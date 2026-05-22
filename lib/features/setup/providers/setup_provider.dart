// ============================================================================
// Setup Provider — Complete setup flow state management
//
// PHASE 4 CONTENTS (preserved):
// - SetupQrScanState (sealed class)
// - SetupQrScanNotifier: manages the QR camera scanning state machine
//
// PHASE 5 ADDITIONS:
// - SetupExchangeState (sealed class): idle/loading/success/error
// - SetupExchangeNotifier: AsyncNotifier that calls SetupRepository,
//   saves session via SessionService, triggers router redirect on success
//
// TWO NOTIFIERS — SINGLE RESPONSIBILITY:
// SetupQrScanNotifier:   Camera state machine (idle→processing→parsed→error)
// SetupExchangeNotifier: Token exchange state (idle→loading→success→error)
//
// These are kept separate to avoid a complex 7-state combined machine.
// The scan screen watches both and renders accordingly.
// ============================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/session_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/api/api_exception.dart';
import '../data/setup_repository.dart';
import '../models/setup_qr_payload.dart';

part 'setup_provider.g.dart';

// ============================================================================
// PART 1: QR SCAN STATE MACHINE (Phase 4 — unchanged)
// ============================================================================

/// State variants for the QR scanning camera screen.
sealed class SetupQrScanState {
  const SetupQrScanState();
}

final class SetupQrScanIdleState extends SetupQrScanState {
  const SetupQrScanIdleState();
}

final class SetupQrScanProcessingState extends SetupQrScanState {
  const SetupQrScanProcessingState();
}

final class SetupQrScanParsedState extends SetupQrScanState {
  const SetupQrScanParsedState({required this.payload});
  final SetupQrPayload payload;
}

final class SetupQrScanErrorState extends SetupQrScanState {
  const SetupQrScanErrorState({required this.message});
  final String message;
}

/// Provider for [SetupQrScanNotifier].
final setupQrScanProvider =
    NotifierProvider<SetupQrScanNotifier, SetupQrScanState>(
  SetupQrScanNotifier.new,
);

/// Manages the QR camera scanning state machine (Phase 4 — unchanged).
class SetupQrScanNotifier extends Notifier<SetupQrScanState> {
  @override
  SetupQrScanState build() => const SetupQrScanIdleState();

  void onQrDetected(String rawValue) {
    final current = state;
    if (current is SetupQrScanProcessingState ||
        current is SetupQrScanParsedState) {
      return;
    }
    _log('QR detected — parsing: ${rawValue.length} chars');
    state = const SetupQrScanProcessingState();
    _parseQrValue(rawValue);
  }

  void reset() {
    _log('reset → returning to idle');
    state = const SetupQrScanIdleState();
  }

  void _parseQrValue(String rawValue) {
    try {
      final dynamic decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        state = const SetupQrScanErrorState(
          message:
              'Invalid QR code format. This does not appear to be a setup QR code.',
        );
        return;
      }
      final SetupQrPayload payload = SetupQrPayload.fromJson(decoded);
      if (payload.isExpired) {
        state = const SetupQrScanErrorState(
          message:
              'This setup QR code has expired. Please generate a new one from the admin panel.',
        );
        return;
      }
      _log('QR parsed successfully: ${payload.eventPublicRef}');
      state = SetupQrScanParsedState(payload: payload);
    } on SetupQrParseException catch (e) {
      _log('SetupQrParseException: ${e.message}');
      state = SetupQrScanErrorState(
        message: 'Invalid setup QR code: ${e.message}',
      );
    } on FormatException {
      state = const SetupQrScanErrorState(
        message:
            'This QR code does not contain valid setup data. Please scan the admin setup QR code.',
      );
    } catch (e) {
      state = const SetupQrScanErrorState(
        message: 'Failed to read QR code. Please try again.',
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[SetupQrScanNotifier] $message');
  }
}

// ============================================================================
// PART 2: TOKEN EXCHANGE STATE (Phase 5 — new)
// ============================================================================

/// State variants for the setup token exchange flow.
///
/// Used by [SetupExchangeNotifier] to communicate progress to the UI.
sealed class SetupExchangeState {
  const SetupExchangeState();
}

/// Initial state — no exchange in progress.
final class SetupExchangeIdleState extends SetupExchangeState {
  const SetupExchangeIdleState();
}

/// Exchange API call is in progress.
/// UI shows loading overlay, buttons are disabled.
final class SetupExchangeLoadingState extends SetupExchangeState {
  const SetupExchangeLoadingState();
}

/// Exchange was successful.
/// Session has been saved. Router will redirect to /home.
final class SetupExchangeSuccessState extends SetupExchangeState {
  const SetupExchangeSuccessState({required this.eventName});

