// ============================================================================
// Settings Provider — Scanner session action state management
//
// ACTIONS:
// 1. logoutSession()      → POST /api/scanner/session/logout → clearSession()
// 2. resetEventBinding()  → clearSession() only (no API call)
// 3. switchEvent()        → clearSession() only (then scan new setup QR)
//
// All three actions ultimately call clearSession() + routerRefreshNotifier.refresh()
// which causes the router guard to redirect to /setup.
//
// DIFFERENCE BETWEEN ACTIONS:
// - logoutSession:      Calls the backend to invalidate the session server-side.
//                       If the API call fails, we still clear locally.
// - resetEventBinding:  Local clear only. Used when session may already be
//                       invalid (e.g., network unavailable).
// - switchEvent:        Local clear only. Used when intentionally switching
//                       to a different event. Same as resetEventBinding but
//                       semantically different from the user's perspective.
//
// STATE MACHINE:
// idle → loading(action) → success (brief) → redirect to /setup
//     ↘                 ↘ error(message)
//
// ARCHITECTURE — Notifier<SettingsState>:
// Using Notifier (not AsyncNotifier) because:
// - Loading state is per-action (needs to know WHICH action is running)
// - Error is transient and recoverable
// - State has multiple independent fields not suited to AsyncValue<void>
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/session_service.dart';

part 'settings_provider.g.dart';

// ============================================================================
// SETTINGS ACTION ENUM
// ============================================================================

/// Identifies which settings action is currently in progress.
///
/// Used to show the loading indicator on the correct button only,
/// and to display the correct error message.
enum SettingsAction {
  /// Logout action: server-side session invalidation + local clear.
  logout,

  /// Reset action: local session clear only.
  reset,

  /// Switch event action: local session clear only.
  switchEvent,
}

// ============================================================================
// SETTINGS STATE
// ============================================================================

/// Represents the current state of the settings screen actions.
sealed class SettingsState {
  const SettingsState();
}

/// No action in progress — normal settings display.
final class SettingsIdleState extends SettingsState {
  const SettingsIdleState();
}

/// An action is in progress.
///
/// [action] identifies which button is loading so the UI can
/// show a spinner on the correct button.
final class SettingsLoadingState extends SettingsState {
  const SettingsLoadingState({required this.action});
  final SettingsAction action;
}

/// Action completed successfully.
///
/// This state is brief — the router redirects to /setup immediately after.
final class SettingsSuccessState extends SettingsState {
  const SettingsSuccessState({required this.action});
  final SettingsAction action;
}

/// Action failed with an error.
///
/// [action] identifies which action failed.
/// The user can retry or dismiss the error.
final class SettingsErrorState extends SettingsState {
  const SettingsErrorState({
    required this.action,
    required this.message,
    this.isNetworkError = false,
  });

  final SettingsAction action;
  final String message;
  final bool isNetworkError;
}

// ============================================================================
// SETTINGS NOTIFIER
// ============================================================================

/// Riverpod provider for [SettingsNotifier].
@riverpod
class Settings extends _$Settings {
  @override
  SettingsState build() {
    _log('build → idle');
    return const SettingsIdleState();
  }

  // ==========================================================================
  // LOGOUT SESSION
  // ==========================================================================

