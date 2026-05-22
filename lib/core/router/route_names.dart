// ============================================================================
// Route Names — Named route path constants
//
// All navigation route paths are defined as constants here.
// Import this file wherever navigation is needed.
//
// Convention:
// - All paths start with '/'
// - Multi-word paths use kebab-case: /manual-search
// - Sub-routes use the parent path as prefix: /setup/scan
// ============================================================================

/// Defines all named route paths used in the gate scanner app.
abstract final class RouteNames {
  RouteNames._();

  // ==========================================================================
  // SETUP FLOW — Unconfigured device binding
  // ==========================================================================

  /// Welcome/setup screen — shown when no active session exists.
  /// Users must complete setup here before accessing any other screen.
  static const String setup = '/setup';

  /// Setup QR camera scanning screen — sub-route of setup.
  /// Opened when user taps "Scan Setup QR" on the welcome screen.
  static const String setupScan = '/setup/scan';

  /// Manual setup entry screen — sub-route of setup.
  /// Operator types server_url, event_public_ref, and setup_token.
  static const String setupManual = '/setup/manual';

  // ==========================================================================
  // MAIN APP — Session-protected screens
  // ==========================================================================

  /// Scanner home dashboard — shown when an active session exists.
  /// Entry point to all scanning features.
  static const String home = '/home';

  /// Ticket QR scan screen — full-screen camera for ticket scanning.
  /// Requires active session.
  static const String scan = '/scan';

  /// Manual ticket search — type-in reference lookup.
  /// Alternative to camera scanning.
  static const String manualSearch = '/manual-search';

  /// Session settings — device info, logout, reset, switch event.
  static const String settings = '/settings';
}