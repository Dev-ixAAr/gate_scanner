// ============================================================================
// App Colors — Color palette for gate_scanner
//
// Dark scanner-friendly theme optimized for:
// - Low-light gate/entrance environments
// - High contrast validation state feedback
// - Quick visual parsing of scan results at a glance
//
// Full theme implementation in Phase 2.
// Phase 1: Color constants defined and ready to use.
// ============================================================================

import 'package:flutter/material.dart';

/// Central color palette for the gate scanner app.
///
/// All colors are referenced from here — never use hardcoded Color()
/// literals in widget files. This enables easy theme changes.
abstract final class AppColors {
  AppColors._();

  // --------------------------------------------------------------------------
  // BACKGROUND COLORS
  // Dark theme backgrounds optimized for OLED screens and low-light use.
  // --------------------------------------------------------------------------

  /// Primary background — darkest surface, used for main screen backgrounds.
  static const Color backgroundPrimary = Color(0xFF0A0A0A);

  /// Secondary background — slightly lighter, used for cards and containers.
  static const Color backgroundSecondary = Color(0xFF141414);

  /// Tertiary background — used for elevated surfaces, dialogs, bottom sheets.
  static const Color backgroundTertiary = Color(0xFF1E1E1E);

  /// Surface color — used for interactive surfaces like buttons and inputs.
  static const Color surface = Color(0xFF242424);

  // --------------------------------------------------------------------------
  // TEXT COLORS
  // --------------------------------------------------------------------------

  /// Primary text — headings, important labels.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text — body text, descriptions.
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Tertiary text — hints, timestamps, less important info.
  static const Color tertiary = Color(0xFF6B6B6B);

  /// Disabled text — for disabled buttons and inputs.
  static const Color textDisabled = Color(0xFF404040);

  // --------------------------------------------------------------------------
  // BRAND / ACCENT COLORS
  // Scanner green is the primary brand color — associated with "go" and valid.
  // --------------------------------------------------------------------------

  /// Primary brand color — scanner green.
  /// Used for: primary buttons, active status indicators, accent elements.
  static const Color brandGreen = Color(0xFF2ECC71);

  /// Darker brand green — used for pressed states, darker accents.
  static const Color brandGreenDark = Color(0xFF27AE60);

  /// Brand green with low opacity — used for card backgrounds on valid state.
  static const Color brandGreenSurface = Color(0x1A2ECC71);

  // --------------------------------------------------------------------------
  // VALIDATION STATE COLORS
  // These are the most critical colors — operators must instantly recognize
  // the validation state from across a crowd.
  // --------------------------------------------------------------------------

  /// VALID — Ticket is valid and can be admitted.
  /// Bright green — positive, go, admit.
  static const Color statusValid = Color(0xFF2ECC71);

  /// VALID surface — Background for valid result cards.
  static const Color statusValidSurface = Color(0x1A2ECC71);

  /// ALREADY USED — Ticket has already been scanned.
  /// Amber/yellow — caution, already processed.
  static const Color statusAlreadyUsed = Color(0xFFF39C12);

  /// ALREADY USED surface — Background for already-used result cards.
  static const Color statusAlreadyUsedSurface = Color(0x1AF39C12);

  /// REVOKED — Ticket has been revoked by organizer.
  /// Red — deny entry.
  static const Color statusRevoked = Color(0xFFE74C3C);

  /// REVOKED surface — Background for revoked result cards.
  static const Color statusRevokedSurface = Color(0x1AE74C3C);

  /// CANCELLED — Order/ticket has been cancelled.
  /// Red — deny entry.
  static const Color statusCancelled = Color(0xFFE74C3C);

  /// CANCELLED surface.
  static const Color statusCancelledSurface = Color(0x1AE74C3C);

  /// INVALID — QR code not recognized or malformed.
  /// Red — deny entry.
  static const Color statusInvalid = Color(0xFFE74C3C);

  /// INVALID surface.
  static const Color statusInvalidSurface = Color(0x1AE74C3C);

  /// WRONG EVENT — Ticket belongs to a different event.
  /// Orange — deny entry but different from revoke/cancel.
  static const Color statusWrongEvent = Color(0xFFE67E22);

  /// WRONG EVENT surface.
  static const Color statusWrongEventSurface = Color(0x1AE67E22);

  // --------------------------------------------------------------------------
  // SEMANTIC / UTILITY COLORS
  // --------------------------------------------------------------------------

  /// Error color — for error states, destructive action buttons.
  static const Color error = Color(0xFFE74C3C);

  /// Error surface — background for error banners.
  static const Color errorSurface = Color(0x1AE74C3C);

  /// Warning color — for caution states.
  static const Color warning = Color(0xFFF39C12);

  /// Warning surface — background for warning banners.
  static const Color warningSurface = Color(0x1AF39C12);

  /// Info color — for informational states.
  static const Color info = Color(0xFF3498DB);

  /// Info surface — background for info banners.
  static const Color infoSurface = Color(0x1A3498DB);

  /// Success color — alias for statusValid for non-scan contexts.
  static const Color success = Color(0xFF2ECC71);

  /// Success surface.
  static const Color successSurface = Color(0x1A2ECC71);

  // --------------------------------------------------------------------------
  // BORDER / DIVIDER COLORS
  // --------------------------------------------------------------------------

  /// Primary border — visible card borders, input field borders.
  static const Color borderPrimary = Color(0xFF2A2A2A);

  /// Secondary border — subtle dividers.
  static const Color borderSecondary = Color(0xFF1E1E1E);

  // --------------------------------------------------------------------------
  // SCANNER OVERLAY COLORS
  // Used specifically in the QR camera viewfinder overlay.
  // --------------------------------------------------------------------------

  /// Scanner frame corner color — the four corner markers of the scan frame.
  static const Color scannerFrameCorner = Color(0xFF2ECC71);

  /// Scanner overlay mask — semi-transparent black outside the scan area.
  static const Color scannerOverlayMask = Color(0xBB000000);

  /// Scanner scan line color — animated line sweeping through scan area.
  static const Color scannerScanLine = Color(0xFF2ECC71);
}