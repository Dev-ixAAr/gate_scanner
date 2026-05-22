// ============================================================================
// Loading Overlay — Full-screen and inline loading indicators
//
// CONFIRMED COMPLETE from Phase 2. No changes in Phase 6.
// Re-emitted here for completeness.
//
// Widgets available:
// - LoadingOverlay          → full-screen semi-transparent overlay
// - InlineLoader            → small centered spinner for widget subtrees
// - ScanProcessingIndicator → overlay shown during ticket validation
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Full-screen semi-transparent overlay with a loading spinner.
///
/// Use when an async operation blocks the entire screen.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     MainContent(),
///     if (isLoading) const LoadingOverlay(message: 'Connecting...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
    this.barrierColor = AppColors.backgroundOverlay,
  });

  /// Optional message displayed below the spinner.
  final String? message;

  /// Color of the semi-transparent barrier.
  final Color barrierColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: barrierColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderPrimary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.brandPrimary,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small centered loading indicator for use within widget subtrees.
class InlineLoader extends StatelessWidget {
  const InlineLoader({
    super.key,
    this.size = 24,
    this.color = AppColors.brandPrimary,
    this.padding = const EdgeInsets.all(24),
  });

  final double size;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}

/// Scan processing indicator shown while validating a ticket QR code.
///
/// Shown as an overlay on the camera view between scan detection
/// and result display.
class ScanProcessingIndicator extends StatelessWidget {
  const ScanProcessingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundOverlay,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brandPrimaryBorder),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.brandPrimary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Validating ticket...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}