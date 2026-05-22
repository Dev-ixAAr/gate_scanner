// ============================================================================
// Scanner Session Model — Backend response from setup token exchange
//
// Full implementation with freezed in Phase 5.
// Phase 1: Structure defined.
// ============================================================================

// TODO: Add freezed + json_serializable in Phase 5

/// Response model from the setup token verification endpoint.
///
/// Returned by the backend after a successful setup token exchange.
/// Contains the scanner session token and event details.
class ScannerSessionModel {
  const ScannerSessionModel({
    required this.sessionToken,
    required this.eventName,
    required this.eventPublicRef,
    required this.deviceName,
    required this.sessionStartedAt,
  });

  // TODO: Replace with freezed fromJson in Phase 5

  /// Scanner session token — used as Bearer token in all subsequent requests.
  final String sessionToken;

  /// Human-readable event name.
  final String eventName;

  /// Event public reference.
  final String eventPublicRef;

  /// Device name as registered on the backend.
  final String deviceName;

  /// Session creation timestamp.
  final DateTime sessionStartedAt;
}