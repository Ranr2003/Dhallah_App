// lib/utils/app.theme.dart
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════
// 1. App Colors
// ══════════════════════════════════════════════

/// Stores all color constants used across the application.
abstract class AppColors {
  // Theme Main Colors
  static const Color primary     = Color(0xFFB293CD);
  static const Color primaryDark = Color(0xFF8A6AAF);
  static const Color secondary   = Color(0xFFE8DDF1);

  // Background & UI Elements
  static const Color background  = Color(0xFFFFFFFF);
  static const Color fieldBg     = Color(0xFFF9F9F9);
  static const Color white       = Colors.white;

  // Typography Colors
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666680);
  static const Color textHint      = Color(0xFFAAAAAA);

  // Status & Feedback Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error   = Color(0xFFE53935);

  // Miscellaneous
  static const Color mapPin      = Color(0xFFE53935);
  static const Color shadowColor = Color(0x1AB293CD);
}

// ══════════════════════════════════════════════
// 2. App Dimensions
// ══════════════════════════════════════════════

/// Centralizes all sizes, spacing, and radius constants.
abstract class AppDimens {
  // Border Radius Constants
  static const double radiusSmall  = 12.0;
  static const double radiusMedium = 15.0;
  static const double radiusLarge  = 25.0;
  static const double radiusSheet  = 30.0;

  // Component Sizes
  static const double buttonHeight = 52.0;
  static const double iconSizeLg   = 65.0;
  static const double iconSizeXl   = 100.0;
  static const double tabBarHeight = 50.0;

  // Spacing & Padding
  static const double spaceSm  = 8.0;
  static const double spaceMd  = 15.0;
  static const double spaceLg  = 25.0;
  static const double spaceXl  = 40.0;
  static const double paddingH = 25.0;

  // Font Sizes
  static const double fontSm      = 12.0;
  static const double fontMd      = 13.0;
  static const double fontLg      = 14.0;
  static const double fontXl      = 16.0;
  static const double fontTitle   = 17.0;
  static const double fontAppBar  = 18.0;
}

// ══════════════════════════════════════════════
// 3. Gradients
// ══════════════════════════════════════════════

/// Default linear gradient used for buttons and backgrounds.
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [AppColors.primary, AppColors.secondary],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ══════════════════════════════════════════════
// 4. Main App Theme
// ══════════════════════════════════════════════

/// Defines the global light theme data for the entire application.
abstract class AppTheme {

  /// Returns a configured [ThemeData] with custom styles.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',

      // Define standard color schemes
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary:   AppColors.primary,
        secondary: AppColors.secondary,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // Global style for AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      // Global style for Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Global style for Text Fields (Input Decoration)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}