// ============================================================================
// gate_scanner — Application Entry Point
//
// Phase 5 update:
// - Adds global navigatorKey for use by SessionRevokeInterceptor
// - The interceptor needs to show SnackBars and navigate without BuildContext
// - navigatorKey is declared here and passed to the interceptor via its
//   provider constructor
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Global navigator key used by non-widget code to access the navigator.
///
/// Primary use case: [SessionRevokeInterceptor] needs to show a SnackBar
/// and navigate to /setup after detecting a 401 response. Since interceptors
/// run outside the widget tree, they cannot use BuildContext navigation.
///
/// This key is passed to:
/// - [MaterialApp.router] via navigatorKey parameter — not possible with
///   MaterialApp.router (GoRouter manages its own navigator).
/// - [SessionRevokeInterceptor] directly via its provider.
///
/// USAGE IN INTERCEPTOR:
/// ```dart
/// final context = navigatorKey.currentContext;
/// if (context != null && context.mounted) {
///   ScaffoldMessenger.of(context).showSnackBar(...);
/// }
/// ```
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF080808),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: GateScannerApp(),
    ),
  );
}

/// Root application widget.
///
/// Watches [appRouterProvider] so that when the router provider is refreshed
/// (e.g., after session changes), the MaterialApp.router receives the updated
/// router configuration.
class GateScannerApp extends ConsumerWidget {
  const GateScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Gate Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}