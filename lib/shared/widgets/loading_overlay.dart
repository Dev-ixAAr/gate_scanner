// ============================================================================
// Loading Overlay — Full screen loading indicator
//
// Full implementation in Phase 5.
// Phase 1: Placeholder.
// ============================================================================

import 'package:flutter/material.dart';

/// Full screen semi-transparent loading overlay.
/// Placeholder — full implementation in Phase 5.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement in Phase 5
    return const Center(child: CircularProgressIndicator());
  }
}