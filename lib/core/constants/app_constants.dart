// ============================================================================
// App Constants — Application-wide constant values
//
// All magic numbers, timeout values, limits, and string constants.
// Never use hardcoded literals in feature code — reference these constants.
// ============================================================================

/// Application-wide constants for gate_scanner.
abstract final class AppConstants {
  AppConstants._();

  // ==========================================================================
  // APP IDENTITY
  // ==========================================================================

  /// Display name of the application.
  static const String appName = 'Gate Scanner';

  /// Short name used in compact UI spaces.
  static const String appNameShort = 'GateScanner';

  /// Organization name — shown in about/settings screens.
  static const String orgName = 'Your Company';

  /// Fallback version string if package_info_plus fails to read pubspec.
  static const String fallbackVersion = '1.0.0';

  /// Fallback build number.
  static const String fallbackBuildNumber = '1';

  // ==========================================================================
  // API / NETWORK TIMEOUTS (milliseconds)
  // ==========================================================================

  /// Maximum time to wait for a connection to be established.
  /// If the server doesn't respond in this time, show a network error.
  static const int apiConnectTimeoutMs = 10000; // 10 seconds

  /// Maximum time to wait for response data after connecting.
  /// Set higher than connect timeout for DB-heavy operations like ticket lookup.
  static const int apiReceiveTimeoutMs = 30000; // 30 seconds

  /// Maximum time to wait while sending the request body.
  static const int apiSendTimeoutMs = 10000; // 10 seconds

  // ==========================================================================
  // SESSION MANAGEMENT
  // ==========================================================================

  /// How often the home screen polls the backend to verify the session
  /// is still active. Detects remote revocation by administrators.
  static const int sessionPollIntervalSeconds = 60; // 1 minute

  /// Maximum number of consecutive session check failures before forcing
  /// the user to re-authenticate. Prevents false logouts on brief outages.
  static const int maxSessionCheckFailures = 3;

  // ==========================================================================
  // SCANNER BEHAVIOR
  // ==========================================================================

  /// Minimum delay (ms) between processing two QR scans.
  /// Prevents rapid duplicate scans of the same ticket.
  static const int scanDebounceMs = 1500; // 1.5 seconds

  /// How long to show the scan result before auto-dismissing (ms).
  /// Set to 0 to require manual dismissal.
  static const int scanResultAutoDismissMs = 0; // Manual dismiss (safer)

  /// Maximum number of consecutive scan errors before showing
  /// a "scanner may be experiencing issues" message.
  static const int maxConsecutiveScanErrors = 5;

  // ==========================================================================
  // UI — SPACING AND DIMENSIONS
  // ==========================================================================

  /// Standard horizontal padding for all screen-level content.
  static const double screenPaddingHorizontal = 20.0;

  /// Standard vertical padding for all screen-level content.
  static const double screenPaddingVertical = 24.0;

  /// Standard spacing between cards/sections on a screen.
  static const double sectionSpacing = 16.0;

  /// Standard spacing between items within a card.
  static const double itemSpacing = 12.0;

  // ==========================================================================
  // UI — BORDER RADIUS
  // ==========================================================================

  /// Border radius for chips and badges.
  static const double radiusBadge = 100.0;

  /// Border radius for small components (inputs, small cards).
  static const double radiusSmall = 8.0;

  /// Border radius for standard cards.
  static const double radiusCard = 12.0;

  /// Border radius for large cards and bottom sheets.
  static const double radiusLarge = 16.0;

  /// Border radius for extra-large surfaces (modals, scan result sheet).
  static const double radiusXLarge = 24.0;

  // ==========================================================================
  // QR SCANNER OVERLAY
  // ==========================================================================

  /// Scan frame width as a fraction of the screen width (0.0 to 1.0).
  static const double scanFrameWidthFraction = 0.72;

  /// Length of the corner markers on the scan frame (dp).
  static const double scanFrameCornerLength = 28.0;

  /// Width/thickness of the corner marker stroke (dp).
  static const double scanFrameCornerStrokeWidth = 4.0;

  /// Border radius of the scan frame corners.
  static const double scanFrameCornerRadius = 6.0;

  // ==========================================================================
  // VALIDATION STATUS VALUES
  // These must match exactly what the backend sends in validation_status field.
  // ==========================================================================

  static const String statusValid = 'valid';
  static const String statusAlreadyUsed = 'already_used';
  static const String statusRevoked = 'revoked';
  static const String statusCancelled = 'cancelled';
  static const String statusInvalid = 'invalid';
  static const String statusWrongEvent = 'wrong_event';

  // ==========================================================================
  // TICKET SOURCE TYPES
  // ==========================================================================

  static const String sourceOnline = 'online';
  static const String sourcePhysical = 'physical';
  static const String sourceComplimentary = 'complimentary';

  // ==========================================================================
  // DEVICE TYPE VALUES
  // Sent with API payloads.
  // ==========================================================================

  static const String deviceTypePhone = 'phone';
  static const String deviceTypeTablet = 'tablet';
  static const String osAndroid = 'Android';
}

// ==========================================================================
// SECURITY — customize for your organization before production release
// ==========================================================================

/// Security-related configuration for server URLs and TLS pinning.
abstract final class AppSecurityConfig {
  AppSecurityConfig._();

  /// **Default: dynamic server URL per event (from setup QR).**
  ///
  /// When `false`, any hostname in the setup QR is accepted if the URL is
  /// valid HTTPS (release) or HTTP/HTTPS to local dev hosts (debug).
  /// Use this when each event/customer has a different API domain.
  ///
  /// Set to `true` only if you want to lock the app to specific domains.
  static const bool enforceHostAllowlist = false;

  /// Used only when [enforceHostAllowlist] is `true`.
  ///
  /// Example: `yourcompany.com` also allows `api.yourcompany.com`.
  static const List<String> allowedServerHostSuffixes = <String>[
    // 'yourcompany.com',
  ];

  /// SHA-256 certificate fingerprints (base64) per API hostname.
  ///
  /// Example: `'api.yourcompany.com': ['abcd1234...']`
  /// Generate: `openssl s_client -connect api.example.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64`
  static const Map<String, List<String>> certificatePinSha256 =
      <String, List<String>>{
    // 'api.yourcompany.com': ['YOUR_BASE64_SHA256_PIN_HERE'],
  };

  /// API error codes that mean the scanner session was revoked (403 responses).
  static const Set<String> sessionRevokedErrorCodes = {
    'SESSION_REVOKED',
    'SCANNER_SESSION_REVOKED',
    'session_revoked',
  };

  /// Manual setup: client-side max age before local expiry blocks exchange.
  static const int manualSetupMaxAgeHours = 24;
}