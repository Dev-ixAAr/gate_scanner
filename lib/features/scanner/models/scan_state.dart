// ============================================================================
// Scan State — Enum for ticket scanner states
//
// Full implementation in Phase 7.
// Phase 1: Enum defined.
// ============================================================================

/// Represents the current state of the ticket scanner.
///
/// Used by the scanner provider to control UI state transitions.
enum ScanStatus {
  /// Camera is ready, waiting for a QR code to be detected.
  idle,

  /// A QR code has been detected, sending to backend for validation.
  processing,

  /// Validation result received, showing result to operator.
  result,

  /// An error occurred during scanning or validation.
  error,
}