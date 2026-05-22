// ============================================================================
// App Router — Final implementation (Phase 9)
//
// ALL routes now point to real screens:
// - /setup          → WelcomeSetupScreen        (Phase 4)
// - /setup/scan     → SetupQrScanScreen          (Phase 4)
// - /home           → ScannerHomeScreen          (Phase 6)
// - /scan           → TicketScanScreen           (Phase 7)
// - /manual-search  → ManualSearchScreen         (Phase 8)
// - /settings       → SessionSettingsScreen      (Phase 9) ✅ NEW
//
// No more placeholder screens. The gate scanner app is fully implemented.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/storage_keys.dart';
import '../secure_storage/secure_storage_service.dart';
import 'route_names.dart';

// Phase 4
import '../../features/setup/screens/welcome_setup_screen.dart';
import '../../features/setup/screens/setup_qr_scan_screen.dart';
import '../../features/setup/screens/setup_manual_screen.dart';
// Phase 6
import '../../features/home/screens/scanner_home_screen.dart';
// Phase 7
import '../../features/scanner/screens/ticket_scan_screen.dart';
// Phase 8
import '../../features/manual_search/screens/manual_search_screen.dart';
// Phase 9
import '../../features/settings/screens/session_settings_screen.dart';

part 'app_router.g.dart';

// ============================================================================
// ROUTER REFRESH NOTIFIER
// ============================================================================

/// Triggers GoRouter to re-run redirect guards.
///
/// Called by:
/// - [SetupExchangeNotifier]: after successful session save → redirect to /home
/// - [SettingsNotifier]: after logout/reset/switch → redirect to /setup
/// - [SessionRevokeInterceptor]: after 401 detected → redirect to /setup
///
/// The router listens to this via [refreshListenable].
class RouterRefreshNotifier extends ChangeNotifier {
  /// Triggers GoRouter to re-evaluate all redirect guards.
  void refresh() => notifyListeners();
}

/// Global provider for [RouterRefreshNotifier].
///
/// Accessible throughout the app:
/// ```dart
/// final notifier = ref.read(routerRefreshNotifierProvider);
/// notifier.refresh();
/// ```
final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ============================================================================
// APP ROUTER PROVIDER
// ============================================================================

/// Provides the configured [GoRouter] instance.
///
/// The router:
/// - Listens to [routerRefreshNotifierProvider] for session state changes
/// - Re-runs the redirect guard on every navigation attempt
/// - Guards all non-setup routes: requires active session token
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final storage = ref.read(secureStorageServiceProvider);
  final refreshNotifier = ref.read(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.setup,

    // Refresh when routerRefreshNotifier fires.
    // This causes the redirect guard to re-run.
    refreshListenable: refreshNotifier,

    // Debug logging — set to false for production release builds.
    debugLogDiagnostics: true,

    // =========================================================================
    // SESSION GUARD
    //
    // Runs on every navigation attempt.
    // Reads session token from secure storage (single source of truth).
    //
    // Rules:
    // - No token + not on setup route → /setup
    // - Token exists + on setup route → /home (already configured)
    // - All other cases → allow navigation
    // =========================================================================
    redirect: (BuildContext context, GoRouterState state) async {
      final String? sessionToken =
          await storage.read(key: StorageKeys.sessionToken);
      final bool hasActiveSession =
          sessionToken != null && sessionToken.trim().isNotEmpty;

      final String currentLocation = state.matchedLocation;
      final bool isSetupRoute = currentLocation == RouteNames.setup ||
          currentLocation == RouteNames.setupScan ||
          currentLocation == RouteNames.setupManual;

      // No session → force to setup.
      if (!hasActiveSession && !isSetupRoute) {
        return RouteNames.setup;
      }

      // Has session + on setup → redirect to home.
      if (hasActiveSession && isSetupRoute) {
        return RouteNames.home;
      }

      // Allow navigation.
      return null;
    },

    // =========================================================================
    // ROUTES — All fully implemented
    // =========================================================================
    routes: [
      // ── SETUP FLOW ──────────────────────────────────────────────────────
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
          GoRoute(
            path: 'manual',
            name: 'setup-manual',
            builder: (context, state) => const SetupManualScreen(),
          ),
        ],
      ),

      // ── HOME ────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const ScannerHomeScreen(),
      ),

      // ── TICKET SCAN ─────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.scan,
        name: 'scan',
        builder: (context, state) => const TicketScanScreen(),
      ),

      // ── MANUAL SEARCH ───────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.manualSearch,
        name: 'manual-search',
        builder: (context, state) => const ManualSearchScreen(),
      ),

      // ── SETTINGS ────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        // ✅ Phase 9: Real screen — final route replacement
        builder: (context, state) => const SessionSettingsScreen(),
      ),
    ],

    // =========================================================================
    // ERROR HANDLER
    // =========================================================================
    errorBuilder: (context, state) {
      return Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141414),
          title: const Text('Navigation Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF3B30),
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Page Not Found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${state.uri}" does not exist in this app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 14,
                  ),
                ),
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
    },
  );
}