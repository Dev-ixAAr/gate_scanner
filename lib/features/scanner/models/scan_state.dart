// ============================================================================
// Scan State — Scanner state machine types
//
// Defines the ScanStatus enum and ScannerState class used by ScannerNotifier.
//
// STATE MACHINE:
//
//   [idle] ──── QR detected ────→ [processing]
//      ↑                               │
//      │                    success ───┤
//      │                               ↓
//      │                          [result]
//      │                               │
//      │              done/dismiss ────┘
//      │
//      └──── [error] ← API error
//
// The camera is paused during [processing] and [result] states.
// The camera resumes when transitioning back to [idle].
// ============================================================================

import 'ticket_validation_result.dart';

/// Status phases of the ticket scanner.
enum ScanStatus {
  /// Camera is live and waiting for a QR code.
  idle,

  /// QR detected, API validation call in progress.
  /// Camera is paused.
  processing,

  /// Validation result received and displayed.
  /// Camera is paused, result bottom sheet is visible.
  result,

  /// An error occurred during validation.
  /// Camera is paused, error shown in sheet.
  error,
}

/// Complete state of the ticket scanner screen.
///
/// Managed by [ScannerNotifier]. All scanner UI reads from this state.
class ScannerState {
  const ScannerState({
    this.status = ScanStatus.idle,
    this.lastResult,
    this.lastError,
    this.isFlashOn = false,
    this.isCameraActive = true,
    this.scannedCount = 0,
  });

  /// Current phase of the scanner state machine.
  final ScanStatus status;

  /// The most recent validation result.
  ///
  /// Non-null when [status] is [ScanStatus.result] or [ScanStatus.error].
  /// Null when [status] is [ScanStatus.idle] or [ScanStatus.processing].
  final TicketValidationResult? lastResult;

  /// Error message when [status] is [ScanStatus.error].
  ///
  /// Set when a network or unexpected error occurs during validation.
  final String? lastError;

  /// Whether the camera torch/flashlight is currently on.
  final bool isFlashOn;

  /// Whether the camera scanner is currently active (not paused).
  final bool isCameraActive;

  /// Running count of tickets scanned in this session.
  ///
  /// Incremented on every successful validation (regardless of result type).
  /// Displayed in the AppBar for operator awareness.
  final int scannedCount;

  // --------------------------------------------------------------------------
  // Computed
  // --------------------------------------------------------------------------

  bool get isIdle => status == ScanStatus.idle;
  bool get isProcessing => status == ScanStatus.processing;
  bool get hasResult => status == ScanStatus.result;
  bool get hasError => status == ScanStatus.error;

  // --------------------------------------------------------------------------
  // CopyWith
  // --------------------------------------------------------------------------

  ScannerState copyWith({
    ScanStatus? status,
    TicketValidationResult? lastResult,
    String? lastError,
    bool? isFlashOn,
    bool? isCameraActive,
    int? scannedCount,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      status: status ?? this.status,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      lastError: clearError ? null : (lastError ?? this.lastError),
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      scannedCount: scannedCount ?? this.scannedCount,
    );
  }

  @override
  String toString() => 'ScannerState('
      'status: $status, '
      'isFlashOn: $isFlashOn, '
      'isCameraActive: $isCameraActive, '
      'scannedCount: $scannedCount'
      ')';
}