// ============================================================================
// App Theme — Complete ThemeData for gate_scanner
//
// Implements a full Material 3 dark theme with:
// - Complete TextTheme with scanner-optimized type scale
// - ElevatedButton, OutlinedButton, TextButton themes
// - Card, Input, AppBar, BottomSheet, Dialog, SnackBar themes
// - Custom component themes for consistent UI across the app
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  AppTheme._();

  // ==========================================================================
  // TYPOGRAPHY CONSTANTS
  // Font sizes follow a clear scale for scannable information hierarchy.
  // Large sizes ensure readability in various lighting conditions.
  // ==========================================================================

  static const String _fontFamily = 'Roboto'; // System default on Android

  // Font size scale
  static const double _fontSizeDisplay = 36.0;    // Holder name on valid scan
  static const double _fontSizeHeadline1 = 28.0;  // Screen titles
  static const double _fontSizeHeadline2 = 22.0;  // Section headers
  static const double _fontSizeHeadline3 = 18.0;  // Card headers
  static const double _fontSizeBodyLarge = 16.0;   // Primary body content
  static const double _fontSizeBodyMedium = 14.0;  // Secondary body content
  static const double _fontSizeBodySmall = 12.0;   // Timestamps, captions
  static const double _fontSizeLabel = 11.0;       // Uppercase labels
  static const double _fontSizeButton = 15.0;      // Button labels

  // ==========================================================================
  // SPACING AND SHAPE CONSTANTS
  // ==========================================================================

  static const double _radiusSmall = 8.0;
  static const double _radiusMedium = 12.0;
  static const double _radiusLarge = 16.0;
  static const double _radiusXLarge = 24.0;
  static const double _radiusFull = 100.0; // Pills/badges

  // ==========================================================================
  // PUBLIC API
  // ==========================================================================

  /// The only theme for gate_scanner — dark mode only.
  ///
  /// Returns a fully configured [ThemeData] with all component themes set.
  /// Use via: MaterialApp.router(theme: AppTheme.darkTheme)
  static ThemeData get darkTheme {
    // Build color scheme first — other component themes reference it.
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary — brand green
      primary: AppColors.brandPrimary,
      onPrimary: AppColors.textInverse,
      primaryContainer: AppColors.brandPrimarySurface,
      onPrimaryContainer: AppColors.brandPrimary,
      // Secondary — darker green
      secondary: AppColors.brandPrimaryDark,
      onSecondary: AppColors.textInverse,
      secondaryContainer: AppColors.brandPrimarySurface,
      onSecondaryContainer: AppColors.brandPrimaryLight,
      // Tertiary — info blue
      tertiary: AppColors.info,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.infoSurface,
      onTertiaryContainer: AppColors.info,
      // Error
      error: AppColors.error,
      onError: AppColors.textPrimary,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
      // Surfaces
      surface: AppColors.backgroundSecondary,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.backgroundTertiary,
      onSurfaceVariant: AppColors.textSecondary,
      // Outline
      outline: AppColors.borderPrimary,
      outlineVariant: AppColors.borderSecondary,
      // Shadow and scrim
      shadow: Colors.black,
      scrim: Colors.black,
      // Inverse
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.backgroundPrimary,
      inversePrimary: AppColors.brandPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,

      // ---- Text Theme -------------------------------------------------------
      textTheme: _buildTextTheme(),

      // ---- AppBar Theme -----------------------------------------------------
      appBarTheme: _buildAppBarTheme(),

      // ---- Card Theme -------------------------------------------------------
      cardTheme: _buildCardTheme(),

      // ---- Elevated Button Theme --------------------------------------------
      elevatedButtonTheme: _buildElevatedButtonTheme(),

      // ---- Outlined Button Theme --------------------------------------------
      outlinedButtonTheme: _buildOutlinedButtonTheme(),

      // ---- Text Button Theme ------------------------------------------------
      textButtonTheme: _buildTextButtonTheme(),

      // ---- Input Decoration Theme -------------------------------------------
      inputDecorationTheme: _buildInputDecorationTheme(),

      // ---- Bottom Sheet Theme -----------------------------------------------
      bottomSheetTheme: _buildBottomSheetTheme(),

      // ---- Dialog Theme -----------------------------------------------------
      dialogTheme: _buildDialogTheme(),

      // ---- SnackBar Theme ---------------------------------------------------
      snackBarTheme: _buildSnackBarTheme(),

      // ---- Divider Theme ----------------------------------------------------
      dividerTheme: const DividerThemeData(
        color: AppColors.borderPrimary,
        thickness: 1,
        space: 1,
      ),

      // ---- Icon Theme -------------------------------------------------------
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // ---- Progress Indicator Theme -----------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimary,
        linearTrackColor: AppColors.backgroundTertiary,
        circularTrackColor: AppColors.backgroundTertiary,
      ),

      // ---- Switch Theme -----------------------------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandPrimary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandPrimarySurface;
          }
          return AppColors.backgroundTertiary;
        }),
      ),

      // ---- Chip Theme -------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundTertiary,
        selectedColor: AppColors.brandPrimarySurface,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: _fontSizeBodySmall,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.borderPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ---- List Tile Theme --------------------------------------------------
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: _fontSizeBodyLarge,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: _fontSizeBodyMedium,
        ),
        iconColor: AppColors.textSecondary,
      ),

      // ---- System UI Overlay ------------------------------------------------
      // Controlled globally but can be overridden per-screen with
      // SystemChrome.setSystemUIOverlayStyle() in individual screens.
    );
  }

  // ==========================================================================
  // PRIVATE BUILDERS — One method per component theme
  // ==========================================================================

  // --------------------------------------------------------------------------
  // TEXT THEME
  // Defines the complete typographic scale for the app.
  //
  // Scale rationale:
  // - displayLarge: Used for the holder name on valid ticket scan — MUST be
  //   readable at arm's length by gate operators
  // - headlineMedium/Small: Screen titles and section headers
  // - bodyLarge/Medium/Small: Info rows, descriptions, timestamps
  // - labelLarge: Button labels
  // - labelSmall: Uppercase category labels (ONLINE, PHYSICAL, VIP, etc.)
  // --------------------------------------------------------------------------
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Display — holder name on valid scan result
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeDisplay,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),

      // Headline — screen titles and major section headers
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeHeadline1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeHeadline2,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeHeadline3,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),

      // Title — card titles, list item titles, dialog titles
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeBodyLarge,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeBodyMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: _fontSizeBodySmall,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Body — main content, info rows, descriptions
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeBodyLarge,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: _fontSizeBodyMedium,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: _fontSizeBodySmall,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),

      // Label — buttons, chips, uppercase tags, small interactive elements
      labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeButton,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: _fontSizeBodySmall,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.2,
      ),
      labelSmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: _fontSizeLabel,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR THEME
  // --------------------------------------------------------------------------
  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: AppColors.backgroundSecondary,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20.0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeHeadline3,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.backgroundPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      toolbarHeight: 56,
    );
  }

  // --------------------------------------------------------------------------
  // CARD THEME
  // Default card styling — used for info cards on home screen,
  // settings cards, and general content grouping.
  // --------------------------------------------------------------------------
  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        side: const BorderSide(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  // --------------------------------------------------------------------------
  // ELEVATED BUTTON THEME — Primary action buttons
  // Example: "Start Scanning", "Confirm Check-in"
  //
  // States:
  // - Default: brand green background, black text
  // - Pressed: darker green
  // - Disabled: muted gray, lower opacity
  // --------------------------------------------------------------------------
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        // Background color per state
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.backgroundTertiary;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.brandPrimaryDark;
          }
          return AppColors.brandPrimary;
        }),
        // Foreground (text/icon) color per state
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textDisabled;
          }
          return AppColors.textInverse;
        }),
        // Overlay color for ripple effect
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withAlpha(30);
          }
          return Colors.transparent;
        }),
        // No elevation — flat design
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        // Text style
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: _fontSizeButton,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            letterSpacing: 0.2,
          ),
        ),
        // Shape and border radius
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusMedium)),
          ),
        ),
        // Padding
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        // Minimum size — ensures touch target is at least 48x48dp
        minimumSize: const WidgetStatePropertyAll(Size(88, 52)),
        // Tap animation
        animationDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // OUTLINED BUTTON THEME — Secondary action buttons
  // Example: "Manual Search", "Cancel", "Switch Event"
  //
  // States:
  // - Default: transparent background, brand green border and text
  // - Pressed: subtle brand green overlay
  // - Disabled: muted gray
  // --------------------------------------------------------------------------
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.brandPrimarySurface;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textDisabled;
          }
          return AppColors.brandPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.brandPrimarySurface;
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: AppColors.borderPrimary);
          }
          if (states.contains(WidgetState.pressed)) {
            return const BorderSide(color: AppColors.brandPrimaryDark);
          }
          return const BorderSide(color: AppColors.brandPrimary);
        }),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: _fontSizeButton,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            letterSpacing: 0.2,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusMedium)),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(88, 52)),
        animationDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TEXT BUTTON THEME — Tertiary / low-emphasis actions
  // Example: "Forgot something?", "Learn more", inline action links
  // --------------------------------------------------------------------------
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textDisabled;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.brandPrimaryDark;
          }
          return AppColors.brandPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.brandPrimarySurface;
          }
          return Colors.transparent;
        }),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: _fontSizeBodyMedium,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusSmall)),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 36)),
        animationDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // INPUT DECORATION THEME — Text fields
  // Used in: manual search input, any future login/filter inputs
  //
  // Design: filled background with no visible border by default,
  // colored border on focus, red border on error.
  // --------------------------------------------------------------------------
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundTertiary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      // Hint text style
      hintStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: _fontSizeBodyMedium,
        fontWeight: FontWeight.w400,
      ),
      // Label text style (floating)
      labelStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: _fontSizeBodyMedium,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.brandPrimary,
        fontSize: _fontSizeBodySmall,
        fontWeight: FontWeight.w500,
      ),
      // Error text style
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: _fontSizeBodySmall,
      ),
      // Default border — no border visible, just filled background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        borderSide: BorderSide.none,
      ),
      // Enabled border — subtle visible border
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderPrimary, width: 1),
      ),
      // Focused border — brand green
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      // Error border — red
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      // Focused error border
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      // Disabled border
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        borderSide: const BorderSide(color: AppColors.borderSecondary, width: 1),
      ),
      // Prefix/suffix icon color
      prefixIconColor: AppColors.textTertiary,
      suffixIconColor: AppColors.textTertiary,
    );
  }

  // --------------------------------------------------------------------------
  // BOTTOM SHEET THEME — Used for scan result modal
  // --------------------------------------------------------------------------
  static BottomSheetThemeData _buildBottomSheetTheme() {
    return BottomSheetThemeData(
      backgroundColor: AppColors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.backgroundSecondary,
      modalBarrierColor: AppColors.backgroundOverlay,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_radiusXLarge),
          topRight: Radius.circular(_radiusXLarge),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      dragHandleColor: AppColors.borderPrimary,
      dragHandleSize: const Size(40, 4),
      showDragHandle: true,
    );
  }

  // --------------------------------------------------------------------------
  // DIALOG THEME — Confirmation dialogs (logout, reset, switch event)
  // --------------------------------------------------------------------------
  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: AppColors.backgroundTertiary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeHeadline3,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: _fontSizeBodyMedium,
        height: 1.5,
        fontFamily: _fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLarge),
        side: const BorderSide(color: AppColors.borderPrimary),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      alignment: Alignment.center,
    );
  }

  // --------------------------------------------------------------------------
  // SNACKBAR THEME — Session revoked message, scan errors, network errors
  // --------------------------------------------------------------------------
  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: AppColors.backgroundTertiary,
      contentTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: _fontSizeBodyMedium,
        fontFamily: _fontFamily,
      ),
      actionTextColor: AppColors.brandPrimary,
      disabledActionTextColor: AppColors.textDisabled,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
        side: const BorderSide(color: AppColors.borderPrimary),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      closeIconColor: AppColors.textTertiary,
      showCloseIcon: true,
    );
  }

  // ==========================================================================
  // EXTENSION METHODS — Named card styles for specific use cases
  // These are not part of ThemeData — use them directly in widget code.
  // ==========================================================================

  /// Card decoration for the VALID scan result.
  static BoxDecoration get validResultDecoration => BoxDecoration(
        color: AppColors.statusValidSurface,
        borderRadius: BorderRadius.circular(_radiusLarge),
        border: Border.all(color: AppColors.statusValidBorder, width: 1.5),
      );

  /// Card decoration for the ALREADY USED scan result.
  static BoxDecoration get alreadyUsedResultDecoration => BoxDecoration(
        color: AppColors.statusAlreadyUsedSurface,
        borderRadius: BorderRadius.circular(_radiusLarge),
        border: Border.all(color: AppColors.statusAlreadyUsedBorder, width: 1.5),
      );

  /// Card decoration for REVOKED / CANCELLED / INVALID scan results.
  static BoxDecoration get deniedResultDecoration => BoxDecoration(
        color: AppColors.statusRevokedSurface,
        borderRadius: BorderRadius.circular(_radiusLarge),
        border: Border.all(color: AppColors.statusRevokedBorder, width: 1.5),
      );

  /// Card decoration for the WRONG EVENT scan result.
  static BoxDecoration get wrongEventResultDecoration => BoxDecoration(
        color: AppColors.statusWrongEventSurface,
        borderRadius: BorderRadius.circular(_radiusLarge),
        border: Border.all(color: AppColors.statusWrongEventBorder, width: 1.5),
      );

  /// Standard info card decoration used on home screen and settings.
  static BoxDecoration get infoCardDecoration => BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(_radiusMedium),
        border: Border.all(color: AppColors.borderPrimary, width: 1),
      );

  /// Highlighted info card — e.g., event name card on home screen.
  static BoxDecoration get highlightCardDecoration => BoxDecoration(
        color: AppColors.brandPrimarySurface,
        borderRadius: BorderRadius.circular(_radiusMedium),
        border: Border.all(color: AppColors.brandPrimaryBorder, width: 1),
      );
}