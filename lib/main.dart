// ============================================================================
// gate_scanner — Application Entry Point
//
// Phase 2 update:
// - Uses full AppTheme.darkTheme (not just basic dark theme)
// - Watches appRouterProvider via ConsumerWidget for reactive routing
// - Handles router refresh for session-based redirects
// - Portrait lock and system UI overlay configured
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
///
/// Responsibilities:
/// 1. Initialize Flutter binding (required before async operations)
/// 2. Lock orientation to portrait
/// 3. Configure system UI overlay style
/// 4. Wrap app in ProviderScope (Riverpod root)
void main() async {
  // Must be called before any Flutter framework operations.
  // Required when main() is async or uses plugins before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only.
  // Gate scanner apps are always used in portrait mode at entrances.
  // This prevents accidental landscape mode that would break the camera UI.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure the system UI (status bar and navigation bar) appearance.
  // Must be set here before the app renders for consistent startup appearance.
  // Individual screens can override this with SystemChrome.setSystemUIOverlayStyle().
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Transparent status bar — app content extends behind it.
      statusBarColor: Colors.transparent,
      // Light icons (white) — readable on the dark theme background.
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // iOS status bar brightness
      // Navigation bar matches app background.
      systemNavigationBarColor: Color(0xFF080808),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Run the application.
  // ProviderScope is the root of all Riverpod state management.
  // It must be the outermost widget — all providers are accessible within.
  runApp(
    const ProviderScope(
      child: GateScannerApp(),
    ),
  );
}

/// Root application widget.
///
/// Uses [ConsumerWidget] to watch the [appRouterProvider].
/// The router is watched (not read) so that when the router provider
/// is rebuilt (e.g., after session changes), the MaterialApp.router
/// receives the updated router configuration.
///
/// The router internally uses [routerRefreshNotifierProvider] to trigger
/// redirect guard re-evaluation without rebuilding the entire widget tree.
class GateScannerApp extends ConsumerWidget {
  const GateScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider.
    // This rebuilds GateScannerApp if the router itself changes.
    // The router's redirect guard re-runs automatically when
    // routerRefreshNotifierProvider.refresh() is called.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // Application title — shown in:
      // - Android task switcher (recent apps)
      // - Accessibility tools (screen readers)
      // - Window title on desktop platforms
      title: 'Gate Scanner',

      // Remove the debug banner in all builds.
      // Even in debug builds, the banner looks unprofessional for a
      // production-oriented gate scanner app.
      debugShowCheckedModeBanner: false,

      // Apply the scanner app's dark theme.
      // This is the ONLY theme — no light mode support.
      // Dark mode is universally appropriate for scanning environments.
      theme: AppTheme.darkTheme,

      // Force dark mode regardless of system settings.
      // The operator's phone brightness or system preference must not
      // affect the scanner app's appearance.
      themeMode: ThemeMode.dark,

      // GoRouter provides both routerDelegate and routeInformationParser.
      // Using routerConfig is the recommended approach with go_router.
      routerConfig: router,
    );
  }
}