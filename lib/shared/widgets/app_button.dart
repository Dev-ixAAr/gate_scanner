// ============================================================================
// App Button — Reusable button widget
//
// Full implementation in Phase 2.
// Phase 1: Placeholder.
// ============================================================================

import 'package:flutter/material.dart';

// TODO: Implement reusable button variants in Phase 2:
// - AppButton.primary(...)  → green filled
// - AppButton.secondary(...) → outlined
// - AppButton.danger(...)   → red filled
// - Loading state with spinner

/// Reusable button widget for gate scanner app.
/// Placeholder — full implementation in Phase 2.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}