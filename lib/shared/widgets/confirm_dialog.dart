// ============================================================================
// Confirm Dialog — Reusable confirmation dialog widget
//
// Used for all destructive or significant actions in the app:
// - Logout scanner session (settings)
// - Reset event binding (settings)
// - Switch event (settings)
//
// USAGE:
// ```dart
// final bool? confirmed = await ConfirmDialog.show(
//   context: context,
//   title: 'Logout Session',
//   message: 'This will end your scanner session on the server.',
//   confirmLabel: 'Logout',
//   isDestructive: true,
// );
// if (confirmed == true) {
//   // perform action
// }
// ```
//
// VARIANTS:
// - isDestructive: true  → confirm button is red (for permanent/risky actions)
// - isDestructive: false → confirm button uses brand primary color
//
// RETURN VALUE:
// - true:  user tapped the confirm button
// - false: user tapped the cancel button
// - null:  user dismissed the dialog by tapping outside (treated as cancel)
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Reusable confirmation dialog for significant or destructive actions.
///
/// Use [ConfirmDialog.show] to display the dialog and await the result.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog._({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    this.icon,
    this.additionalContent,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  /// Optional widget shown between the message and the action buttons.
  /// Use for warning cards or additional context.
  final Widget? additionalContent;

  // ==========================================================================
  // STATIC SHOW METHOD
  // ==========================================================================

  /// Displays the confirmation dialog and returns the user's choice.
  ///
  /// Returns:
  /// - `true`  when the user taps [confirmLabel]
  /// - `false` when the user taps [cancelLabel]
  /// - `null`  when the user dismisses the dialog (barrier tap / back button)
  ///
  /// Parameters:
  /// - [title]: Dialog title (e.g., 'Logout Session')
  /// - [message]: Explanation of what will happen (e.g., 'This will end...')
  /// - [confirmLabel]: Confirm button text (e.g., 'Logout', 'Reset', 'Switch')
  /// - [cancelLabel]: Cancel button text (default: 'Cancel')
  /// - [isDestructive]: When true, confirm button is red (default: false)
  /// - [icon]: Optional icon shown in the dialog header
  /// - [additionalContent]: Optional widget for extra context
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
    Widget? additionalContent,
  }) {
    return showDialog<bool>(
      context: context,
      // Prevent dismissal by tapping outside for destructive actions.
      barrierDismissible: !isDestructive,
      builder: (dialogContext) => ConfirmDialog._(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
        additionalContent: additionalContent,
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final Color confirmColor =
        isDestructive ? AppColors.error : AppColors.brandPrimary;
    final Color confirmTextColor =
        isDestructive ? AppColors.textPrimary : AppColors.textInverse;

    return AlertDialog(
      backgroundColor: AppColors.backgroundTertiary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDestructive
              ? AppColors.errorBorder
              : AppColors.borderPrimary,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.brandPrimary,
              size: 22,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (additionalContent != null) ...[
            const SizedBox(height: 16),
            additionalContent!,
          ],
        ],
      ),
      actions: [
        // Cancel button — always secondary/outlined style.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(
            cancelLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),

        // Confirm button — red for destructive, green for non-destructive.
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: confirmTextColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}