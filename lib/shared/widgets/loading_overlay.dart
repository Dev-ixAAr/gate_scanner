// ============================================================================
// Loading Overlay — Full-screen and inline loading indicators
//
// Implemented now (Phase 2) because AppButton uses the inline spinner,
// and the full-screen overlay is needed in Phase 4+ for API calls.
//
// LoadingOverlay         → Full-screen overlay with spinner and message
// InlineLoader           → Small centered spinner for use inside widgets
// ButtonLoadingIndicator → Compact spinner matching button size
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// ============================================================================
// FULL-SCREEN LOADING OVERLAY
// ============================================================================

/// Full-screen semi-transparent overlay with a loading spinner.
///
/// Use this when an async operation blocks the entire screen
/// (e.g., setup token exchange, session logout).
///
/// Usage — wrap the overlay over existing content:
/// ```dart
/// Stack(
///   children: [
///     // Your screen content
///     MainContent(),
///     // Show overlay when loading
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
  /// If null, only the spinner is shown.
  final String? message;

  /// Color of the semi-transparent barrier behind the spinner.
  final Color barrierColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: barrierColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 28,
          ),
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

// ============================================================================
// INLINE LOADER — Small centered spinner
// ============================================================================

/// Small centered loading indicator for use within widget subtrees.
///
/// Use when a specific section of a screen is loading,
/// not the entire screen.
///
/// Example:
/// ```dart
/// if (isLoading) const InlineLoader()
/// else ResultWidget(data: data)
/// ```
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

// ============================================================================
// SCAN PROCESSING INDICATOR
// Used on ticket scan screen while awaiting API validation response.
// ============================================================================

/// Scan processing animation shown while validating a ticket QR code.
///
/// Shown as an overlay on the camera view between scan detection and
/// result display. Indicates to the operator that processing is in progress.
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