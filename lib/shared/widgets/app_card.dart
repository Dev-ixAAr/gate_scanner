// ============================================================================
// App Card — Reusable card widget with variants
//
// Provides consistent card styling across the app.
//
// AppCard             → Standard info card (dark background, subtle border)
// AppCard.highlighted → Accent card (green tint — used for event name display)
// AppCard.status      → Validation state card (color matches scan result)
// AppCard.section     → Section grouping card with title header
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// STANDARD INFO CARD
// ============================================================================

/// Standard dark-background card with subtle border.
///
/// Use for grouping related information on a screen.
///
/// Example:
/// ```dart
/// AppCard(
///   child: Column(
///     children: [
///       InfoRow(label: 'Server', value: session.serverUrl),
///       InfoRow(label: 'Device', value: session.deviceName),
///     ],
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? EdgeInsets.zero,
      decoration: AppTheme.infoCardDecoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

// ============================================================================
// HIGHLIGHTED CARD (Event Name, Active Status)
// ============================================================================

/// Card with a subtle brand green tint.
///
/// Use for the most important piece of information on a screen,
/// such as the event name on the home dashboard.
///
/// Example:
/// ```dart
/// AppCard.highlighted(
///   child: Column(
///     children: [
///       Text('Connected Event', style: ...),
///       Text('Summer Festival 2024', style: ...),
///     ],
///   ),
/// )
/// ```
class AppHighlightCard extends StatelessWidget {
  const AppHighlightCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? EdgeInsets.zero,
      decoration: AppTheme.highlightCardDecoration,
      child: child,
    );
  }
}

// ============================================================================
// STATUS CARD (Validation Result Colors)
// ============================================================================

/// Card with color-coded background matching a validation status.
///
/// Used on the scan result screen to visually communicate the result.
///
/// [status] should match one of the AppConstants.status* values.
///
/// Example:
/// ```dart
/// AppStatusCard(
///   status: 'valid',
///   child: Text('VALID TICKET'),
/// )
/// ```
class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    super.key,
    required this.status,
    required this.child,
    this.padding,
  });

  final String status;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceForValidationStatus(status),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderForValidationStatus(status),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

// ============================================================================
// SECTION CARD (Titled card group)
// ============================================================================

/// Card with a section title header above the content.
///
/// Used on settings and home screens to group related info rows.
///
/// Example:
/// ```dart
/// AppSectionCard(
///   title: 'SESSION INFO',
///   children: [
///     InfoRow(label: 'Event', value: 'Summer Festival'),
///     InfoRow(label: 'Started', value: '8:30 AM'),
///   ],
/// )
/// ```
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.titleTrailing,
    this.titleIcon,
    this.padding,
    this.highlighted = false,
  });

  final String title;
  final List<Widget> children;

  /// Optional widget placed at the end of the title row.
  /// Example: a small icon button.
  final Widget? titleTrailing;

  /// Optional icon shown before the section title.
  final IconData? titleIcon;
  final EdgeInsetsGeometry? padding;

  /// When true, uses brand-tinted card styling.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final decoration = highlighted
        ? AppTheme.highlightCardDecoration
        : AppTheme.infoCardDecoration;

    return Container(
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(
                    titleIcon,
                    size: 16,
                    color: highlighted
                        ? AppColors.brandPrimary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: highlighted
                          ? AppColors.brandPrimary
                          : AppColors.textTertiary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                if (titleTrailing != null) titleTrailing!,
              ],
            ),
          ),
          // Divider between title and content
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: AppColors.borderSecondary,
              height: 16,
            ),
          ),
          // Content
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW — Key/Value display row used inside cards
// ============================================================================

/// A label + value row for displaying structured information inside cards.
///
/// Used extensively on home screen, settings screen, and scan result screen.
///
/// Example:
/// ```dart
/// InfoRow(
///   label: 'Holder Name',
///   value: 'John Smith',
///   valueStyle: TextStyle(fontWeight: FontWeight.bold),
/// )
/// ```
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.trailing,
    this.isLast = false,
    this.valueCopyable = false,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  /// Optional widget at the end of the row (e.g., copy button, status badge).
  final Widget? trailing;

  /// When true, no bottom border is drawn (use for last item in a card).
  final bool isLast;

  /// When true, tapping the value copies it to clipboard.
  final bool valueCopyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: labelStyle ??
                  theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
          // Value
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          // Trailing (optional)
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (isLast) return rowContent;

    return Column(
      children: [
        rowContent,
        const Divider(
          color: AppColors.borderSecondary,
          height: 1,
          thickness: 1,
        ),
      ],
    );
  }
}