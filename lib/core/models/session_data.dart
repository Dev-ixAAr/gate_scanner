// ============================================================================
// Session Data Model — Active scanner session state
//
// Represents the complete session bound to this device.
// This model is assembled from individual keys stored in SecureStorage
// and serves as the single source of truth for session state throughout
// the app.
//
// Lifecycle:
// 1. Created by SessionService.saveSession() after successful token exchange
// 2. Read by SessionService.getSession() to hydrate app state on startup
// 3. Exposed via sessionDataProvider for reactive UI updates
// 4. Destroyed by SessionService.clearSession() on logout/reset/revocation
//
// Design choice: Plain Dart class (not freezed) because:
// - SessionData is only ever read, not modified in-place
// - The only mutation is a full replace (new session binding)
// - Avoids code generation dependency for a simple value object
// - copyWith is implemented manually for the few cases it's needed
// ============================================================================

/// Represents an active scanner session bound to a specific event and backend.
///
/// All fields are required — a partial session is not valid.
/// Use [SessionData.fromStorageValues] to safely construct from storage reads
/// that may return null for missing keys.
class SessionData {
  const SessionData({
    required this.serverUrl,
    required this.eventPublicRef,
    required this.eventName,
    required this.sessionToken,
    required this.sessionStartedAt,
    required this.deviceName,
  });

  // ==========================================================================
  // FIELDS
  // ==========================================================================

  /// Base URL of the backend server this scanner is bound to.
  ///
  /// Used as the Dio base URL for ALL authenticated API requests.
  /// This is the [server_url] field from the setup QR code.
  ///
  /// Examples:
  /// - 'https://tickets.yourcompany.com'
  /// - 'http://192.168.1.100:8000' (local development)
  final String serverUrl;

  /// Public event reference identifier.
  ///
  /// Sent with every ticket validation request to scope the lookup
  /// to the correct event. Prevents cross-event ticket acceptance.
  ///
  /// Example: 'EVT-2024-SUMMER-FEST-001'
  final String eventPublicRef;

  /// Human-readable event name for display in the UI.
  ///
  /// Shown prominently on the home screen so the operator can
  /// confirm they are scanning for the correct event.
  ///
  /// Example: 'Summer Music Festival 2024'
  final String eventName;

  /// Scanner session authentication token.
  ///
  /// Used as the Bearer token in the Authorization header for all
  /// authenticated API calls. This is the most sensitive stored value.
  ///
  /// ⚠ Never log, display, or transmit this value outside of the
  /// Authorization header. It is stored encrypted via Android Keystore.
  final String sessionToken;

  /// Timestamp when this scanner session was established.
  ///
  /// Displayed on the home screen so operators can see how long
  /// the scanner has been running. Stored as ISO 8601 string,
  /// parsed to DateTime when the session is loaded.
  final DateTime sessionStartedAt;

  /// Display name for this scanner device.
  ///
  /// Set by the backend during session creation (may be derived from
  /// device hardware info or a custom name set by the administrator).
  ///
  /// Examples: 'Gate 1', 'Main Entrance', 'Samsung Galaxy A53 (Gate 2)'
  final String deviceName;

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  /// Constructs a [SessionData] from raw secure storage values.
  ///
  /// Returns [null] if any required field is missing or cannot be parsed.
  /// This handles the case where:
  /// - The device has never been set up (all values null)
  /// - Storage was partially written (a write failed mid-session-save)
  /// - A field format changed between app versions (date parse failure)
  ///
  /// Usage:
  /// ```dart
  /// final session = SessionData.fromStorageValues(
  ///   serverUrl: await storage.read(key: StorageKeys.serverUrl),
  ///   eventPublicRef: await storage.read(key: StorageKeys.eventPublicRef),
  ///   // ... all fields
  /// );
  /// if (session == null) {
  ///   // No valid session — show setup screen
  /// }
  /// ```
  static SessionData? fromStorageValues({
    required String? serverUrl,
    required String? eventPublicRef,
    required String? eventName,
    required String? sessionToken,
    required String? sessionStartedAt,
    required String? deviceName,
  }) {
    // All fields are required. If any is null, the session is invalid.
    if (serverUrl == null ||
        serverUrl.isEmpty ||
        eventPublicRef == null ||
        eventPublicRef.isEmpty ||
        eventName == null ||
        eventName.isEmpty ||
        sessionToken == null ||
        sessionToken.isEmpty ||
        sessionStartedAt == null ||
        sessionStartedAt.isEmpty ||
        deviceName == null ||
        deviceName.isEmpty) {
      return null;
    }

    // Parse the ISO 8601 session start timestamp.
    // Returns null if the format is invalid (e.g., from an old app version).
    final DateTime? parsedDate = DateTime.tryParse(sessionStartedAt);
    if (parsedDate == null) {
      return null;
    }

    return SessionData(
      serverUrl: serverUrl.trim(),
      eventPublicRef: eventPublicRef.trim(),
      eventName: eventName.trim(),
      sessionToken: sessionToken.trim(),
      sessionStartedAt: parsedDate,
      deviceName: deviceName.trim(),
    );
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  /// Returns a copy of this [SessionData] with specified fields replaced.
  ///
  /// Used when the backend returns an updated event name or device name
  /// during a session refresh, without requiring a full re-authentication.
  SessionData copyWith({
    String? serverUrl,
    String? eventPublicRef,
    String? eventName,
    String? sessionToken,
    DateTime? sessionStartedAt,
    String? deviceName,
  }) {
    return SessionData(
      serverUrl: serverUrl ?? this.serverUrl,
      eventPublicRef: eventPublicRef ?? this.eventPublicRef,
      eventName: eventName ?? this.eventName,
      sessionToken: sessionToken ?? this.sessionToken,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  // ==========================================================================
  // COMPUTED PROPERTIES
  // ==========================================================================

  /// Returns a URL-safe display version of the server URL.
  ///
  /// Strips the protocol prefix for compact display in the UI.
  /// Example: 'https://tickets.company.com' → 'tickets.company.com'
  String get serverUrlDisplay {
    return serverUrl
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
  }

  /// Returns the server URL with trailing slash removed.
  ///
  /// Used when constructing API endpoint URLs.
  String get serverUrlNormalized {
    return serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
  }

  // ==========================================================================
  // EQUALITY AND HASH
  // ==========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionData &&
        other.serverUrl == serverUrl &&
        other.eventPublicRef == eventPublicRef &&
        other.eventName == eventName &&
        other.sessionToken == sessionToken &&
        other.sessionStartedAt == sessionStartedAt &&
        other.deviceName == deviceName;
  }

  @override
  int get hashCode {
    return Object.hash(
      serverUrl,
      eventPublicRef,
      eventName,
      sessionToken,
      sessionStartedAt,
      deviceName,
    );
  }

  // ==========================================================================
  // DEBUG REPRESENTATION
  // ==========================================================================

  @override
  String toString() {
    // Never include sessionToken in toString — it may end up in logs.
    return 'SessionData('
        'eventName: "$eventName", '
        'eventPublicRef: "$eventPublicRef", '
        'serverUrl: "$serverUrl", '
        'deviceName: "$deviceName", '
        'sessionStartedAt: ${sessionStartedAt.toIso8601String()}, '
        'sessionToken: ***'
        ')';
  }
}