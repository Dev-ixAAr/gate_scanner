// ============================================================================
// Scanner Session Model — Backend response from setup token exchange
//
// Returned by the backend when a valid setup token is exchanged.
// Contains the scanner session token and event details that are
// stored in SecureStorage via SessionService.
//
// EXPECTED BACKEND RESPONSE JSON:
// {
//   "session_token": "tok_scanner_xxxxxxxxxxxxxxxx",
//   "event_name": "Summer Music Festival 2024",
//   "event_public_ref": "EVT-2024-SUMMER-001",
//   "device_name": "Samsung SM-A536B",
//   "session_started_at": "2024-07-15T08:30:00.000Z",
//   "expires_at": "2024-07-16T00:00:00.000Z"  // optional
// }
//
// DESIGN DECISION:
// Plain Dart class with manual fromJson — not Freezed.
// This model is constructed once from the API response and immediately
// passed to SessionService.saveSession(). It is never mutated or used
// in a switch expression. Freezed overhead is not justified here.
// ============================================================================

/// Response model from the setup token verification endpoint.
///
/// Created by [ScannerSessionModel.fromJson] after a successful
/// setup token exchange. All fields from this model are saved to
/// secure storage via [SessionService.saveSession].
class ScannerSessionModel {
  const ScannerSessionModel({
    required this.sessionToken,
    required this.eventName,
    required this.eventPublicRef,
    required this.deviceName,
    required this.sessionStartedAt,
    this.expiresAt,
  });

  // ==========================================================================
  // FIELDS
  // ==========================================================================

  /// The scanner session token.
  ///
  /// Used as the Bearer token for all authenticated API requests.
  /// Stored in SecureStorage after successful token exchange.
  /// This is the primary auth credential for the scanner session.
  final String sessionToken;

  /// Human-readable event name.
  ///
  /// Example: 'Summer Music Festival 2024'
  /// Displayed on the home screen as the connected event.
  final String eventName;

  /// Event public reference identifier.
  ///
  /// Example: 'EVT-2024-SUMMER-001'
  /// Sent with all ticket validation requests.
  final String eventPublicRef;

  /// Device name as registered by the backend.
  ///
  /// The backend may use the submitted device info to generate a canonical
  /// device name. This name is displayed on the home screen.
  final String deviceName;

  /// Timestamp when this session was created on the server.
  ///
  /// Displayed on the home screen: "Session started at: ..."
  final DateTime sessionStartedAt;

  /// Optional session expiry timestamp.
  ///
  /// If provided, the app can show a countdown or warn the operator
  /// when the session is about to expire.
  /// If null, the session is valid until explicitly revoked.
  final DateTime? expiresAt;

  // ==========================================================================
  // FACTORY — fromJson
  // ==========================================================================

  /// Parses a [ScannerSessionModel] from the API response JSON Map.
  ///
  /// Throws [ScannerSessionParseException] if any required field is missing
  /// or cannot be parsed. This exception propagates up to [SetupRepository]
  /// which converts it to an [ApiException] for the UI.
  ///
  /// Field name mappings (snake_case → camelCase):
  /// - session_token → sessionToken
  /// - event_name → eventName
  /// - event_public_ref → eventPublicRef
  /// - device_name → deviceName
  /// - session_started_at → sessionStartedAt
  /// - expires_at → expiresAt (optional)
  factory ScannerSessionModel.fromJson(Map<String, dynamic> json) {
    // --- session_token -------------------------------------------------------
    final dynamic rawToken = json['session_token'];
    if (rawToken == null || rawToken.toString().trim().isEmpty) {
      throw const ScannerSessionParseException(
        field: 'session_token',
        message: 'Backend response missing required field: session_token',
      );
    }

    // --- event_name ----------------------------------------------------------
    final dynamic rawEventName = json['event_name'];
    if (rawEventName == null || rawEventName.toString().trim().isEmpty) {
      throw const ScannerSessionParseException(
        field: 'event_name',
        message: 'Backend response missing required field: event_name',
      );
    }

    // --- event_public_ref ----------------------------------------------------
    final dynamic rawEventRef = json['event_public_ref'];
    if (rawEventRef == null || rawEventRef.toString().trim().isEmpty) {
      throw const ScannerSessionParseException(
        field: 'event_public_ref',
        message: 'Backend response missing required field: event_public_ref',
      );
    }

    // --- device_name ---------------------------------------------------------
    final dynamic rawDeviceName = json['device_name'];
    // Device name may be null if the backend doesn't echo it back.
    // Fall back to empty string — it will be replaced by the local device info.
    final String deviceName =
        rawDeviceName?.toString().trim() ?? 'Gate Scanner Device';

    // --- session_started_at --------------------------------------------------
    final dynamic rawStartedAt = json['session_started_at'];
    DateTime sessionStartedAt;
    if (rawStartedAt == null) {
      // If backend doesn't return this, use current time as a fallback.
      sessionStartedAt = DateTime.now().toUtc();
    } else {
      final DateTime? parsed = DateTime.tryParse(rawStartedAt.toString());
      sessionStartedAt = parsed?.toUtc() ?? DateTime.now().toUtc();
    }

    // --- expires_at (optional) -----------------------------------------------
    DateTime? expiresAt;
    final dynamic rawExpiresAt = json['expires_at'];
    if (rawExpiresAt != null && rawExpiresAt.toString().isNotEmpty) {
      expiresAt = DateTime.tryParse(rawExpiresAt.toString())?.toUtc();
    }

    return ScannerSessionModel(
      sessionToken: rawToken.toString().trim(),
      eventName: rawEventName.toString().trim(),
      eventPublicRef: rawEventRef.toString().trim(),
      deviceName: deviceName,
      sessionStartedAt: sessionStartedAt,
      expiresAt: expiresAt,
    );
  }

  // ==========================================================================
  // SERIALIZATION
  // ==========================================================================

  Map<String, dynamic> toJson() {
    return {
      'session_token': sessionToken,
      'event_name': eventName,
      'event_public_ref': eventPublicRef,
      'device_name': deviceName,
      'session_started_at': sessionStartedAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  // ==========================================================================
  // DEBUG
  // ==========================================================================

  @override
  String toString() {
    // Never include session token in toString.
    return 'ScannerSessionModel('
        'eventName: "$eventName", '
        'eventPublicRef: "$eventPublicRef", '
        'deviceName: "$deviceName", '
        'sessionStartedAt: ${sessionStartedAt.toIso8601String()}, '
        'sessionToken: ***'
        ')';
  }
}

// ============================================================================
// SCANNER SESSION PARSE EXCEPTION
// ============================================================================

/// Thrown when the backend response cannot be parsed into a [ScannerSessionModel].
class ScannerSessionParseException implements Exception {
  const ScannerSessionParseException({
    required this.message,
    this.field,
  });

  final String message;
  final String? field;

  @override
  String toString() =>
      'ScannerSessionParseException: $message'
      '${field != null ? " (field: $field)" : ""}';
}