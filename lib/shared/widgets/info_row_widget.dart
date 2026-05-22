// ============================================================================
// Info Row Widget — Label + Value display row
//
// The primary widget for displaying structured key-value information
// throughout the app:
// - Home screen cards (event name, server, device, session time)
// - Settings screen (device info, session info)
// - Scan result screen (holder name, ticket ref, order ref)
// - Manual search results
//
// VARIANTS:
// InfoRowWidget           → standard label + value row
// InfoRowWidget.compact   → smaller font, tighter padding
// InfoRowWidget.prominent → larger value text for important fields
//
// FEATURES:
// - Optional leading icon
// - Optional trailing widget
// - Optional copy-to-clipboard on value tap
// - Optional value color override
// - Monospace font option for codes and references
// - Bottom divider (except for last row in a group)
// - Optional value truncation with tooltip
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// A label + value information display row.
///
/// Used extensively throughout the app for structured data display.
/// Supports icons, copy-to-clipboard, trailing widgets, and styling variants.
///
/// Example:
/// ```dart
/// InfoRowWidget(
///   label: 'Holder Name',
///   value: 'John Smith',
///   icon: Icons.person_outline,
///   isLast: false,
/// )
///
/// InfoRowWidget(
///   label: 'Ticket Reference',
///   value: 'TKT-2024-00123',
///   monospace: true,
///   valueCopyable: true,
///   isLast: true,
/// )
/// ```
class InfoRowWidget extends StatelessWidget {
  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.isLast = false,
    this.valueCopyable = false,
    this.monospace = false,
    this.valueColor,
    this.labelWidth = 110.0,
    this.verticalPadding = 12.0,
    this.labelStyle,
    this.valueStyle,
    this.maxValueLines,
    this.onTap,
  });

  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// The label/key text (left side).
  ///
  /// Examples: 'Holder Name', 'Server', 'Session Started'
  final String label;

  /// The value text (right side).
  ///
  /// Examples: 'John Smith', 'events.company.com', '8:30 AM'
  final String value;

  /// Optional leading icon displayed before the label.
  ///
  /// Use semantic icons that match the data type:
  /// - Icons.person_outline → person/name
  /// - Icons.confirmation_number_outlined → ticket reference
  /// - Icons.event_outlined → event
  /// - Icons.dns_outlined → server URL
  final IconData? icon;

  /// Optional widget displayed at the trailing end of the row.
  ///
  /// Examples: StatusPill, a copy icon button, an action button.
  final Widget? trailing;

  /// When true, no bottom divider is drawn.
  ///
  /// Set to true for the last row in a card section.
  final bool isLast;

  /// When true, tapping the value copies it to the clipboard.
  ///
  /// Shows a small clipboard icon next to the value.
  /// Good for ticket references, server URLs, and other copyable data.
  final bool valueCopyable;

  /// When true, renders the value in a monospace font.
  ///
  /// Use for codes, references, tokens, and technical identifiers.
  final bool monospace;

  /// Override color for the value text.
  ///
  /// Use [AppColors] constants for semantic meaning.
  final Color? valueColor;

  /// Width of the label column in logical pixels.
  ///
  /// Adjust if labels are longer than typical to prevent wrapping.
  final double labelWidth;

  /// Vertical padding around the row content.
  final double verticalPadding;

  /// Custom text style for the label. Overrides the default style.
  final TextStyle? labelStyle;

  /// Custom text style for the value. Overrides the default style.
  final TextStyle? valueStyle;

  /// Maximum number of lines for the value text.
  ///
  /// Null (default): no limit — value wraps naturally.
  /// 1: single line with ellipsis.
  final int? maxValueLines;

  /// Optional tap handler for the entire row.
  ///
  /// If [valueCopyable] is true, tapping copies the value.
  /// [onTap] fires in addition to the copy action.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget rowContent = Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Leading icon ───────────────────────────────────────────────
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                icon,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── Label column ───────────────────────────────────────────────
          SizedBox(
            width: icon != null ? labelWidth - 24 : labelWidth,
            child: Text(
              label,
              style: labelStyle ??
                  const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
            ),
          ),

          // ── Value ──────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: maxValueLines,
                    overflow: maxValueLines != null
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    style: valueStyle ??
                        TextStyle(
                          color: valueColor ?? AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          fontFamily: monospace ? 'monospace' : null,
                          letterSpacing: monospace ? 0.3 : null,
                        ),
                  ),
                ),

                // Copy icon (shown when valueCopyable = true).
                if (valueCopyable) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Trailing widget ────────────────────────────────────────────
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    // Wrap in InkWell if tappable.
    final Widget tappable = (valueCopyable || onTap != null)
        ? InkWell(
            onTap: valueCopyable
                ? () {
                    _copyToClipboard(context, value);
                    onTap?.call();
                  }
                : onTap,
            borderRadius: BorderRadius.circular(4),
            child: rowContent,
          )
        : rowContent;

    // Add bottom divider unless this is the last row.
    if (isLast) return tappable;

    return Column(
      children: [
        tappable,
        const Divider(
          color: AppColors.borderSecondary,
          height: 1,
          thickness: 1,
        ),
      ],
    );
  }

  /// Copies [text] to the system clipboard and shows a SnackBar confirmation.
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.brandPrimary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Copied: ${text.length > 40 ? '${text.substring(0, 40)}...' : text}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.backgroundTertiary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.borderPrimary),
            ),
            showCloseIcon: false,
          ),
        );
    }
  }
}

// ============================================================================
// COMPACT INFO ROW — Smaller, tighter variant
// ============================================================================

/// Compact variant of [InfoRowWidget] for dense UI sections.
///
/// Uses smaller fonts and tighter padding than the standard row.
/// Use in settings screens and secondary info sections.
///
/// Example:
/// ```dart
/// CompactInfoRow(label: 'OS Version', value: 'Android 13')
/// CompactInfoRow(label: 'App Version', value: 'v1.0.0')
/// ```
class CompactInfoRow extends StatelessWidget {
  const CompactInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isLast = false,
    this.valueColor,
    this.monospace = false,
    this.icon,
  });

  final String label;
  final String value;
  final bool isLast;
  final Color? valueColor;
  final bool monospace;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InfoRowWidget(
      label: label,
      value: value,
      icon: icon,
      isLast: isLast,
      valueColor: valueColor,
      monospace: monospace,
      labelWidth: 100,
      verticalPadding: 8,
      labelStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      valueStyle: TextStyle(
        color: valueColor ?? AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: monospace ? 'monospace' : null,
      ),
    );
  }
}

// ============================================================================
// PROMINENT INFO ROW — Larger value for important fields
// ============================================================================

/// Prominent variant with a larger value text for critical information.
///
/// Use for the holder name on valid scan results, or the event name.
///
/// Example:
/// ```dart
/// ProminentInfoRow(
///   label: 'Holder',
///   value: 'John Smith',
///   valueColor: AppColors.statusValid,
/// )
/// ```
class ProminentInfoRow extends StatelessWidget {
  const ProminentInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isLast = false,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final bool isLast;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InfoRowWidget(
      label: label,
      value: value,
      icon: icon,
      isLast: isLast,
      valueColor: valueColor,
      verticalPadding: 14,
      labelStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      valueStyle: TextStyle(
        color: valueColor ?? AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}