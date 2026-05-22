// ============================================================================
// Home Provider — Session data and status management for the home screen
//
// RESPONSIBILITIES:
// 1. Load the current session from SessionService on initialization
// 2. Expose all session fields needed by the home screen UI
// 3. Provide refreshSessionStatus() for periodic server-side validation
// 4. Track session health status (active, checking, error)
//
// ARCHITECTURE DECISION — AsyncNotifier:
// Loading session data from SecureStorage is async.
// AsyncNotifier provides AsyncValue<HomeState> which the UI handles
// with .when(loading:, data:, error:) — no manual loading flags needed.
//
// SESSION REFRESH FLOW:
// On AppLifecycleState.resumed → refreshSessionStatus() is called
// → GET /api/scanner/session
// → If 200: update session status to active
// → If 401: SessionRevokeInterceptor clears session + redirects to /setup
//           (the interceptor handles this automatically — homeProvider
//            does not need to handle 401 explicitly)
// → If network error: set status to error (session may still be valid)
//
// POLLING:
// The home screen calls refreshSessionStatus() on:
// - Screen initial load (build)
// - App lifecycle resume (foreground)
// - Manual pull-to-refresh (optional)
// No automatic timer polling — battery and network conservative approach.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/session_data.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/services/session_service.dart';

part 'home_provider.g.dart';

// ============================================================================
// HOME STATE MODEL
// ============================================================================

/// Represents the complete state of the home screen.
///
/// Combines session data with session health status.
/// Created by [HomeNotifier] after loading session from storage.
class HomeState {
  const HomeState({
    required this.session,
    required this.sessionStatus,
    this.lastRefreshedAt,
    this.refreshError,
  });

  /// The current session data loaded from secure storage.
  /// Contains: eventName, serverUrl, deviceName, sessionStartedAt, etc.
  final SessionData session;

  /// Current health status of the scanner session.
  /// Updated by [HomeNotifier.refreshSessionStatus].
  final SessionHealthStatus sessionStatus;

  /// When the session was last successfully verified with the server.
  /// Null if not yet checked.
  final DateTime? lastRefreshedAt;

  /// Error message from the last failed session refresh.
  /// Null if last refresh was successful or not yet attempted.
  final String? refreshError;

  // --------------------------------------------------------------------------
  // Computed properties for UI consumption
  // --------------------------------------------------------------------------

  /// True when the session is confirmed active.
  bool get isSessionActive => sessionStatus == SessionHealthStatus.active;

  /// True when a session refresh is in progress.
  bool get isRefreshing => sessionStatus == SessionHealthStatus.checking;

  /// True when the last refresh resulted in an error.
  bool get hasRefreshError => sessionStatus == SessionHealthStatus.error;

  // --------------------------------------------------------------------------
  // CopyWith
  // --------------------------------------------------------------------------

  HomeState copyWith({
    SessionData? session,
    SessionHealthStatus? sessionStatus,
    DateTime? lastRefreshedAt,
    String? refreshError,
  }) {
    return HomeState(
      session: session ?? this.session,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      refreshError: refreshError ?? this.refreshError,
    );
  }

  @override
  String toString() => 'HomeState('
      'event: "${session.eventName}", '
      'status: $sessionStatus, '
      'lastRefreshed: $lastRefreshedAt'
      ')';
}

// ============================================================================
// SESSION HEALTH STATUS
// ============================================================================

/// Represents the server-verified health of the scanner session.
enum SessionHealthStatus {
  /// Initial state — not yet checked with server.
  unknown,

  /// Server check in progress.
  checking,

  /// Server confirmed session is active and valid.
  active,

  /// Server check failed (network error, timeout).
  /// Session may still be valid — last known state is preserved.
  error,

  /// Server returned 401 — session was revoked.
  /// [SessionRevokeInterceptor] handles this automatically.
  /// This state is set briefly before the interceptor redirects.
  revoked,
}

// ============================================================================
// HOME NOTIFIER
// ============================================================================

/// Provides [HomeState] for the scanner home screen.
///
/// Lifecycle:
/// 1. [build]: loads session from storage → returns initial [HomeState]
/// 2. [refreshSessionStatus]: calls API → updates [sessionStatus]
/// 3. On 401: [SessionRevokeInterceptor] takes over → redirects to /setup
@riverpod
class Home extends _$Home {
  @override
  Future<HomeState> build() async {
    _log('build → loading session from storage');

    // Load the session from secure storage.
    final SessionService sessionService = ref.read(sessionServiceProvider);
    final SessionData? session = await sessionService.getSession();

    if (session == null) {
      // This should not happen — the router guard redirects to /setup
      // before HomeScreen is shown if no session exists.
      // But guard defensively anyway.
      _log('build → WARNING: No session found on home screen');
      throw const SessionNotFoundError();
    }

    _log('build → session loaded: ${session.eventName}');

    // Return initial state with unknown status.
    // Status will be updated by refreshSessionStatus() called from the screen.
    return HomeState(
      session: session,
      sessionStatus: SessionHealthStatus.unknown,
    );
  }

  // ==========================================================================
  // REFRESH SESSION STATUS
  // ==========================================================================