  /// Name of the event this scanner is now bound to.
  /// Used for a brief success display before navigation.
  final String eventName;
}

/// Exchange failed with an error.
/// UI shows error message and re-enables the confirm button.
final class SetupExchangeErrorState extends SetupExchangeState {
  const SetupExchangeErrorState({
    required this.message,
    this.isNetworkError = false,
  });

  /// Human-readable error message to display in the UI.
  final String message;

  /// True when the error was a network connectivity issue.
  /// Allows the UI to show "Check your connection" guidance.
  final bool isNetworkError;
}

/// Riverpod provider for [SetupExchangeNotifier].
///
/// Access in screens:
/// ```dart
/// final exchangeState = ref.watch(setupExchangeProvider);
/// final notifier = ref.read(setupExchangeProvider.notifier);
/// notifier.exchangeSetupToken(payload);
/// ```
@riverpod
class SetupExchange extends _$SetupExchange {
  @override
  SetupExchangeState build() => const SetupExchangeIdleState();

  // ==========================================================================
  // EXCHANGE SETUP TOKEN
  // ==========================================================================

  /// Exchanges a setup token for a scanner session token.
  ///
  /// Full flow:
  /// 1. Set state to loading
  /// 2. Collect device info from DeviceInfoService
  /// 3. Call SetupRepository.verifySetupToken
  /// 4. On success: save session via SessionService
  /// 5. On success: invalidate sessionDataProvider (triggers reactive updates)
  /// 6. On success: trigger router refresh (redirects to /home)
  /// 7. On success: set state to success
  /// 8. On error: set state to error with message
  ///
  /// [payload]: the parsed and validated setup QR payload to exchange
  Future<void> exchangeSetupToken(SetupQrPayload payload) async {
    // Guard: prevent duplicate calls while already loading.
    if (state is SetupExchangeLoadingState) {
      _log('Exchange already in progress — ignoring duplicate call');
      return;
    }

    _log('Starting token exchange for event: ${payload.eventPublicRef}');
    state = const SetupExchangeLoadingState();

    try {
      // Step 1: Collect device information.
      final deviceInfoService = ref.read(deviceInfoServiceProvider);
      final deviceInfo = await deviceInfoService.getDeviceInfo();
      _log('Device info collected: ${deviceInfo.deviceName}');

      // Step 2: Get the app version for the request payload.
      // DeviceInfoModel has a fallback version — replace with live value.
      final appInfoService = ref.read(appInfoServiceProvider);
      final appVersion = await appInfoService.getAppVersion();
      final deviceInfoWithVersion = deviceInfo.copyWith(appVersion: appVersion);

      // Step 3: Call the API.
      final setupRepository = ref.read(setupRepositoryProvider);
      final sessionModel = await setupRepository.verifySetupToken(
        payload: payload,
        deviceInfo: deviceInfoWithVersion,
      );
      _log('API call successful — saving session');

      // Step 4: Save session to secure storage.
      final sessionService = ref.read(sessionServiceProvider);
      await sessionService.saveSession(
        serverUrl: payload.serverUrlNormalized,
        eventPublicRef: sessionModel.eventPublicRef,
        eventName: sessionModel.eventName,
        sessionToken: sessionModel.sessionToken,
        sessionStartedAt: sessionModel.sessionStartedAt,
        deviceName: sessionModel.deviceName,
      );
      _log('Session saved successfully');

      // Step 5: Invalidate session providers so they re-read from storage.
      // This updates any UI that watches sessionDataProvider.
      ref.invalidate(sessionDataProvider);
      _log('sessionDataProvider invalidated');

      // Step 6: Trigger the router refresh notifier.
      // The router guard will re-run, detect the new session token,
      // and redirect to /home.
      final routerNotifier = ref.read(routerRefreshNotifierProvider);
      routerNotifier.refresh();
      _log('Router refresh triggered — redirecting to /home');

      // Step 7: Set success state for any UI that watches this provider.
      state = SetupExchangeSuccessState(eventName: sessionModel.eventName);
    } on ApiException catch (e) {
      _log('ApiException during exchange: $e');
      state = SetupExchangeErrorState(
        message: e.message,
        isNetworkError: e.isNetworkError,
      );
    } catch (e) {
      _log('Unexpected error during exchange: $e');
      state = SetupExchangeErrorState(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ==========================================================================
  // RESET
  // ==========================================================================

  /// Resets the exchange state to idle.
  ///
  /// Called when the operator dismisses an error and wants to try again.
  void reset() {
    _log('reset → idle');
    state = const SetupExchangeIdleState();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[SetupExchangeNotifier] $message');
  }
}