// ============================================================================
// Scanner Provider — Ticket scan state management
//
// Uses Notifier<ScannerState> (synchronous base) because:
// - Camera rendering state (isFlashOn, isCameraActive) is synchronous
// - The API call result is captured into the state object
// - AsyncNotifier would wrap everything in AsyncValue, hiding camera state
//   behind loading/error/data wrappers inappropriately
//
// STATE MACHINE:
// idle → (QR detected) → processing → result
//                                  ↓
//                        (error) → error
// result/error → (done) → idle
//
// DEBOUNCE:
// The scanner debounces QR detections by 1.5 seconds.
// mobile_scanner fires onDetect many times per second for the same QR.
// Without debouncing, the same ticket would be validated multiple times.
//
// FLASH STATE:
// Flash state is tracked in ScannerState and toggled via toggleFlash().
// The actual camera torch is controlled by the screen via the controller.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../data/scanner_repository.dart';
import '../models/scan_state.dart';
import '../models/ticket_validation_result.dart';

part 'scanner_provider.g.dart';

/// Riverpod provider for [ScannerNotifier].
///
/// Access in screens:
/// ```dart
/// final scannerState = ref.watch(scannerProvider);
/// final notifier = ref.read(scannerProvider.notifier);
/// ```
@riverpod
class Scanner extends _$Scanner {
  @override
  ScannerState build() {
    _log('build → initial idle state');
    return const ScannerState();
  }

  /// Timestamp of the last QR detection — used for debouncing.
  DateTime? _lastDetectionTime;

  // ==========================================================================
  // ON QR DETECTED
  // ==========================================================================

  /// Called when the camera detects a QR code string.
  ///
  /// DEBOUNCE: Ignores calls within [_debounceDuration] of the last call.
  /// GUARD: Ignores calls when already processing or showing result.
  ///
  /// Flow:
  /// idle → processing → result (success)
  ///                  → error (API failure)
  Future<void> onQrDetected(String rawValue) async {
    final String trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) return;

    // Guard: don't process if already handling a scan.
    if (state.status == ScanStatus.processing ||
        state.status == ScanStatus.result) {
      return;
    }

    // Debounce: ignore rapid duplicate detections of the same QR.
    final now = DateTime.now();
    if (_lastDetectionTime != null) {
      final elapsed = now.difference(_lastDetectionTime!);
      if (elapsed.inMilliseconds < 1500) {
        _log('Debounced scan — ${elapsed.inMilliseconds}ms since last');
        return;
      }
    }
    _lastDetectionTime = now;

    _log('QR detected → starting validation: "${trimmedValue.truncate(40)}"');

    // Transition to processing state — camera pauses.
    state = state.copyWith(
      status: ScanStatus.processing,
      isCameraActive: false,
      clearResult: true,
      clearError: true,
    );

    try {
      // Call the validation API.
      final ScannerRepository repository =
          ref.read(scannerRepositoryProvider);
      final TicketValidationResult result =
          await repository.validateTicketQr(trimmedValue);

      _log('Validation complete: ${result.runtimeType}');

      // Transition to result state.
      state = state.copyWith(
        status: ScanStatus.result,
        lastResult: result,
        isCameraActive: false,
        scannedCount: state.scannedCount + 1,
      );
    } on ApiException catch (e) {
      _log('ApiException: $e');
      // For session revocation, the interceptor handles redirect.
      // For other errors, show them in the error result sheet.
      state = state.copyWith(
        status: ScanStatus.result,
        lastResult: ErrorResult(
          message: e.message,
          isNetworkError: e.isNetworkError,
        ),
        isCameraActive: false,
        scannedCount: state.scannedCount + 1,
      );
    } catch (e) {
      _log('Unexpected error: $e');
      state = state.copyWith(
        status: ScanStatus.result,
        lastResult: const ErrorResult(
          message: 'An unexpected error occurred. Please try again.',
        ),
        isCameraActive: false,
      );
    }
  }

  // ==========================================================================
  // RESET SCAN
  // ==========================================================================

  /// Resets the scanner back to idle state.
  ///
  /// Called when:
  /// - User taps "Done" on a result sheet
  /// - User taps "Retry" on an error result
  /// - Result sheet is dismissed by swipe
  ///
  /// Camera resumes scanning after reset.
  void resetScan() {
    _log('resetScan → returning to idle');
    state = state.copyWith(
      status: ScanStatus.idle,
      isCameraActive: true,
      clearResult: true,
      clearError: true,
    );
  }

  // ==========================================================================
  // TOGGLE FLASH
  // ==========================================================================

  /// Toggles the flash/torch state in the provider state.
  ///
  /// The actual camera torch is controlled by the MobileScannerController
  /// in the screen. This method only tracks the state for UI rendering.
  void toggleFlash() {
    state = state.copyWith(isFlashOn: !state.isFlashOn);
    _log('toggleFlash → ${state.isFlashOn ? "ON" : "OFF"}');
  }

  /// Syncs flash UI state with the camera torch (e.g. after [toggleTorch]).
  void setFlashOn(bool isOn) {
    if (state.isFlashOn == isOn) return;
    state = state.copyWith(isFlashOn: isOn);
    _log('setFlashOn → ${isOn ? "ON" : "OFF"}');
  }

  // ==========================================================================
  // CONFIRM CHECKIN
  // ==========================================================================

  /// Explicitly calls the check-in endpoint after displaying a valid result.
  ///
  /// Used when the backend requires a separate check-in confirmation call
  /// (as opposed to auto-check-in during validation).
  ///
  /// Call this if your backend validate endpoint does NOT auto-check-in.
  /// If your backend auto-checks-in on validate, this method is not needed.
  ///
  /// The current lastResult must be a [ValidResult] to call this method.
  Future<void> confirmCheckin() async {
    final current = state.lastResult;
    if (current is! ValidResult) {
      _log('confirmCheckin → lastResult is not ValidResult, skipping');
      return;
    }

    _log('confirmCheckin → calling checkin for ${current.ticketReference}');

    try {
      final repository = ref.read(scannerRepositoryProvider);
      final result = await repository.checkinTicket(current.ticketReference);

      state = state.copyWith(
        lastResult: result,
        status: ScanStatus.result,
      );
    } on ApiException catch (e) {
      _log('confirmCheckin ApiException: $e');
      state = state.copyWith(
        lastResult: ErrorResult(message: e.message),
        status: ScanStatus.result,
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ScannerNotifier] $message');
  }
}

// ============================================================================
// EXTENSION — String truncation for logging
// ============================================================================

extension _StringTruncate on String {
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }
}