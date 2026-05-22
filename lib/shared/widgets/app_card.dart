// ============================================================================
// App Card — Reusable card widget
//
// Full implementation in Phase 2.
// Phase 1: Placeholder.
// ============================================================================

import 'package:flutter/material.dart';

/// Reusable card widget with consistent styling.
/// Placeholder — full implementation in Phase 2.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: child);
  }
}