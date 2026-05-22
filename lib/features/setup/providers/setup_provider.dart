// ============================================================================
// Setup Provider — QR scan and token exchange state management
//
// PHASE 4 SCOPE:
// - SetupQrScanState: manages the camera screen state machine
//   (idle → qrDetected → parsed → error)
// - SetupQrScanNotifier: handles QR string parsing + state transitions
//
// PHASE 5 ADDITIONS (not yet implemented):
// - exchangeSetupToken(SetupQrPayload): calls backend API
// - SetupState for the full exchange flow (loading/success/error)
//
// STATE MACHINE:
//
//   [idle] ──────── QR detected ──────→ [processing]
//      ↑                                      │
//      │                          success ────┤
//      │                                      ↓
//      │                               [qrParsed(payload)]
//      │                                      │
//      │           cancelled / error ─────────┘
//      │
//      └──── error(message) ← parse failure / expiry
//
// The [qrParsed] state triggers the confirmation bottom sheet.
// The [idle] state means the camera is active and scanning.
// ============================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/setup_qr_payload.dart';

// ==========================================================================
// STATE DEFINITION
// ==========================================================================

/// Represents the state of the setup QR scanning screen.
///
/// Uses a sealed class pattern for exhaustive switch handling.
/// The UI switches on this type to render the appropriate UI state.
sealed class SetupQrScanState {
  const SetupQrScanState();
}

/// Camera is active and waiting for a QR code to be detected.
/// This is the default/initial state.
final class SetupQrScanIdleState extends SetupQrScanState {
  const SetupQrScanIdleState();
}

/// A QR code has been detected and is being parsed.
/// Camera is paused. Show a loading indicator briefly.
final class SetupQrScanProcessingState extends SetupQrScanState {
  const SetupQrScanProcessingState();
}

/// QR code was successfully parsed and validated (not expired).
/// Camera is paused. Show the confirmation bottom sheet.
final class SetupQrScanParsedState extends SetupQrScanState {
  const SetupQrScanParsedState({required this.payload});

  /// The parsed and structurally valid QR payload.
  /// Ready to be sent to the token exchange API.
  final SetupQrPayload payload;
}

/// QR parse failed or QR was expired.
/// Camera resumes after the error is shown.
final class SetupQrScanErrorState extends SetupQrScanState {
  const SetupQrScanErrorState({required this.message});

  /// Human-readable error message for display in a Snackbar.
  final String message;
}

// ==========================================================================
// NOTIFIER
// ==========================================================================

/// Riverpod provider for [SetupQrScanNotifier].
///
/// Access in screens:
/// ```dart
/// final scanState = ref.watch(setupQrScanProvider);
/// final notifier = ref.read(setupQrScanProvider.notifier);
/// ```
final setupQrScanProvider =
    NotifierProvider<SetupQrScanNotifier, SetupQrScanState>(
  SetupQrScanNotifier.new,
);

/// Manages the state machine for the setup QR scanning screen.
///
/// Handles:
/// - QR string detection and JSON parsing
/// - SetupQrPayload validation (structure + expiry)
/// - State transitions through the scanning flow
/// - Camera pause/resume coordination via state
class SetupQrScanNotifier extends Notifier<SetupQrScanState> {
  @override
  SetupQrScanState build() {
    // Initial state: camera active, waiting for QR.
    return const SetupQrScanIdleState();
  }

  // ==========================================================================
  // ON QR DETECTED
  // ==========================================================================

  /// Called when the camera detects a QR code string.
  ///
  /// Transitions:
  /// - idle → processing (briefly)
  /// - processing → parsed (valid QR)
  /// - processing → error (invalid JSON, missing fields, expired)
  ///
  /// If already in [processing] or [parsed] state, this call is ignored
  /// to prevent duplicate processing of the same QR code.
  ///
  /// [rawValue]: the raw string value from the QR code barcode
  void onQrDetected(String rawValue) {
    // Guard: ignore if already processing or showing result.
    // This prevents duplicate calls from the scanner detecting the same QR
    // multiple times per second.
    final current = state;
    if (current is SetupQrScanProcessingState ||
        current is SetupQrScanParsedState) {
      return;
    }

    _debugLog('QR detected — parsing: ${rawValue.length} chars');

    // Transition to processing state.
    state = const SetupQrScanProcessingState();

    // Parse and validate synchronously.
    // JSON parsing is CPU-bound but fast for small payloads.
    // No need for async/compute isolate here.
    _parseQrValue(rawValue);
  }

  // ==========================================================================
  // RESET (Resume scanning)
  // ==========================================================================

  /// Resets the scanner to idle state, re-enabling the camera.
  ///
  /// Called when:
  /// - User taps "Cancel" on the confirmation bottom sheet
  /// - After showing an error Snackbar (auto-reset)
  /// - User dismisses the bottom sheet by swiping down
  void reset() {
    _debugLog('reset → returning to idle');
    state = const SetupQrScanIdleState();
  }

  // ==========================================================================
  // PRIVATE — QR PARSING
  // ==========================================================================

  /// Parses the raw QR string into a [SetupQrPayload].
  ///
  /// Attempts JSON decode → [SetupQrPayload.fromJson] → expiry check.
  /// Sets state to [SetupQrScanParsedState] on success.
  /// Sets state to [SetupQrScanErrorState] on any failure.
  void _parseQrValue(String rawValue) {
    try {
      // Step 1: Parse the raw string as JSON.
      final dynamic decoded = jsonDecode(rawValue);

      // Step 2: Ensure the JSON root is a Map.
      if (decoded is! Map<String, dynamic>) {
        _debugLog('QR parse failed: JSON root is not an object');
        state = const SetupQrScanErrorState(
          message:
              'Invalid QR code format. This does not appear to be a setup QR code.',
        );
        return;
      }

      // Step 3: Parse the Map into a SetupQrPayload (validates all fields).
      final SetupQrPayload payload = SetupQrPayload.fromJson(decoded);

      // Step 4: Check if the QR code has expired.
      if (payload.isExpired) {
        _debugLog('QR code is expired: ${payload.expiresAt}');
        state = const SetupQrScanErrorState(
          message:
              'This setup QR code has expired. Please generate a new one from the admin panel.',
        );
        return;
      }

      // Step 5: Valid payload — transition to parsed state.
      _debugLog('QR parsed successfully: ${payload.eventPublicRef}');
      state = SetupQrScanParsedState(payload: payload);
    } on SetupQrParseException catch (e) {
      // Missing or invalid field in the QR JSON.
      _debugLog('SetupQrParseException: ${e.message}');
      state = SetupQrScanErrorState(
        message: 'Invalid setup QR code: ${e.message}',
      );
    } on FormatException catch (e) {
      // JSON decode failed — not valid JSON.
      _debugLog('JSON FormatException: $e');
      state = const SetupQrScanErrorState(
        message:
            'This QR code does not contain valid setup data. Please scan the admin setup QR code.',
      );
    } catch (e) {
      // Unexpected error.
      _debugLog('Unexpected parse error: $e');
      state = const SetupQrScanErrorState(
        message: 'Failed to read QR code. Please try again.',
      );
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[SetupQrScanNotifier] $message');
    }
  }
}