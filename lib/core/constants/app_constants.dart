// ============================================================================
// App Constants — Application-wide constant values
//
// Centralizes all magic numbers and strings used across the app.
// ============================================================================

/// Application-wide constant values.
///
/// All magic numbers, timeout values, and string constants used
/// throughout the app are defined here for easy maintenance.
abstract final class AppConstants {
  AppConstants._();

  // --------------------------------------------------------------------------
  // APP INFO
  // --------------------------------------------------------------------------

  /// Display name of the application.
  static const String appName = 'Gate Scanner';

  /// Fallback version string used when package_info_plus is unavailable.
  static const String fallbackVersion = '1.0.0';

  // --------------------------------------------------------------------------
  // API TIMEOUTS
  // All values in milliseconds.
  // --------------------------------------------------------------------------

  /// Connection timeout for API requests.
  /// If the server does not respond within this time, throw a connection error.
  static const int apiConnectTimeoutMs = 10000; // 10 seconds

  /// Receive timeout for API requests.
  /// If data is not received within this time after connection, throw an error.
  /// Set higher for ticket validation which may involve DB lookups.
  static const int apiReceiveTimeoutMs = 30000; // 30 seconds

  /// Send timeout for uploading request body data.
  static const int apiSendTimeoutMs = 10000; // 10 seconds

  // --------------------------------------------------------------------------
  // SESSION
  // --------------------------------------------------------------------------

  /// How often to poll the backend to verify session is still active.
  /// Used in the home screen to detect remote session revocation.
  static const int sessionPollIntervalSeconds = 60; // 1 minute

  // --------------------------------------------------------------------------
  // SCANNER
  // --------------------------------------------------------------------------

  /// Delay in milliseconds after a scan result is shown before
  /// the camera automatically resumes scanning.
  /// Gives the operator time to read the result.
  static const int scanResultAutoDismissMs = 3000; // 3 seconds

  /// Maximum number of scan retries before showing a "scanner error" state.
  static const int maxScanRetries = 3;

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  /// Standard border radius for cards and containers.
  static const double borderRadiusCard = 12.0;

  /// Standard border radius for buttons.
  static const double borderRadiusButton = 10.0;

  /// Standard border radius for chips and badges.
  static const double borderRadiusBadge = 20.0;

  /// Standard horizontal padding for screen content.
  static const double screenPaddingHorizontal = 20.0;

  /// Standard vertical padding for screen content.
  static const double screenPaddingVertical = 24.0;

  // --------------------------------------------------------------------------
  // QR SCANNER
  // --------------------------------------------------------------------------

  /// Width of the QR scanning frame as a fraction of screen width.
  static const double scanFrameWidthFraction = 0.75;

  /// Height of the QR scanning frame (square, matches width fraction).
  static const double scanFrameHeightFraction = 0.75;
}