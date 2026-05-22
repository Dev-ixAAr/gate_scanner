// ============================================================================
// Status Badge — Colored validation status indicator widget
//
// Used in:
// - Scan result screens (Phase 7) to show ticket validation state
// - Manual search screen (Phase 8) to show ticket status in results
// - Session status indicators on home screen
//
// VARIANTS:
// StatusBadge              → colored dot + text label (inline)
// StatusBadge.pill         → rounded pill with background fill
// StatusBadge.icon         → icon + label
// StatusBadge.sessionDot   → small dot only (for AppBar/status indicators)
//
// SUPPORTED STATUS VALUES:
// These match the backend validation_status field values exactly.
// - 'valid'           → Green
// - 'already_used'    → Amber
// - 'revoked'         → Red
// - 'cancelled'       → Red
// - 'invalid'         → Red
// - 'wrong_event'     → Orange
//
// Additional session-specific statuses:
// - 'active'          → Green (scanner session active)
// - 'error'           → Red (scanner session error)
// - 'checking'        → Blue (verifying)
// - 'unknown'         → Gray
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// ============================================================================
// STATUS CONFIG — Maps status string to visual properties
// ============================================================================

/// Visual configuration for a single status value.
class _StatusConfig {
  const _StatusConfig({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;
}

/// Maps status string values to visual configuration.
_StatusConfig _configForStatus(String status) {
  switch (status.toLowerCase().trim()) {
    // ── Ticket validation statuses ──────────────────────────────────────────
    case 'valid':
      return const _StatusConfig(
        color: AppColors.statusValid,
        label: 'Valid',
        icon: Icons.check_circle_outline_rounded,
      );
    case 'already_used':
    case 'already_checked_in':
      return const _StatusConfig(
        color: AppColors.statusAlreadyUsed,
        label: 'Already Used',
        icon: Icons.warning_amber_rounded,
      );
    case 'revoked':
      return const _StatusConfig(
        color: AppColors.statusRevoked,
        label: 'Revoked',
        icon: Icons.remove_circle_outline_rounded,
      );
    case 'cancelled':
      return const _StatusConfig(
        color: AppColors.statusCancelled,
        label: 'Cancelled',
        icon: Icons.cancel_outlined,
      );
    case 'invalid':
      return const _StatusConfig(
        color: AppColors.statusInvalid,
        label: 'Invalid',
        icon: Icons.help_outline_rounded,
      );
    case 'wrong_event':
      return const _StatusConfig(
        color: AppColors.statusWrongEvent,
        label: 'Wrong Event',
        icon: Icons.location_off_outlined,
      );

    // ── Session health statuses ─────────────────────────────────────────────
    case 'active':
      return const _StatusConfig(
        color: AppColors.statusValid,
        label: 'Active',
        icon: Icons.check_circle_outline_rounded,
      );
    case 'error':
      return const _StatusConfig(
        color: AppColors.warning,
        label: 'Warning',
        icon: Icons.warning_amber_rounded,
      );
    case 'checking':
      return const _StatusConfig(
        color: AppColors.info,
        label: 'Checking',
        icon: Icons.sync_rounded,
      );
    case 'online':
      return const _StatusConfig(
        color: AppColors.statusValid,
        label: 'Online',
        icon: Icons.wifi_rounded,
      );
    case 'offline':
      return const _StatusConfig(
        color: AppColors.statusInvalid,
        label: 'Offline',
        icon: Icons.wifi_off_rounded,
      );

    // ── Ticket source types ─────────────────────────────────────────────────
    case 'online':
      return const _StatusConfig(
        color: AppColors.info,
        label: 'Online',
        icon: Icons.shopping_cart_outlined,
      );
    case 'physical':
      return const _StatusConfig(
        color: AppColors.textSecondary,
        label: 'Physical',
        icon: Icons.confirmation_number_outlined,
      );
    case 'complimentary':
      return const _StatusConfig(
        color: AppColors.brandPrimary,
        label: 'Complimentary',
        icon: Icons.card_giftcard_outlined,
      );

    // ── Default / unknown ───────────────────────────────────────────────────
    default:
      return _StatusConfig(
        color: AppColors.textTertiary,
        label: status.isEmpty ? 'Unknown' : status,
        icon: Icons.circle_outlined,
      );
  }
}

// ============================================================================
// STATUS BADGE WIDGET
// ============================================================================

/// Inline status indicator: colored dot + text label.
///
/// Used in list items and info rows where space is limited.
///
/// Example:
/// ```dart
/// StatusBadge(status: 'valid')
/// StatusBadge(status: 'already_used')
/// StatusBadge(status: 'revoked', showDot: true)
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
    this.showLabel = true,
    this.dotSize = 8.0,
    this.fontSize = 13.0,
    this.fontWeight = FontWeight.w600,
    this.customLabel,
  });

  /// The validation or session status string.
  /// Must match one of the supported status values.
  final String status;

  /// Whether to show the colored dot indicator.
  final bool showDot;

  /// Whether to show the text label.
  final bool showLabel;

  /// Size of the dot in logical pixels.
  final double dotSize;

  /// Font size of the label text.
  final double fontSize;

  /// Font weight of the label text.
  final FontWeight fontWeight;

  /// Override the auto-generated label text.
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.color,
              boxShadow: [
                BoxShadow(
                  color: config.color.withAlpha(80),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (showLabel) const SizedBox(width: 6),
        ],
        if (showLabel)
          Text(
            customLabel ?? config.label,
            style: TextStyle(
              color: config.color,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// STATUS PILL — Rounded pill with colored background
// ============================================================================

/// Rounded pill badge with colored background for prominent status display.
///
/// Used on scan result screens and list items that need more visual weight.
///
/// Example:
/// ```dart
/// StatusPill(status: 'valid')      // Full green pill
/// StatusPill(status: 'revoked')    // Full red pill
/// StatusPill(                      // Custom size
///   status: 'already_used',
///   fontSize: 11,
///   verticalPadding: 4,
/// )
/// ```
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12.0,
    this.horizontalPadding = 12.0,
    this.verticalPadding = 6.0,
    this.customLabel,
    this.iconSize = 14.0,
  });

  final String status;
  final bool showIcon;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final String? customLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: config.color.withAlpha(30),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: config.color.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(config.icon, color: config.color, size: iconSize),
            const SizedBox(width: 5),
          ],
          Text(
            customLabel ?? config.label.toUpperCase(),
            style: TextStyle(
              color: config.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS DOT — Minimal dot only (no label)
// ============================================================================

/// A minimal colored dot for use in dense UI (AppBars, list row indicators).
///
/// Example:
/// ```dart
/// StatusDot(status: 'active', size: 10)
/// StatusDot(status: 'error', size: 8)
/// ```
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.status,
    this.size = 10.0,
    this.withGlow = true,
  });

  final String status;
  final double size;

  /// Whether to add a soft glow shadow to make the dot more visible.
  final bool withGlow;

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: config.color,
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: config.color.withAlpha(100),
                  blurRadius: size,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

// ============================================================================
// STATUS RESULT HEADER — Full-width colored header for scan result screens
// ============================================================================

/// Large full-width status header for scan result screens.
///
/// Shows a large icon, status label, and optional subtitle.
/// The background color fills the entire header area.
///
/// Used by ScanResultScreen (Phase 7) and ManualSearchScreen (Phase 8).
///
/// Example:
/// ```dart
/// StatusResultHeader(
///   status: 'valid',
///   title: 'VALID TICKET',
///   subtitle: 'Admit the holder',
/// )
/// ```
class StatusResultHeader extends StatelessWidget {
  const StatusResultHeader({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
  });

  final String status;
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: config.color.withAlpha(25),
        border: Border(
          bottom: BorderSide(
            color: config.color.withAlpha(80),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large status icon.
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.color.withAlpha(30),
              border: Border.all(color: config.color.withAlpha(80), width: 2),
            ),
            child: Icon(config.icon, color: config.color, size: 34),
          ),
          const SizedBox(height: 14),

          // Status title (e.g., "VALID TICKET").
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: config.color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),

          // Optional subtitle.
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}