  /// Logs out the scanner session on the server, then clears locally.
  ///
  /// FLOW:
  /// 1. Set state to loading(logout)
  /// 2. POST /api/scanner/session/logout
  /// 3. Regardless of API success/failure: clearSession() locally
  /// 4. Trigger router refresh → redirect to /setup
  ///
  /// WHY clear session even if API call fails:
  /// If the server is unreachable, the session token is likely invalid anyway.
  /// Keeping it would leave the scanner in a broken state.
  /// The operator can always scan a new setup QR to reconnect.
  Future<void> logoutSession() async {
    if (state is SettingsLoadingState) return;

    _log('logoutSession → starting');
    state = const SettingsLoadingState(action: SettingsAction.logout);

    // Step 1: Attempt server-side logout.
    bool apiCallSucceeded = false;
    try {
      final Dio dio = await ref.read(authenticatedDioProvider.future);
      await dio.post<dynamic>(ApiEndpoints.logoutScannerSession);
      apiCallSucceeded = true;
      _log('logoutSession → API call succeeded');
    } on DioException catch (e) {
      final ApiException apiException = ApiException.fromDioException(e);
      _log('logoutSession → API failed: $apiException (continuing with local clear)');
      // Don't set error state yet — still proceed with local clear.
      // A failed server logout is not a blocker for clearing locally.
      _ = apiCallSucceeded; // suppress unused warning
    } catch (e) {
      _log('logoutSession → unexpected error: $e (continuing with local clear)');
    }

    // Step 2: Always clear the local session.
    await _clearAndRedirect(
      action: SettingsAction.logout,
      apiCallSucceeded: apiCallSucceeded,
    );
  }

  // ==========================================================================
  // RESET EVENT BINDING
  // ==========================================================================

  /// Clears the local session data without calling the backend.
  ///
  /// Use when:
  /// - The session is already known to be invalid
  /// - No network connectivity
  /// - The user wants to disconnect without server notification
  ///
  /// FLOW:
  /// 1. Set state to loading(reset)
  /// 2. clearSession() locally
  /// 3. Trigger router refresh → redirect to /setup
  Future<void> resetEventBinding() async {
    if (state is SettingsLoadingState) return;

    _log('resetEventBinding → starting');
    state = const SettingsLoadingState(action: SettingsAction.reset);

    await _clearAndRedirect(
      action: SettingsAction.reset,
      apiCallSucceeded: true, // No API call — always succeeds locally
    );
  }

  // ==========================================================================
  // SWITCH EVENT
  // ==========================================================================

  /// Clears the local session and returns to setup for a new event QR scan.
  ///
  /// Semantically distinct from resetEventBinding — this is an intentional
  /// switch to a different event, not a reset due to an error.
  ///
  /// FLOW:
  /// 1. Set state to loading(switchEvent)
  /// 2. clearSession() locally
  /// 3. Trigger router refresh → redirect to /setup
  Future<void> switchEvent() async {
    if (state is SettingsLoadingState) return;

    _log('switchEvent → starting');
    state = const SettingsLoadingState(action: SettingsAction.switchEvent);

    await _clearAndRedirect(
      action: SettingsAction.switchEvent,
      apiCallSucceeded: true,
    );
  }

  // ==========================================================================
  // RESET ERROR STATE
  // ==========================================================================

  /// Resets to idle state after an error.
  ///
  /// Called when the user dismisses an error SnackBar or retries.
  void resetError() {
    if (state is SettingsErrorState) {
      state = const SettingsIdleState();
    }
  }

  // ==========================================================================
  // PRIVATE — SHARED CLEAR AND REDIRECT
  // ==========================================================================

  /// Clears the session and triggers router redirect to /setup.
  ///
  /// Called by all three action methods after their specific logic completes.
  Future<void> _clearAndRedirect({
    required SettingsAction action,
    required bool apiCallSucceeded,
  }) async {
    try {
      // Clear all session data from secure storage.
      final SessionService sessionService = ref.read(sessionServiceProvider);
      await sessionService.clearSession();
      _log('_clearAndRedirect → session cleared');

      // Invalidate session providers so they re-read from (now empty) storage.
      ref.invalidate(sessionDataProvider);
      _log('_clearAndRedirect → sessionDataProvider invalidated');

      // Brief success state.
      state = SettingsSuccessState(action: action);

      // Trigger router to re-run the redirect guard.
      // Guard finds no session token → redirects to /setup.
      final routerNotifier = ref.read(routerRefreshNotifierProvider);
      routerNotifier.refresh();
      _log('_clearAndRedirect → router refresh triggered');
    } catch (e) {
      _log('_clearAndRedirect → error during clear: $e');
      state = SettingsErrorState(
        action: action,
        message: 'Failed to clear session data. Please try again.',
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[SettingsNotifier] $message');
  }
}