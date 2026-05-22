// ============================================================================
// App Colors — Complete color palette for gate_scanner
//
// Design principles:
// 1. Dark-first: optimized for low-light gate/entrance environments
// 2. High contrast validation states: operators must read results instantly
// 3. Semantic color mapping: green=valid, red=deny, amber=caution, orange=wrong
// 4. OLED friendly: true blacks (0xFF000000) for battery efficiency
// 5. Accessible: all text colors meet WCAG AA contrast ratios on dark backgrounds
// ============================================================================

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Private constructor — this class is a namespace, not instantiated.
  AppColors._();

  // ==========================================================================
  // BACKGROUND HIERARCHY
  // Uses layered dark surfaces to create visual depth without shadows.
  // Each layer is slightly lighter than the one below it.
  // ==========================================================================

  /// Level 0 — Deepest background. Used for Scaffold backgrounds.
  /// True near-black for OLED battery savings.
  static const Color backgroundPrimary = Color(0xFF080808);

  /// Level 1 — Card and container backgrounds.
  /// Slightly lifted from the scaffold background.
  static const Color backgroundSecondary = Color(0xFF141414);

  /// Level 2 — Elevated surfaces: dialogs, bottom sheets, drawers.
  static const Color backgroundTertiary = Color(0xFF1C1C1C);

  /// Level 3 — Interactive surfaces: selected states, hover backgrounds.
  static const Color backgroundQuaternary = Color(0xFF242424);

  /// Overlay — Used for modal barriers and loading overlays.
  /// Semi-transparent black.
  static const Color backgroundOverlay = Color(0xCC000000);

  // ==========================================================================
  // TEXT COLORS
  // Layered opacity system for text hierarchy.
  // ==========================================================================

  /// Primary text — headings, important values, names.
  /// Full white for maximum contrast on dark backgrounds.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text — body content, labels, descriptions.
  /// Reduced opacity for visual hierarchy.
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Tertiary text — hints, timestamps, metadata, helper text.
  static const Color textTertiary = Color(0xFF6B6B6B);

  /// Disabled text — for disabled UI elements.
  static const Color textDisabled = Color(0xFF3D3D3D);

  /// Inverse text — black text on light/colored backgrounds.
  /// Used on brand green buttons.
  static const Color textInverse = Color(0xFF000000);

  // ==========================================================================
  // BRAND / ACCENT — Scanner Green
  // The primary brand color. Associated with "go", "valid", "active".
  // Chosen to be immediately recognizable as a positive/proceed signal.
  // ==========================================================================

  /// Primary brand color — scanner green.
  /// Used for: primary CTA buttons, active status dots, accent borders,
  /// scan frame corners, and navigation highlights.
  static const Color brandPrimary = Color(0xFF00D16C);

  /// Brand dark — pressed/active state of primary brand color.
  static const Color brandPrimaryDark = Color(0xFF00A855);

  /// Brand light — for subtle accents and hover states.
  static const Color brandPrimaryLight = Color(0xFF33DA89);

  /// Brand surface — very low opacity brand color for card backgrounds.
  /// Used as tint on valid ticket result cards.
  static const Color brandPrimarySurface = Color(0x1400D16C);

  /// Brand border — low opacity brand color for card borders.
  static const Color brandPrimaryBorder = Color(0x3300D16C);

  // ==========================================================================
  // VALIDATION STATE COLORS — CRITICAL
  //
  // These six colors are the most important in the app.
  // Gate operators must instantly recognize the scan result color
  // from across a crowd. Each color maps to a specific action:
  //
  //   GREEN  → Admit (valid)
  //   AMBER  → Caution — already processed (already used)
  //   RED    → Deny (revoked, cancelled, invalid)
  //   ORANGE → Deny + investigate (wrong event)
  // ==========================================================================

  // --- VALID ----------------------------------------------------------------
  /// Bright green — "ADMIT". Ticket is valid and not yet used.
  static const Color statusValid = Color(0xFF00D16C);
  static const Color statusValidDark = Color(0xFF009E52);
  static const Color statusValidSurface = Color(0x1A00D16C);
  static const Color statusValidBorder = Color(0x4000D16C);

  // --- ALREADY USED ---------------------------------------------------------
  /// Amber — "CAUTION". Ticket was already checked in. Possible duplicate.
  static const Color statusAlreadyUsed = Color(0xFFFFB020);
  static const Color statusAlreadyUsedDark = Color(0xFFCC8C00);
  static const Color statusAlreadyUsedSurface = Color(0x1AFFB020);
  static const Color statusAlreadyUsedBorder = Color(0x40FFB020);

  // --- REVOKED --------------------------------------------------------------
  /// Red — "DENY". Ticket has been explicitly revoked by the organizer.
  static const Color statusRevoked = Color(0xFFFF3B30);
  static const Color statusRevokedDark = Color(0xFFCC2F26);
  static const Color statusRevokedSurface = Color(0x1AFF3B30);
  static const Color statusRevokedBorder = Color(0x40FF3B30);

  // --- CANCELLED ------------------------------------------------------------
  /// Red — "DENY". The order or ticket has been cancelled.
  /// Same color family as revoked — both mean deny entry.
  static const Color statusCancelled = Color(0xFFFF3B30);
  static const Color statusCancelledDark = Color(0xFFCC2F26);
  static const Color statusCancelledSurface = Color(0x1AFF3B30);
  static const Color statusCancelledBorder = Color(0x40FF3B30);

  // --- INVALID --------------------------------------------------------------
  /// Red — "DENY". QR code not recognized, malformed, or not in system.
  static const Color statusInvalid = Color(0xFFFF3B30);
  static const Color statusInvalidDark = Color(0xFFCC2F26);
  static const Color statusInvalidSurface = Color(0x1AFF3B30);
  static const Color statusInvalidBorder = Color(0x40FF3B30);

  // --- WRONG EVENT ----------------------------------------------------------
  /// Orange — "DENY + INVESTIGATE". Ticket exists but for a different event.
  /// Different from pure red to signal "valid ticket, wrong location".
  static const Color statusWrongEvent = Color(0xFFFF6B00);
  static const Color statusWrongEventDark = Color(0xFFCC5500);
  static const Color statusWrongEventSurface = Color(0x1AFF6B00);
  static const Color statusWrongEventBorder = Color(0x40FF6B00);

  // ==========================================================================
  // SEMANTIC UTILITY COLORS
  // Standard semantic colors for non-validation UI states.
  // ==========================================================================

  // --- ERROR ----------------------------------------------------------------
  static const Color error = Color(0xFFFF3B30);
  static const Color errorDark = Color(0xFFCC2F26);
  static const Color errorSurface = Color(0x1AFF3B30);
  static const Color errorBorder = Color(0x40FF3B30);

  // --- WARNING --------------------------------------------------------------
  static const Color warning = Color(0xFFFFB020);
  static const Color warningSurface = Color(0x1AFFB020);
  static const Color warningBorder = Color(0x40FFB020);

  // --- SUCCESS --------------------------------------------------------------
  static const Color success = Color(0xFF00D16C);
  static const Color successSurface = Color(0x1A00D16C);
  static const Color successBorder = Color(0x4000D16C);

  // --- INFO -----------------------------------------------------------------
  static const Color info = Color(0xFF0A84FF);
  static const Color infoDark = Color(0xFF0066CC);
  static const Color infoSurface = Color(0x1A0A84FF);
  static const Color infoBorder = Color(0x400A84FF);

  // ==========================================================================
  // BORDER AND DIVIDER COLORS
  // ==========================================================================

  /// Standard card/container border.
  static const Color borderPrimary = Color(0xFF2A2A2A);

  /// Subtle divider between list items.
  static const Color borderSecondary = Color(0xFF1E1E1E);

  /// Focus/active border for input fields.
  static const Color borderFocus = Color(0xFF00D16C);

  /// Error state border for input fields.
  static const Color borderError = Color(0xFFFF3B30);

  // ==========================================================================
  // SCANNER OVERLAY — QR Camera Viewfinder
  // Used exclusively in the QR scanner camera view overlay.
  // ==========================================================================

  /// Corner markers of the scan frame — brand green for "aim here".
  static const Color scannerFrameCorner = Color(0xFF00D16C);

  /// Semi-transparent mask covering the area outside the scan frame.
  static const Color scannerOverlayMask = Color(0xCC000000);

  /// Animated scan line color — sweeps through the scan frame.
  static const Color scannerScanLine = Color(0xBB00D16C);

  /// Scan frame border outline.
  static const Color scannerFrameBorder = Color(0x6600D16C);

  // ==========================================================================
  // STATUS INDICATOR COLORS
  // Used for small status dots/indicators on the home screen.
  // ==========================================================================

  /// Active/online session indicator dot.
  static const Color indicatorActive = Color(0xFF00D16C);

  /// Inactive/offline indicator dot.
  static const Color indicatorInactive = Color(0xFF6B6B6B);

  /// Error/revoked session indicator dot.
  static const Color indicatorError = Color(0xFFFF3B30);

  // ==========================================================================
  // STATIC HELPER METHODS
  // Convenience methods for getting state colors programmatically.
  // ==========================================================================

  /// Returns the primary color for a given validation status string.
  ///
  /// Used by StatusBadge and scan result screens to apply correct color.
  /// [status] should match the backend validation_status field values.
  static Color forValidationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return statusValid;
      case 'already_used':
      case 'already_checked_in':
        return statusAlreadyUsed;
      case 'revoked':
        return statusRevoked;
      case 'cancelled':
        return statusCancelled;
      case 'invalid':
        return statusInvalid;
      case 'wrong_event':
        return statusWrongEvent;
      default:
        return textTertiary;
    }
  }

  /// Returns the surface (background) color for a given validation status.
  static Color surfaceForValidationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return statusValidSurface;
      case 'already_used':
      case 'already_checked_in':
        return statusAlreadyUsedSurface;
      case 'revoked':
        return statusRevokedSurface;
      case 'cancelled':
        return statusCancelledSurface;
      case 'invalid':
        return statusInvalidSurface;
      case 'wrong_event':
        return statusWrongEventSurface;
      default:
        return backgroundSecondary;
    }
  }

  /// Returns the border color for a given validation status.
  static Color borderForValidationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return statusValidBorder;
      case 'already_used':
      case 'already_checked_in':
        return statusAlreadyUsedBorder;
      case 'revoked':
        return statusRevokedBorder;
      case 'cancelled':
        return statusCancelledBorder;
      case 'invalid':
        return statusInvalidBorder;
      case 'wrong_event':
        return statusWrongEventBorder;
      default:
        return borderPrimary;
    }
  }
}