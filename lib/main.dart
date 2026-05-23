// ============================================================================
// gate_scanner — Application Entry Point
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/security/device_integrity_service.dart';
import 'core/theme/app_theme.dart';

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

class GateScannerApp extends ConsumerStatefulWidget {
  const GateScannerApp({super.key});

  @override
  ConsumerState<GateScannerApp> createState() => _GateScannerAppState();
}

class _GateScannerAppState extends ConsumerState<GateScannerApp> {
  bool _integrityWarningShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDeviceIntegrity());
  }

  Future<void> _checkDeviceIntegrity() async {
    final compromised =
        await ref.read(deviceIntegrityServiceProvider).isDeviceCompromised();
    if (!compromised || _integrityWarningShown || !mounted) return;

    _integrityWarningShown = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Warning'),
        content: const Text(
          'This device appears to be rooted or in developer mode. '
          'Using Gate Scanner on a compromised device may expose session '
          'credentials and attendee data. Continue only if you accept this risk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
