// ============================================================================
// Scan Result Screen — Validation result display overlay
//
// Implemented as a modal bottom sheet shown over the camera view.
// Full implementation in Phase 7.
// Phase 1: Placeholder widget.
// ============================================================================

import 'package:flutter/material.dart';

/// Displays the ticket validation result as a modal bottom sheet.
///
/// TODO: Implement in Phase 7 with all validation state variants:
/// - Valid (green, full holder info)
/// - Already Used (amber, previous check-in info)
/// - Wrong Event (orange, block entry message)
/// - Revoked/Cancelled (red, deny entry)
/// - Invalid (red, not recognized)
class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'ScanResultScreen\nPhase 7',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}