// ============================================================================
// Storage Keys — Secure storage key name constants
//
// All flutter_secure_storage key names are defined here as constants.
// This prevents key name typos and enables safe refactoring.
//
// SECURITY RULE:
// - Session token and server URL go in flutter_secure_storage (encrypted)
// - Non-sensitive preferences (sound enabled, etc.) go in shared_preferences
// - NEVER store session tokens in shared_preferences
// ============================================================================

/// Key name constants for flutter_secure_storage.
///
/// Use these constants whenever reading or writing to secure storage.
/// Never use raw string literals for storage keys.
abstract final class StorageKeys {
  StorageKeys._();

  // --------------------------------------------------------------------------
  // SESSION CREDENTIALS
  // These are the most sensitive values — stored encrypted via Android Keystore.
  // --------------------------------------------------------------------------

  /// The scanner session token returned by the backend after setup token exchange.
  /// Used as Bearer token in all subsequent API requests.
  /// Cleared on logout, reset, or session revocation.
  static const String sessionToken = 'scanner_session_token';

  // --------------------------------------------------------------------------
  // EVENT BINDING INFO
  // Stored after successful setup token exchange.
  // --------------------------------------------------------------------------

  /// The base URL of the event backend server.
  /// Example: 'https://events.yourcompany.com'
  /// Used as the Dio base URL for all API requests.
  static const String serverUrl = 'server_url';

  /// The public event reference identifier.
  /// Example: 'EVT-2024-XYZ'
  /// Sent with validation requests to scope them to the correct event.
  static const String eventPublicRef = 'event_public_ref';

  /// Human-readable event name for display on home screen.
  /// Example: 'Summer Music Festival 2024'
  static const String eventName = 'event_name';

  // --------------------------------------------------------------------------
  // SESSION METADATA
  // Stored for display on home screen and settings screen.
  // --------------------------------------------------------------------------

  /// ISO 8601 timestamp when the scanner session was created.
  /// Example: '2024-07-15T08:30:00.000Z'
  static const String sessionStartedAt = 'session_started_at';

  /// Human-readable device name for display and API payloads.
  /// Example: 'Gate 1 Scanner' or 'Samsung Galaxy A53'
  static const String deviceName = 'device_name';

  /// Unique device identifier generated at first app run.
  /// Stored to maintain consistent device identity across sessions.
  static const String deviceUuid = 'device_uuid';
}