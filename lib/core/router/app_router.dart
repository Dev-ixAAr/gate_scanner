// ============================================================================
// App Router — Updated for Phase 6
//
// Changes from Phase 5:
// - /home route now uses ScannerHomeScreen (real implementation)
// - All other routes unchanged (/scan, /manual-search, /settings remain
//   as Phase 7/8/9 placeholders)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/storage_keys.dart';
import '../secure_storage/secure_storage_service.dart';
import 'route_names.dart';

// Phase 4 screens
import '../../features/setup/screens/welcome_setup_screen.dart';
import '../../features/setup/screens/setup_qr_scan_screen.dart';

// Phase 6 screen
import '../../features/home/screens/scanner_home_screen.dart';

part 'app_router.g.dart';

// ============================================================================
// ROUTER REFRESH NOTIFIER (unchanged)
// ============================================================================

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

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

    routes: [
      // ── Setup (Phase 4) ──────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.setup,
        name: 'setup',
        builder: (context, state) => const WelcomeSetupScreen(),
        routes: [
          GoRoute(
            path: 'scan',
            name: 'setup-scan',
            builder: (context, state) => const SetupQrScanScreen(),
          ),
        ],
      ),

      // ── Home (Phase 6 — real screen) ────────────────────────────────────
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        // ✅ Phase 6: Real screen
        builder: (context, state) => const ScannerHomeScreen(),
      ),

      // ── Scan (Phase 7 placeholder) ───────────────────────────────────────
      GoRoute(
        path: RouteNames.scan,
        name: 'scan',
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'TicketScanScreen',
          phase: 'Phase 7',
          icon: Icons.qr_code_2,
          description: 'Full-screen camera for scanning attendee ticket QR codes.',
        ),
      ),

      // ── Manual Search (Phase 8 placeholder) ─────────────────────────────
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

      // ── Settings (Phase 9 placeholder) ──────────────────────────────────
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const _PlaceholderScreen(
          screenName: 'SessionSettingsScreen',
          phase: 'Phase 9',
          icon: Icons.settings_outlined,
          description: 'Device info, session info, logout, reset, switch event.',
        ),
      ),
    ],

    errorBuilder: (context, state) => _RouterErrorScreen(
      uri: state.uri.toString(),
      error: state.error?.toString(),
    ),
  );
}

// ============================================================================
// PLACEHOLDER SCREEN (Phases 7-9)
// ============================================================================

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.screenName,
    required this.phase,
    required this.icon,
    required this.description,
  });

  final String screenName;
  final String phase;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(screenName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1A00D16C),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0x4000D16C)),
                ),
                child: Text(
                  'PLACEHOLDER — $phase',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF00D16C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.home),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF3B30), size: 64),
              const SizedBox(height: 20),
              Text('"$uri" does not exist.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
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