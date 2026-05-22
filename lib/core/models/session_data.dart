// ============================================================================
// Session Data Model — Active scanner session information
//
// Represents the complete session state stored in secure storage.
// This model is the single source of truth for whether the device
// is bound to an event and has an active scanner session.
//
// Full implementation in Phase 3 (Session Service).
// Phase 1: Model structure defined.
// ============================================================================

/// Represents an active scanner session.
///
/// Created after a successful setup token exchange.
/// Stored fields are persisted in flutter_secure_storage.
/// Cleared on logout, event reset, or remote session revocation.
class SessionData {
  const SessionData({
    required this.serverUrl,
    required this.eventPublicRef,
    required this.eventName,
    required this.sessionToken,
    required this.sessionStartedAt,
    required this.deviceName,
  });

  /// Base URL of the backend server this session is bound to.
  /// Example: 'https://events.yourcompany.com'
  /// Used as Dio base URL for all API requests.
  final String serverUrl;

  /// Public event reference identifier.
  /// Example: 'EVT-2024-SUMMER'
  /// Sent with all ticket validation requests.
  final String eventPublicRef;

  /// Human-readable event name for display on home screen.
  /// Example: 'Summer Music Festival 2024'
  final String eventName;

  /// Scanner session token for API authentication.
  /// Used as: 'Authorization: Bearer <sessionToken>'
  /// This is the most sensitive stored value.
  final String sessionToken;

  /// When this scanner session was started.
  /// Displayed on home screen and settings screen.
  final DateTime sessionStartedAt;

  /// Device display name for this scanner.
  /// Shown on home screen and sent with API requests.
  final String deviceName;

  /// Creates a [SessionData] from individual secure storage values.
  ///
  /// Returns null if any required field is missing.
  static SessionData? fromStorageValues({
    required String? serverUrl,
    required String? eventPublicRef,
    required String? eventName,
    required String? sessionToken,
    required String? sessionStartedAt,
    required String? deviceName,
  }) {
    if (serverUrl == null ||
        eventPublicRef == null ||
        eventName == null ||
        sessionToken == null ||
        sessionStartedAt == null ||
        deviceName == null) {
      return null;
    }

    final DateTime? parsedDate = DateTime.tryParse(sessionStartedAt);
    if (parsedDate == null) return null;

    return SessionData(
      serverUrl: serverUrl,
      eventPublicRef: eventPublicRef,
      eventName: eventName,
      sessionToken: sessionToken,
      sessionStartedAt: parsedDate,
      deviceName: deviceName,
    );
  }

  @override
  String toString() {
    return 'SessionData('
        'eventName: $eventName, '
        'eventPublicRef: $eventPublicRef, '
        'serverUrl: $serverUrl, '
        'deviceName: $deviceName, '
        'sessionStartedAt: $sessionStartedAt'
        ')';
  }
}