// ============================================================================
// App Router — Updated for Phase 4
//
// Changes from Phase 2:
// - /setup route now uses WelcomeSetupScreen (real implementation)
// - /setup/scan route now uses SetupQrScanScreen (real implementation)
// - All other routes remain as Phase 2 placeholders
// - SetupQrScanNotifier state is reset when navigating to setup routes
//   to prevent stale state from a previous scan session
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/storage_keys.dart';
import '../secure_storage/secure_storage_service.dart';
import 'route_names.dart';

// Phase 4 real screens
import '../../features/setup/screens/welcome_setup_screen.dart';
import '../../features/setup/screens/setup_qr_scan_screen.dart';

// Generated file — run: dart run build_runner build --delete-conflicting-outputs
part 'app_router.g.dart';

// ============================================================================
// ROUTER REFRESH NOTIFIER (unchanged from Phase 2)
// ============================================================================

/// Controls GoRouter refresh cycles from outside the widget tree.
class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// Provider for [RouterRefreshNotifier].
final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ============================================================================
// APP ROUTER PROVIDER
// ============================================================================

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final storage = ref.read(secureStorageServiceProvider);
  final refreshNotifier = ref.read(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.setup,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: true,

    // =========================================================================
    // SESSION GUARD
    // =========================================================================
    redirect: (BuildContext context, GoRouterState state) async {
      final String? sessionToken =
          await storage.read(key: StorageKeys.sessionToken);
      final bool hasActiveSession =
          sessionToken != null && sessionToken.trim().isNotEmpty;

      final String currentLocation = state.matchedLocation;
      final bool isSetupRoute = currentLocation == RouteNames.setup ||
          currentLocation == RouteNames.setupScan;

      if (!hasActiveSession && !isSetupRoute) return RouteNames.setup;
      if (hasActiveSession && isSetupRoute) return RouteNames.home;
      return null;
    },

    // =========================================================================
    // ROUTES
    // =========================================================================
    routes: [
      // -----------------------------------------------------------------------
      // SETUP FLOW — Phase 4: Real screens implemented
      // -----------------------------------------------------------------------

      GoRoute(
        path: RouteNames.setup,
        name: 'setup',
        // ✅ Phase 4: Real screen
        builder: (context, state) => const WelcomeSetupScreen(),
        routes: [
          GoRoute(
            path: 'scan',
            name: 'setup-scan',
            // ✅ Phase 4: Real screen
            builder: (context, state) => const SetupQrScanScreen(),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // HOME — Phase 6 placeholder
      // -----------------------------------------------------------------------
      GoRoute(
        path: RouteNames.home,
        name: 'home',
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
      // SCAN — Phase 7 placeholder
      // -----------------------------------------------------------------------
      GoRoute(
        path: RouteNames.scan,
        name: 'scan',
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'TicketScanScreen',
          phase: 'Phase 7',
          icon: Icons.qr_code_2,
          description:
              'Full-screen camera for scanning attendee ticket QR codes.',
        ),
      ),

      // -----------------------------------------------------------------------
      // MANUAL SEARCH — Phase 8 placeholder
      // -----------------------------------------------------------------------
      GoRoute(
        path: RouteNames.manualSearch,
        name: 'manual-search',
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'ManualSearchScreen',
          phase: 'Phase 8',
          icon: Icons.search,
          description: 'Manual ticket reference entry and lookup.',
        ),
      ),

      // -----------------------------------------------------------------------
      // SETTINGS — Phase 9 placeholder
      // -----------------------------------------------------------------------
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
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
    // ERROR HANDLER
    // =========================================================================
    errorBuilder: (context, state) => _RouterErrorScreen(
      uri: state.uri.toString(),
      error: state.error?.toString(),
    ),
  );
}

// ============================================================================
// PLACEHOLDER SCREEN (unchanged from Phase 2 — used for Phases 6-9)
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: const Color(0xFF00D16C), size: 56),
                    const SizedBox(height: 16),
                    Text(screenName, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(description,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (showNavigationLinks) ...[
                const SizedBox(height: 24),
                _navButton(context, 'Start Scanning', Icons.qr_code_scanner,
                    RouteNames.scan),
                const SizedBox(height: 8),
                _navButton(context, 'Manual Search', Icons.search,
                    RouteNames.manualSearch),
                const SizedBox(height: 8),
                _navButton(context, 'Settings', Icons.settings_outlined,
                    RouteNames.settings),
              ],
              const SizedBox(height: 24),
              _DebugSection(screenName: screenName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(
      BuildContext context, String label, IconData icon, String route) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go(route),
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
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF6B6B6B), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugSection extends ConsumerWidget {
  const _DebugSection({required this.screenName});
  final String screenName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    if (!isDebug) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Color(0xFF2A2A2A)),
        const SizedBox(height: 12),
        const Text('DEBUG TOOLS',
            style: TextStyle(
                color: Color(0xFF6B6B6B), fontSize: 11, letterSpacing: 1.2),
            textAlign: TextAlign.center),
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
      ],
    );
  }
}

class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen({required this.uri, this.error});
  final String uri;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF3B30), size: 64),
              const SizedBox(height: 20),
              Text('Route Not Found',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('"$uri" does not exist.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.setup),
                child: const Text('Return to Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}