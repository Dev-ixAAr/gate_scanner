// ============================================================================
// Scanner Home Screen — Event dashboard for active sessions
//
// Full implementation in Phase 6.
// Phase 1: Placeholder widget.
// ============================================================================

import 'package:flutter/material.dart';

/// Main dashboard shown when a scanner session is active.
///
/// TODO: Implement full UI in Phase 6:
/// - Session status indicator
/// - Event name and reference
/// - Server URL
/// - Device name
/// - Session started timestamp
/// - "Start Scanning" button → /scan
/// - "Manual Search" button → /manual-search
/// - Settings icon → /settings
class ScannerHomeScreen extends StatelessWidget {
  const ScannerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with full implementation in Phase 6
    return const Scaffold(
      body: Center(
        child: Text(
          'ScannerHomeScreen\nPhase 6',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}