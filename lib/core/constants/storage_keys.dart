// ============================================================================
// Storage Keys — flutter_secure_storage key name constants
//
// All key names used with flutter_secure_storage are defined here.
// Never use raw string literals as storage keys in feature code.
//
// SECURITY RULE:
// - Session tokens → flutter_secure_storage (Android Keystore backed)
// - Non-sensitive settings → SharedPreferences
// - NEVER mix these up
// ============================================================================

/// Secure storage key name constants for gate_scanner.
abstract final class StorageKeys {
  StorageKeys._();

  // ==========================================================================
  // AUTHENTICATION — MOST SENSITIVE
  // ==========================================================================

  /// Scanner session token returned by the backend after setup token exchange.
  ///
  /// This is the Bearer token used in the Authorization header for all
  /// authenticated API requests. It is the primary auth credential.
  ///
  /// Cleared on: logout, event reset, session revocation.
  /// Set by: successful setup token exchange (Phase 5).
  static const String sessionToken = 'scanner_session_token';

  // ==========================================================================
  // EVENT BINDING
  // Stored after successful setup token exchange.
  // Used in API requests and displayed on home/settings screens.
  // ==========================================================================

  /// Base URL of the backend server this scanner is bound to.
  ///
  /// Extracted from the setup QR code and stored after successful exchange.
  /// Used as the Dio base URL for ALL authenticated API calls.
  ///
  /// Example values:
  /// - 'https://tickets.yourcompany.com'
  /// - 'https://api.eventplatform.io'
  static const String serverUrl = 'server_url';

  /// The event public reference this scanner is bound to.
  ///
  /// Sent with every ticket validation request to scope it to the correct event.
  /// Prevents tickets from one event being validated at another event's gate.
  ///
  /// Example: 'EVT-2024-SUMMER-FEST'
  static const String eventPublicRef = 'event_public_ref';

  /// Human-readable event name for display on home screen.
  ///
  /// Example: 'Summer Music Festival 2024'
  static const String eventName = 'event_name';

  // ==========================================================================
  // SESSION METADATA
  // Informational fields displayed to the operator.
  // ==========================================================================

  /// ISO 8601 UTC timestamp when the scanner session was created.
  ///
  /// Stored as a string, parsed to DateTime when displayed.
  /// Example: '2024-07-15T08:30:00.000Z'
  static const String sessionStartedAt = 'session_started_at';

  /// Human-readable name for this scanner device.
  ///
  /// May be set by the backend based on device registration, or
  /// generated from device hardware info (brand + model).
  ///
  /// Example: 'Gate 1', 'Samsung Galaxy A53', 'Main Entrance Scanner'
  static const String deviceName = 'device_name';

  /// Unique UUID for this device installation.
  ///
  /// Generated once on first app launch and stored permanently.
  /// Used to maintain consistent device identity across sessions.
  /// Not cleared on session logout — only cleared on full app reinstall.
  static const String deviceUuid = 'device_uuid';
}