import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/screen_security_service.dart';

/// Wraps sensitive screens to block screenshots in release builds.
class SecureScreenWrapper extends ConsumerStatefulWidget {
  const SecureScreenWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SecureScreenWrapper> createState() =>
      _SecureScreenWrapperState();
}

class _SecureScreenWrapperState extends ConsumerState<SecureScreenWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenSecurityServiceProvider).enableProtection();
    });
  }

  @override
  void dispose() {
    ref.read(screenSecurityServiceProvider).disableProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
