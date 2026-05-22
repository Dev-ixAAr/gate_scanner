// ============================================================================
// App Button — Reusable button widget with variants
//
// Provides four button variants for consistent UI across the app:
//
// AppButton.primary   → Brand green filled — primary CTAs
//                       Example: "Start Scanning", "Confirm Check-in"
//
// AppButton.secondary → Outlined brand green — secondary actions
//                       Example: "Manual Search", "Cancel"
//
// AppButton.danger    → Red filled — destructive actions
//                       Example: "Reset Event Binding", "Logout"
//
// AppButton.ghost     → Transparent with text — low-emphasis actions
//                       Example: "Skip", "Learn more"
//
// All variants support:
// - Loading state (shows spinner, disables interaction)
// - Disabled state
// - Leading icon (optional)
// - Full-width or shrink-to-fit sizing
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// ============================================================================
// BUTTON VARIANT ENUM
// ============================================================================

enum _AppButtonVariant { primary, secondary, danger, ghost }

// ============================================================================
// MAIN WIDGET
// ============================================================================

/// Reusable button widget for gate_scanner.
///
/// Use the named constructors for the appropriate variant:
/// ```dart
/// AppButton.primary(label: 'Start Scanning', onPressed: _onScan)
/// AppButton.secondary(label: 'Cancel', onPressed: _onCancel)
/// AppButton.danger(label: 'Reset', onPressed: _onReset)
/// AppButton.ghost(label: 'Skip', onPressed: _onSkip)
/// ```
class AppButton extends StatelessWidget {
  // Private constructor — use named constructors below.
  const AppButton._({
    required this.label,
    required this.variant,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.isFullWidth = true,
    super.key,
  });

  // ==========================================================================
  // NAMED CONSTRUCTORS
  // ==========================================================================

  /// Primary button — brand green filled.
  /// Use for the single most important action on a screen.
  ///
  /// Example:
  /// ```dart
  /// AppButton.primary(
  ///   label: 'Start Scanning',
  ///   onPressed: () => context.go(RouteNames.scan),
  ///   leadingIcon: Icons.qr_code_scanner,
  /// )
  /// ```
  const AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    bool isFullWidth = true,
    Key? key,
  }) : this._(
          label: label,
          variant: _AppButtonVariant.primary,
          onPressed: onPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          isFullWidth: isFullWidth,
          key: key,
        );

  /// Secondary button — outlined brand green.
  /// Use for secondary/alternative actions alongside a primary button.
  ///
  /// Example:
  /// ```dart
  /// AppButton.secondary(
  ///   label: 'Manual Search',
  ///   onPressed: () => context.go(RouteNames.manualSearch),
  ///   leadingIcon: Icons.search,
  /// )
  /// ```
  const AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    bool isFullWidth = true,
    Key? key,
  }) : this._(
          label: label,
          variant: _AppButtonVariant.secondary,
          onPressed: onPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          isFullWidth: isFullWidth,
          key: key,
        );

  /// Danger button — red filled.
  /// Use for destructive or irreversible actions.
  /// Always pair with a confirmation dialog before executing.
  ///
  /// Example:
  /// ```dart
  /// AppButton.danger(
  ///   label: 'Reset Event Binding',
  ///   onPressed: _onResetConfirmed,
  ///   leadingIcon: Icons.delete_outline,
  /// )
  /// ```
  const AppButton.danger({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    bool isFullWidth = true,
    Key? key,
  }) : this._(
          label: label,
          variant: _AppButtonVariant.danger,
          onPressed: onPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          isFullWidth: isFullWidth,
          key: key,
        );

  /// Ghost button — transparent background, brand green text.
  /// Use for low-emphasis inline actions.
  ///
  /// Example:
  /// ```dart
  /// AppButton.ghost(
  ///   label: 'View device info',
  ///   onPressed: _showDeviceInfo,
  /// )
  /// ```
  const AppButton.ghost({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    bool isFullWidth = false, // Ghost buttons are typically not full-width
    Key? key,
  }) : this._(
          label: label,
          variant: _AppButtonVariant.ghost,
          onPressed: onPressed,
          isLoading: isLoading,
          leadingIcon: leadingIcon,
          isFullWidth: isFullWidth,
          key: key,
        );

  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  final String label;
  final _AppButtonVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final bool isFullWidth;

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    // Disable the button while loading.
    final bool isDisabled = onPressed == null || isLoading;

    Widget buttonWidget;

    switch (variant) {
      case _AppButtonVariant.primary:
        buttonWidget = _buildElevatedButton(isDisabled);
      case _AppButtonVariant.secondary:
        buttonWidget = _buildOutlinedButton(isDisabled);
      case _AppButtonVariant.danger:
        buttonWidget = _buildDangerButton(isDisabled);
      case _AppButtonVariant.ghost:
        buttonWidget = _buildGhostButton(isDisabled);
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }
    return buttonWidget;
  }

  // ==========================================================================
  // PRIVATE BUILDERS — One per variant
  // ==========================================================================

  Widget _buildElevatedButton(bool isDisabled) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      child: _buildButtonContent(
        textColor: isDisabled ? AppColors.textDisabled : AppColors.textInverse,
        spinnerColor: AppColors.textInverse,
      ),
    );
  }

  Widget _buildOutlinedButton(bool isDisabled) {
    return OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      child: _buildButtonContent(
        textColor: isDisabled ? AppColors.textDisabled : AppColors.brandPrimary,
        spinnerColor: AppColors.brandPrimary,
      ),
    );
  }

  Widget _buildDangerButton(bool isDisabled) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppColors.backgroundTertiary : AppColors.error,
        foregroundColor: isDisabled ? AppColors.textDisabled : AppColors.textPrimary,
        overlayColor: Colors.white.withAlpha(20),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(88, 52),
      ),
      child: _buildButtonContent(
        textColor: isDisabled ? AppColors.textDisabled : AppColors.textPrimary,
        spinnerColor: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildGhostButton(bool isDisabled) {
    return TextButton(
      onPressed: isDisabled ? null : onPressed,
      child: _buildButtonContent(
        textColor: isDisabled ? AppColors.textDisabled : AppColors.brandPrimary,
        spinnerColor: AppColors.brandPrimary,
      ),
    );
  }

  /// Builds the button's inner content: spinner OR (icon + label).
  Widget _buildButtonContent({
    required Color textColor,
    required Color spinnerColor,
  }) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    }

    if (leadingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(leadingIcon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor)),
        ],
      );
    }

    return Text(label, style: TextStyle(color: textColor));
  }
}