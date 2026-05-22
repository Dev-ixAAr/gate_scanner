// ============================================================================
// App Theme — ThemeData configuration for gate_scanner
//
// Dark theme optimized for gate scanning in various lighting conditions.
// Full implementation in Phase 2.
// Phase 1: Returns basic dark theme with app colors applied.
// ============================================================================

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Provides the MaterialApp theme configuration for the gate scanner app.
///
/// Only dark theme is provided — scanner apps are used in varied lighting
/// and dark mode is universally more appropriate for this use case.
abstract final class AppTheme {
  AppTheme._();

  // TODO: Implement full ThemeData in Phase 2 with:
  // - Custom text styles (TextTheme)
  // - Card decoration theme
  // - Button themes (ElevatedButton, OutlinedButton, TextButton)
  // - Input decoration theme
  // - AppBar theme
  // - BottomSheet theme
  // - SnackBar theme
  // - Dialog theme

  /// Dark theme for the gate scanner app.
  ///
  /// Uses Material 3 design system with scanner-optimized colors.
  static ThemeData get darkTheme {
    return ThemeData(
      // Use Material 3 design system.
      useMaterial3: true,

      // Base brightness — dark.
      brightness: Brightness.dark,

      // Color scheme — derived from brand green seed color.
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandGreen,
        onPrimary: Colors.black,
        secondary: AppColors.brandGreenDark,
        onSecondary: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.backgroundSecondary,
        onSurface: AppColors.textPrimary,
      ),

      // Scaffold background color.
      scaffoldBackgroundColor: AppColors.backgroundPrimary,

      // AppBar theme.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Card theme.
      cardTheme: CardThemeData(
        color: AppColors.backgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderPrimary),
        ),
      ),

      // Divider theme.
      dividerTheme: const DividerThemeData(
        color: AppColors.borderPrimary,
        thickness: 1,
      ),

      // Text theme — TODO: expand in Phase 2.
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.tertiary,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}