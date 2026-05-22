// ============================================================================
// Route Names — Named route path constants
//
// All navigation route paths are defined here as constants.
// Using constants prevents typos and enables refactoring support.
//
// Convention: paths start with '/' and use kebab-case for multi-word paths.
// ============================================================================

/// Defines all named route paths used in the gate scanner app.
///
/// Import this file wherever route paths are needed to avoid
/// hardcoded string literals throughout the codebase.
abstract final class RouteNames {
  // Private constructor prevents instantiation.
  // This class is used as a namespace only.
  RouteNames._();

  /// Setup/onboarding screen.
  /// Shown when no active scanner session exists.
  /// Users must scan a setup QR code here to bind the device to an event.
  static const String setup = '/setup';

  /// Setup QR camera scanning screen.
  /// Sub-route within the setup flow.
  /// Opened from the welcome setup screen when user taps "Scan Setup QR".
  static const String setupScan = '/setup/scan';

  /// Scanner home dashboard screen.
  /// Shown when an active session exists.
  /// Displays event info, session status, and navigation to scan/search.
  static const String home = '/home';

  /// Ticket QR scan screen.
  /// Full-screen camera view for scanning attendee ticket QR codes.
  /// Accessible from the home screen.
  static const String scan = '/scan';

  /// Manual ticket search screen.
  /// Allows manual entry of ticket reference for lookup.
  /// Accessible from home screen and scan screen.
  static const String manualSearch = '/manual-search';

  /// Scanner session settings screen.
  /// Shows device info, session info, and logout/reset/switch options.
  /// Accessible from home screen via settings icon.
  static const String settings = '/settings';
}