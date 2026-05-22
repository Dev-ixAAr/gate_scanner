// ============================================================================
// Session Revoke Interceptor — Handle 401/403 responses globally
//
// When ANY authenticated API call returns HTTP 401 or 403:
// 1. Clear all session data from secure storage
// 2. Show a SnackBar informing the operator their session was revoked
// 3. Navigate to /setup screen so they can scan a new setup QR code
// 4. Trigger the GoRouter refresh notifier so the route guard re-runs
//
// IMPORTANT — Why this is complex:
// Interceptors run outside the widget tree with no BuildContext.
// To show a SnackBar and navigate, we need:
// - A GlobalKey<NavigatorState> (from main.dart) for SnackBar context
// - The RouterRefreshNotifier to trigger GoRouter redirect
// - A mutex flag to prevent multiple simultaneous revoke handlers
//
// PREVENTION OF DOUBLE-HANDLING:
// The _isHandlingRevoke flag ensures that if multiple requests fail with 401
// simultaneously (e.g., two API calls made at the same time), only the first
// one triggers the full revoke flow. Subsequent 401s are rejected immediately.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../router/route_names.dart';
import '../../services/session_service.dart';
import '../api_endpoints.dart';

/// Dio interceptor that handles remote session revocation.
///
/// Catches HTTP 401 and 403 responses and triggers the full
/// session cleanup + redirect to setup flow.
class SessionRevokeInterceptor extends Interceptor {
  SessionRevokeInterceptor({
    required SessionService sessionService,
    required RouterRefreshNotifier routerRefreshNotifier,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _sessionService = sessionService,
        _routerRefreshNotifier = routerRefreshNotifier,
        _navigatorKey = navigatorKey;

  final SessionService _sessionService;
  final RouterRefreshNotifier _routerRefreshNotifier;
  final GlobalKey<NavigatorState> _navigatorKey;

  /// Prevents multiple simultaneous revoke flows.
  /// Set to true when handling a revocation, reset after completion.
  bool _isHandlingRevoke = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final int? statusCode = err.response?.statusCode;

    // Only handle 401 (Unauthorized) and 403 (Forbidden).
    // Other errors pass through to the normal error handling chain.
    if (statusCode != 401 && statusCode != 403) {
      handler.next(err);
      return;
    }

    // Skip setup token exchange endpoint — 401 there means bad setup token,
    // not a revoked scanner session. Let it propagate to SetupRepository.
    final String requestPath = err.requestOptions.path;
    if (requestPath.contains(ApiEndpoints.verifySetupToken)) {
      handler.next(err);
      return;
    }

    // Guard: prevent multiple simultaneous revoke flows.
    if (_isHandlingRevoke) {
      _log('Already handling revoke — skipping duplicate 401');
      handler.next(err);
      return;
    }

    _isHandlingRevoke = true;
    _log('Session revocation detected (HTTP $statusCode) — clearing session');

    try {
      // Step 1: Clear the local session from secure storage.
      await _sessionService.clearSession();
      _log('Session cleared from storage');

      // Step 2: Show a SnackBar to inform the operator.
      _showRevocationSnackBar();

      // Step 3: Trigger GoRouter to re-run the redirect guard.
      // Since the session is now cleared, the guard will redirect to /setup.
      _routerRefreshNotifier.refresh();
      _log('Router refresh triggered — redirecting to /setup');
    } catch (e) {
      // If clearSession fails, still attempt to redirect.
      // A partial clear is better than staying on a broken session.
      _log('ERROR during session clear: $e — attempting redirect anyway');
      _routerRefreshNotifier.refresh();
    } finally {
      // Reset the flag after a short delay to allow the UI to settle.
      Future.delayed(const Duration(seconds: 3), () {
        _isHandlingRevoke = false;
      });
    }

    // Reject the error — the original request will not complete.
    // The UI should react to the navigation change, not the error.
    handler.reject(err);
  }

  /// Shows a SnackBar informing the operator of session revocation.
  ///
  /// Uses [_navigatorKey] to get a BuildContext without depending on
  /// the widget tree directly.
  void _showRevocationSnackBar() {
    final BuildContext? context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _log('Cannot show SnackBar — no valid context from navigatorKey');
      return;
    }

    // Use a post-frame callback to ensure the SnackBar shows after
    // any pending widget rebuilds (navigation transition).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: Color(0xFFFFB020),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Revoked',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Your session was ended remotely. Please scan a new setup QR code.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1C1C1C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0x40FFB020)),
            ),
            // No close icon — the navigation to /setup will dismiss it.
            showCloseIcon: false,
          ),
        );
    });
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SessionRevokeInterceptor] $message');
    }
  }
}