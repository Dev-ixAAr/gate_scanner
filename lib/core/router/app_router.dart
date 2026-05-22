// ============================================================================
// App Router — GoRouter Configuration
//
// Provides declarative routing with session-based access control.
//
// ROUTE GUARD LOGIC:
// 1. On every navigation attempt, read session token from secure storage
// 2. No token → force redirect to /setup (device not configured)
// 3. Token exists + navigating to setup route → redirect to /home
//    (device is already configured, don't allow back to setup)
// 4. Token exists + navigating to any other route → allow
//
// REMOTE REVOCATION:
// When a 401 is received from the API (handled in SessionRevokeInterceptor),
// the session is cleared and the router is refreshed via the listenable.
// This automatically re-runs the redirect guard and routes to /setup.
//
// IMPORTANT — Phase 2 note:
// This router uses real SecureStorageService for the session guard.
// Feature screens are still Phase 1 placeholders — replaced phase by phase.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/storage_keys.dart';
import '../secure_storage/secure_storage_service.dart';
import 'route_names.dart';

// ---- Placeholder screen imports (Phase 1) ----------------------------------
// TODO: Replace these with real screen imports phase by phase.
// Phase 4: Setup screens
// Phase 6: Home screen
// Phase 7: Scanner screen
// Phase 8: Manual search screen
// Phase 9: Settings screen

// Generated file — run: dart run build_runner build --delete-conflicting-outputs
part 'app_router.g.dart';

// ==========================================================================
// ROUTER REFRESH NOTIFIER
//
// A [ChangeNotifier] that can be called to force GoRouter to re-evaluate
// its redirect guard. Used when:
// - Session is established (after setup → redirect to home)
// - Session is revoked (after 401 → redirect to setup)
//
// The notifier is injected into GoRouter's refreshListenable.
// When notifier.refresh() is called, GoRouter re-runs the redirect function.
// ==========================================================================

/// Controls GoRouter refresh cycles from outside the widget tree.
///
/// Used by [SessionRevokeInterceptor] (Phase 5+) to force the router to
/// re-evaluate the session guard after clearing a revoked session.
///
/// Usage:
/// ```dart
/// ref.read(routerRefreshNotifierProvider).refresh();
/// ```
class RouterRefreshNotifier extends ChangeNotifier {
  /// Triggers GoRouter to re-run all redirect guards.
  ///
  /// Call this after any session state change:
  /// - After successful setup → routes to /home
  /// - After logout/reset → routes to /setup
  /// - After remote revocation detected → routes to /setup
  void refresh() {
    notifyListeners();
  }
}

/// Provider for [RouterRefreshNotifier].
///
/// Declared as a globally accessible provider so interceptors and
/// providers in other features can trigger router refreshes.
final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  // Dispose the notifier when the provider is destroyed.
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ==========================================================================
// APP ROUTER PROVIDER
// ==========================================================================