  /// Verifies the scanner session is still active on the server.
  ///
  /// Calls GET /api/scanner/session with the stored Bearer token.
  ///
  /// Results:
  /// - 200 OK: updates status to [SessionHealthStatus.active]
  /// - 401/403: [SessionRevokeInterceptor] clears session + redirects to /setup
  ///            (this method does not need to handle 401 explicitly)
  /// - Network error: updates status to [SessionHealthStatus.error]
  ///                  (session may still be valid — don't force logout)
  /// - Other 4xx/5xx: updates status to [SessionHealthStatus.error]
  ///
  /// Does NOT throw — errors are captured into the state's [refreshError] field.
  Future<void> refreshSessionStatus() async {
    // Guard: only refresh if we have a valid current state.
    final currentState = state;
    if (currentState is! AsyncData<HomeState>) {
      _log('refreshSessionStatus → state not ready, skipping');
      return;
    }

    // Guard: don't refresh if already checking.
    if (currentState.value.isRefreshing) {
      _log('refreshSessionStatus → already checking, skipping');
      return;
    }

    _log('refreshSessionStatus → calling GET ${ApiEndpoints.getScannerSession}');

    // Update status to "checking" while the request is in flight.
    state = AsyncData(
      currentState.value.copyWith(
        sessionStatus: SessionHealthStatus.checking,
        refreshError: null,
      ),
    );

    try {
      // Use the authenticated Dio provider.
      // The auth interceptor attaches the Bearer token.
      // The session revoke interceptor handles 401 automatically.
      final Dio dio = await ref.read(authenticatedDioProvider.future);

      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.getScannerSession,
      );

      // 200 OK — session is still active on the server.
      _log('refreshSessionStatus → active (HTTP ${response.statusCode})');

      // Update session data if the server returned updated fields.
      final updatedSession = _parseSessionUpdate(
        response.data,
        currentState.value.session,
      );

      state = AsyncData(
        currentState.value.copyWith(
          session: updatedSession,
          sessionStatus: SessionHealthStatus.active,
          lastRefreshedAt: DateTime.now(),
          refreshError: null,
        ),
      );
    } on DioException catch (e) {
      final ApiException apiException = ApiException.fromDioException(e);
      _log('refreshSessionStatus → DioException: $apiException');

      // 401/403 are handled by SessionRevokeInterceptor automatically.
      // Just mark as revoked for the brief moment before redirect.
      if (apiException.isSessionRevoked) {
        state = AsyncData(
          currentState.value.copyWith(
            sessionStatus: SessionHealthStatus.revoked,
            refreshError: apiException.message,
          ),
        );
        return;
      }

      // Network or server error — preserve current session, mark as error.
      // Don't force logout on network errors — the session may still be valid.
      state = AsyncData(
        currentState.value.copyWith(
          sessionStatus: SessionHealthStatus.error,
          refreshError: _friendlyErrorMessage(apiException),
        ),
      );
    } catch (e) {
      _log('refreshSessionStatus → unexpected error: $e');
      state = AsyncData(
        currentState.value.copyWith(
          sessionStatus: SessionHealthStatus.error,
          refreshError: 'Connection check failed. Scanner may still be active.',
        ),
      );
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Parses updated session fields from a session refresh response.
  ///
  /// The server may return updated event name or device name.
  /// Falls back to the current session values for any missing fields.
  SessionData _parseSessionUpdate(
    Map<String, dynamic>? responseData,
    SessionData currentSession,
  ) {
    if (responseData == null) return currentSession;

    return currentSession.copyWith(
      eventName: (responseData['event_name'] as String?)?.trim() ??
          currentSession.eventName,
      deviceName: (responseData['device_name'] as String?)?.trim() ??
          currentSession.deviceName,
    );
  }

  /// Returns a user-friendly error message for the home screen.
  String _friendlyErrorMessage(ApiException e) {
    if (e.isNetworkError || e.isTimeout) {
      return 'Cannot reach server. Check your network connection.';
    }
    if (e.isServerError) {
      return 'Server error. Scanner may still be active.';
    }
    return 'Connection check failed. Scanner may still be active.';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[HomeNotifier] $message');
    }
  }
}

// ============================================================================
// CONVENIENCE PROVIDERS
// Derived providers for screens that only need specific session fields.
// ============================================================================

/// Provides just the [SessionHealthStatus] from [homeProvider].
final sessionHealthStatusProvider = Provider<SessionHealthStatus>((ref) {
  final homeAsync = ref.watch(homeProvider);
  return homeAsync.whenOrNull(
        data: (state) => state.sessionStatus,
      ) ??
      SessionHealthStatus.unknown;
});

/// Provides the current event name from [homeProvider].
final homeEventNameProvider = Provider<String?>((ref) {
  final homeAsync = ref.watch(homeProvider);
  return homeAsync.whenOrNull(data: (state) => state.session.eventName);
});

// ============================================================================
// EXCEPTIONS
// ============================================================================

/// Thrown by [HomeNotifier.build] if no session exists when home screen loads.
///
/// This should never happen in production because the router guard
/// redirects to /setup before the home screen is rendered.
/// Caught as an error state by the AsyncNotifier framework.
class SessionNotFoundError implements Exception {
  const SessionNotFoundError();

  @override
  String toString() =>
      'SessionNotFoundError: No active session found. '
      'The router guard should have redirected to /setup.';
}