// ============================================================================
// gate_scanner — Application Entry Point
//
// This file bootstraps the Flutter application.
// Key responsibilities:
// - Initializes Flutter binding (required before any async setup)
// - Wraps the entire app in ProviderScope (Riverpod state management root)
// - References AppRouter for declarative navigation
// - Sets up the MaterialApp with theme configuration
//
// Phase 1: Basic structure with placeholders for theme and router.
// These will be fully implemented in Phase 2.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
///
/// [WidgetsFlutterBinding.ensureInitialized] must be called before any
/// plugin initialization or async operations in main().
///
/// [ProviderScope] is the Riverpod root — all providers are accessible
/// within this scope. It must wrap the entire widget tree.
void main() async {
  // Ensure Flutter binding is initialized before any plugin calls.
  // Required when main() is async or uses plugins before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait orientation only.
  // Gate scanners are used in portrait mode at event entrances.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set the system UI overlay style for the status bar.
  // Light icons on dark background to match the scanner app's dark theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Run the app wrapped in ProviderScope.
  // ProviderScope is the root of all Riverpod state management.
  // All providers declared throughout the app are accessible within this scope.
  runApp(
    const ProviderScope(
      child: GateScannerApp(),
    ),
  );
}

/// Root application widget.
///
/// Uses [ConsumerWidget] from Riverpod to access the router provider.
/// The router is a provider because it needs access to session state
/// for route guards (redirect unauthenticated users to setup screen).
class GateScannerApp extends ConsumerWidget {
  const GateScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider.
    // The router is refreshed when session state changes,
    // enabling automatic redirect to /setup on session revocation.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // App title shown in task switcher and accessibility tools.
      title: 'Gate Scanner',

      // Disable the debug banner in all builds for a clean professional look.
      debugShowCheckedModeBanner: false,

      // Apply the scanner app's dark theme.
      // Full theme implementation in Phase 2.
      theme: AppTheme.darkTheme,

      // Use the dark theme as the only theme (no light mode).
      // Scanner apps are used in various lighting conditions,
      // and dark mode is more appropriate for gate scanning contexts.
      themeMode: ThemeMode.dark,

      // GoRouter configuration.
      // routerConfig provides routerDelegate and routeInformationParser.
      routerConfig: router,
    );
  }
}