/// Provides the configured [GoRouter] instance for the entire app.
///
/// Annotated with @riverpod so it can be watched in the widget tree.
/// The router watches [routerRefreshNotifierProvider] for session changes.
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Access secure storage for session guard checks.
  final storage = ref.read(secureStorageServiceProvider);

  // Access the refresh notifier — router listens to this for re-evaluation.
  final refreshNotifier = ref.read(routerRefreshNotifierProvider);

  return GoRouter(
    // Default initial route.
    // The redirect guard will override this immediately based on session state.
    initialLocation: RouteNames.setup,

    // Listen to the refresh notifier.
    // When refreshNotifier.refresh() is called, the redirect guard re-runs.
    // This enables programmatic session-based redirects from outside the router.
    refreshListenable: refreshNotifier,

    // Debug logging — shows route transitions in the console.
    // Keep true during development; set to false for production.
    debugLogDiagnostics: true,

    // =========================================================================
    // SESSION GUARD — Redirect function
    //
    // Called on every navigation attempt (initial, push, go, replace).
    // Must be async because reading secure storage is async.
    //
    // Returns:
    // - null     → allow navigation to the requested route
    // - String   → redirect to the returned path instead
    // =========================================================================
    redirect: (BuildContext context, GoRouterState state) async {
      // Read the session token from secure storage.
      // This is the single source of truth for whether the device is configured.
      final String? sessionToken = await storage.read(StorageKeys.sessionToken);
      final bool hasActiveSession =
          sessionToken != null && sessionToken.trim().isNotEmpty;

      // Current location being navigated to.
      final String currentLocation = state.matchedLocation;

      // Determine if the target is within the setup flow.
      // The setup flow is accessible only to unconfigured devices.
      final bool isSetupRoute = currentLocation == RouteNames.setup ||
          currentLocation == RouteNames.setupScan;

      // ------------------------------------------------------------------
      // CASE 1: No session, not already on setup route
      // Force user to setup — device must be configured first.
      // ------------------------------------------------------------------
      if (!hasActiveSession && !isSetupRoute) {
        return RouteNames.setup;
      }

      // ------------------------------------------------------------------
      // CASE 2: Has session, trying to go to setup route
      // Device is already configured — redirect to home dashboard.
      // Prevents a configured scanner from accidentally re-running setup.
      // ------------------------------------------------------------------
      if (hasActiveSession && isSetupRoute) {
        return RouteNames.home;
      }

      // ------------------------------------------------------------------
      // CASE 3: All other cases — allow navigation.
      // - Has session, navigating to home/scan/search/settings → allow
      // - No session, already on setup route → allow
      // ------------------------------------------------------------------
      return null;
    },

    // =========================================================================
    // ROUTES
    // =========================================================================
    routes: [
      // -----------------------------------------------------------------------
      // SETUP FLOW
      // -----------------------------------------------------------------------

      GoRoute(
        path: RouteNames.setup,
        name: 'setup',
        // TODO: Phase 4 — replace builder with:
        // builder: (context, state) => const WelcomeSetupScreen(),
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'WelcomeSetupScreen',
          phase: 'Phase 4',
          icon: Icons.qr_code_scanner,
          description:
              'Welcome screen for unconfigured scanners.\n'
              'Users scan the admin setup QR code here.',
        ),
        routes: [
          GoRoute(
            path: 'scan',  // Full path: /setup/scan
            name: 'setup-scan',
            // TODO: Phase 4 — replace builder with:
            // builder: (context, state) => const SetupQrScanScreen(),
            builder: (context, state) => const _PlaceholderScreen(
              screenName: 'SetupQrScanScreen',
              phase: 'Phase 4',
              icon: Icons.camera_alt_outlined,
              description:
                  'Camera view for scanning the admin setup QR code.\n'
                  'After successful scan: token exchange → session stored.',
            ),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // HOME (Session-protected)
      // -----------------------------------------------------------------------

      GoRoute(
        path: RouteNames.home,
        name: 'home',
        // TODO: Phase 6 — replace builder with:
        // builder: (context, state) => const ScannerHomeScreen(),
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'ScannerHomeScreen',
          phase: 'Phase 6',
          icon: Icons.dashboard_outlined,
          description:
              'Dashboard shown when scanner session is active.\n'
              'Shows event name, server, device, session start time.',
          showNavigationLinks: true,
        ),
      ),

      // -----------------------------------------------------------------------
      // TICKET SCAN (Session-protected)
      // -----------------------------------------------------------------------

      GoRoute(
        path: RouteNames.scan,
        name: 'scan',
        // TODO: Phase 7 — replace builder with:
        // builder: (context, state) => const TicketScanScreen(),
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'TicketScanScreen',
          phase: 'Phase 7',
          icon: Icons.qr_code_2,
          description:
              'Full-screen camera for scanning attendee ticket QR codes.\n'
              'Shows validation result as modal bottom sheet.',
        ),
      ),

      // -----------------------------------------------------------------------
      // MANUAL SEARCH (Session-protected)
      // -----------------------------------------------------------------------

      GoRoute(
        path: RouteNames.manualSearch,
        name: 'manual-search',
        // TODO: Phase 8 — replace builder with:
        // builder: (context, state) => const ManualSearchScreen(),
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'ManualSearchScreen',
          phase: 'Phase 8',
          icon: Icons.search,
          description:
              'Manual ticket reference entry and lookup.\n'
              'Alternative to camera scanning for accessibility.',
        ),
      ),

      // -----------------------------------------------------------------------
      // SETTINGS (Session-protected)
      // -----------------------------------------------------------------------

      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        // TODO: Phase 9 — replace builder with:
        // builder: (context, state) => const SessionSettingsScreen(),
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'SessionSettingsScreen',
          phase: 'Phase 9',
          icon: Icons.settings_outlined,
          description:
              'Device info, session info, logout, reset, switch event.',
        ),
      ),
    ],

    // =========================================================================
    // ERROR HANDLER — Unknown/invalid routes
    // =========================================================================
    errorBuilder: (context, state) => _RouterErrorScreen(
      uri: state.uri.toString(),
      error: state.error?.toString(),
    ),
  );
}

