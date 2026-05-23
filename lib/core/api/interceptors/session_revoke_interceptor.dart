// ============================================================================
// Session Revoke Interceptor — Complete Phase 9 implementation
//
// Handles HTTP 401/403 responses from any authenticated API call.
//
// WHAT HAPPENS ON 401/403:
// 1. _isHandlingRevoke mutex prevents duplicate handling
// 2. clearSession() removes all session data from secure storage
// 3. sessionDataProvider is invalidated (reactive UI updates)
// 4. routerRefreshNotifier.refresh() causes GoRouter to re-run the
//    redirect guard, which finds no session → redirects to /setup
// 5. SnackBar is shown via post-frame callback (safe from interceptor context)
//
// WHY POST-FRAME CALLBACK FOR NAVIGATION:
// Interceptors run in Dio's async chain, which may be called during a widget
// build phase. Triggering navigation or SnackBars directly from the interceptor
// can cause "setState during build" errors. addPostFrameCallback defers
// the UI side-effects until the current frame is complete.
//
// WHY routerRefreshNotifier (not direct GoRouter navigation):
// The interceptor does not have access to the GoRouter instance directly.
// routerRefreshNotifier is a ChangeNotifier that GoRouter listens to.
// When refresh() is called, GoRouter re-runs the redirect() function,
// which detects no session token and redirects to /setup naturally.
// This is cleaner than storing a router reference in the interceptor.
//
// ENDPOINTS THAT SKIP 401 HANDLING:
// - verifySetupToken: 401 here means bad setup token, not revoked session
//
// MUTEX RESET:
// _isHandlingRevoke resets after 3 seconds to handle edge cases where the
// revoke flow completes but the flag never resets (e.g., navigation cancelled).
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../../providers/session_providers.dart';
import '../../router/app_router.dart';
import '../../services/session_service.dart';
import '../api_endpoints.dart';

/// Dio interceptor that handles remote session revocation.
///
/// Catches HTTP 401 and 403 responses from authenticated endpoints.
/// Triggers the full session cleanup + router redirect to /setup.
class SessionRevokeInterceptor extends Interceptor {
  SessionRevokeInterceptor({
    required SessionService sessionService,
    required RouterRefreshNotifier routerRefreshNotifier,
    required GlobalKey<NavigatorState> navigatorKey,
    required Ref ref,
  })  : _sessionService = sessionService,
        _routerRefreshNotifier = routerRefreshNotifier,
        _navigatorKey = navigatorKey,
        _ref = ref;

  final SessionService _sessionService;
  final RouterRefreshNotifier _routerRefreshNotifier;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Ref _ref;

  /// Mutex: prevents multiple simultaneous revoke flows.
  ///
  /// If two API calls return 401 simultaneously, only the first
  /// triggers the revoke flow. The second is silently passed through.
  bool _isHandlingRevoke = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final int? statusCode = err.response?.statusCode;

    if (!_shouldRevokeSession(statusCode, err.response?.data)) {
      handler.next(err);
      return;
    }

    // Skip the setup token exchange endpoint.
    // 401 on that endpoint means the setup token is bad, not a revoked session.
    final String requestPath = err.requestOptions.path;
    if (_isSetupEndpoint(requestPath)) {
      _log('Skipping revoke for setup endpoint: $requestPath');
      handler.next(err);
      return;
    }

    // Mutex guard — prevent duplicate handling.
    if (_isHandlingRevoke) {
      _log('Already handling revocation — suppressing duplicate 401');
      handler.reject(err);
      return;
    }

    _isHandlingRevoke = true;
    _log('Session revocation detected (HTTP $statusCode) on $requestPath');

    try {
      // Step 1: Clear session from secure storage.
      await _sessionService.clearSession();
      _log('Session cleared from secure storage');

      // Step 2: Invalidate session providers for reactive UI updates.
      // This ensures any watching providers get fresh (null) data.
      _ref.invalidate(sessionDataProvider);
      _log('sessionDataProvider invalidated');

      // Step 3: Trigger router to re-run the redirect guard.
      // Guard will find no session token → redirect to /setup.
      _routerRefreshNotifier.refresh();
      _log('Router refresh triggered → will redirect to /setup');

      // Step 4: Show revocation SnackBar via post-frame callback.
      // Using addPostFrameCallback ensures we don't trigger UI changes
      // during an ongoing build cycle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRevocationSnackBar();
      });
    } catch (e) {
      // If clearSession fails, still trigger the router redirect.
      // A partial clear is better than being stuck on a broken session.
      _log('ERROR during session clear: $e — triggering redirect anyway');
      _routerRefreshNotifier.refresh();
    } finally {
      // Reset mutex after a delay to handle edge cases.
      Future<void>.delayed(const Duration(seconds: 3), () {
        _isHandlingRevoke = false;
        _log('Revoke mutex reset');
      });
    }

    // Reject the error so the original caller receives an error response.
    // The session cleanup and navigation happen independently of this.
    handler.reject(err);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Returns true if the request path is the setup token exchange endpoint.
  bool _isSetupEndpoint(String path) {
    return path.contains(ApiEndpoints.verifySetupToken);
  }

  /// True when the response means the scanner session is invalid/revoked.
  bool _shouldRevokeSession(int? statusCode, dynamic responseData) {
    if (statusCode == 401) return true;
    if (statusCode != 403) return false;

    if (responseData is! Map<String, dynamic>) return false;

    final String? code = (responseData['error_code'] as String?) ??
        (responseData['code'] as String?);
    if (code == null) return false;

    return AppSecurityConfig.sessionRevokedErrorCodes
        .contains(code.trim());
  }

  /// Shows the session revocation SnackBar.
  ///
  /// Uses [_navigatorKey] to get a valid BuildContext from outside the
  /// widget tree. The post-frame callback ensures this runs safely.
  void _showRevocationSnackBar() {
    final BuildContext? context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _log('Cannot show SnackBar — no valid context from navigatorKey');
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Persistent — stays until user dismisses or navigates away.
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.backgroundTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.warningBorder, width: 1),
          ),
          showCloseIcon: true,
          closeIconColor: AppColors.textTertiary,
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Revoked',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your session has been revoked by the administrator. '
                      'Please scan a new setup QR code to reconnect.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

    _log('Revocation SnackBar shown');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SessionRevokeInterceptor] $message');
    }
  }
}

// ============================================================================
// AppColors reference for SnackBar — imported inline to avoid circular imports
// ============================================================================

class AppColors {
  static const Color backgroundTertiary = Color(0xFF1C1C1C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF6B6B6B);
  static const Color warning = Color(0xFFFFB020);
  static const Color warningBorder = Color(0x40FFB020);
  static const Color warningSurface = Color(0x1AFFB020);
}