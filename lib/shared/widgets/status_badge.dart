// ============================================================================
// Status Badge — Colored validation status indicator
//
// Full implementation in Phase 6/7.
// Phase 1: Placeholder.
// ============================================================================

import 'package:flutter/material.dart';

/// Colored status badge for validation results.
/// Placeholder — full implementation in Phase 6.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    // TODO: Map status to color in Phase 6
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}