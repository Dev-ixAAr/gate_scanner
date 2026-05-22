// ============================================================================
// Error Banner — Inline error display widget
//
// Full implementation in Phase 5.
// Phase 1: Placeholder.
// ============================================================================

import 'package:flutter/material.dart';

/// Inline error message banner.
/// Placeholder — full implementation in Phase 5.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement in Phase 5
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.withAlpha(30),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}