// ============================================================================
// PHASE 2 PLACEHOLDER SCREEN
//
// Used for all routes in Phase 2 until real screens are built.
// Shows route info, description, and navigation test buttons.
// Will be removed route-by-route in Phases 4-9.
// ============================================================================

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.screenName,
    required this.phase,
    required this.icon,
    required this.description,
    this.showNavigationLinks = false,
  });

  final String screenName;
  final String phase;
  final IconData icon;
  final String description;
  final bool showNavigationLinks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(screenName),
        actions: [
          // Settings shortcut — available on all screens for testing
          if (screenName != 'SessionSettingsScreen')
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go(RouteNames.settings),
              tooltip: 'Settings',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phase badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1A00D16C),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0x4000D16C)),
                  ),
                  child: Text(
                    'PLACEHOLDER — $phase',
                    style: const TextStyle(
                      color: Color(0xFF00D16C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Screen icon and name
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFF00D16C),
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      screenName,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Navigation links (shown only on home placeholder)
              if (showNavigationLinks) ...[
                const SizedBox(height: 24),
                Text(
                  'NAVIGATION',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                _NavButton(
                  label: 'Start Scanning',
                  icon: Icons.qr_code_scanner,
                  onTap: () => context.go(RouteNames.scan),
                ),
                const SizedBox(height: 8),
                _NavButton(
                  label: 'Manual Search',
                  icon: Icons.search,
                  onTap: () => context.go(RouteNames.manualSearch),
                ),
                const SizedBox(height: 8),
                _NavButton(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => context.go(RouteNames.settings),
                ),
              ],

              const SizedBox(height: 24),

              // DEBUG: Force-navigate to setup (test session guard)
              // This simulates what happens when a session is cleared.
              _DebugSection(screenName: screenName),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00D16C), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF6B6B6B),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug section shown only in debug builds.
/// Allows testing session guard by forcing navigation to setup.
class _DebugSection extends ConsumerWidget {
  const _DebugSection({required this.screenName});

  final String screenName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    if (!isDebug) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Color(0xFF2A2A2A)),
        const SizedBox(height: 12),
        Text(
          'DEBUG TOOLS',
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.go(RouteNames.setup),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Force → Setup (test session guard)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFB020),
            side: const BorderSide(color: Color(0xFFFFB020)),
          ),
        ),
        const SizedBox(height: 8),
        if (screenName != 'ScannerHomeScreen')
          OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.home),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('Force → Home (test session guard)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A84FF),
              side: const BorderSide(color: Color(0xFF0A84FF)),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// ROUTER ERROR SCREEN
// Shown when navigation is attempted to a non-existent route.
// ============================================================================

class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen({
    required this.uri,
    this.error,
  });

  final String uri;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Error'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF3B30),
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                'Route Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '"$uri" does not exist in this app.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF3B30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x40FF3B30)),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.setup),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Return to Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}