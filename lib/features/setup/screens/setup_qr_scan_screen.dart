// ============================================================================
// Setup QR Scan Screen — Camera view for scanning admin setup QR
//
// Full implementation in Phase 4.
// Phase 1: Placeholder widget.
// ============================================================================

import 'package:flutter/material.dart';

/// Camera screen for scanning the admin setup QR code.
///
/// TODO: Implement full UI in Phase 4:
/// - Full screen mobile_scanner camera view
/// - QR scanner overlay widget
/// - Instruction text
/// - Torch toggle button
/// - QR parse + validate + bottom sheet preview
/// - Camera permission handling
class SetupQrScanScreen extends StatelessWidget {
  const SetupQrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with full implementation in Phase 4
    return const Scaffold(
      body: Center(
        child: Text(
          'SetupQrScanScreen\nPhase 4',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}