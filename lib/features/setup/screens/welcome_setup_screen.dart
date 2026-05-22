// ============================================================================
// Welcome Setup Screen — Initial screen for unconfigured devices
//
// Shown when no active scanner session exists.
// Guides the user to scan the admin setup QR code.
//
// Full implementation in Phase 4.
// Phase 1: Placeholder widget.
// ============================================================================

import 'package:flutter/material.dart';

/// Welcome/setup screen shown to unconfigured scanners.
///
/// TODO: Implement full UI in Phase 4:
/// - App logo centered
/// - "Gate Scanner" title
/// - Setup instructions
/// - "Scan Setup QR" button → navigate to setup scan screen
/// - App version at bottom
class WelcomeSetupScreen extends StatelessWidget {
  const WelcomeSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with full implementation in Phase 4
    return const Scaffold(
      body: Center(
        child: Text(
          'WelcomeSetupScreen\nPhase 4',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}