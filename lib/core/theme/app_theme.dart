import 'package:flutter/material.dart';
import 'relay_colors.dart';

/// Relay Drivers app theme
/// Aligned with RelayPlatform design system
class AppTheme {
  AppTheme._();

  /// Standard border radius (sharp corners per brand guidelines)
  static const double borderRadius = 4.0;

  /// Card left accent bar width
  static const double accentBarWidth = 8.0;

  /// Standard button height
  static const double buttonHeight = 52.0;

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: RelayColors.primary,
        secondary: RelayColors.primaryLight,
        surface: RelayColors.darkSurface1,
        error: RelayColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RelayColors.darkTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: RelayColors.darkSurfaceBase,
      appBarTheme: const AppBarTheme(
        backgroundColor: RelayColors.darkSurface1,
        foregroundColor: RelayColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: RelayColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: RelayColors.darkSurface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: RelayColors.darkBorderSubtle,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RelayColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RelayColors.primary,
          minimumSize: const Size(double.infinity, buttonHeight),
          side: const BorderSide(color: RelayColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RelayColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RelayColors.darkSurface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: RelayColors.darkBorderDefault,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: RelayColors.darkBorderSubtle,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: RelayColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: RelayColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: RelayColors.danger, width: 2),
        ),
        hintStyle: const TextStyle(color: RelayColors.darkTextMuted),
        labelStyle: const TextStyle(color: RelayColors.darkTextSecondary),
        errorStyle: const TextStyle(color: RelayColors.danger),
      ),
      dividerTheme: const DividerThemeData(
        color: RelayColors.darkBorderSubtle,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RelayColors.darkSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RelayColors.darkSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RelayColors.darkSurface3,
        contentTextStyle: const TextStyle(color: RelayColors.darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RelayColors.darkSurface2,
        labelStyle: const TextStyle(color: RelayColors.darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      iconTheme: const IconThemeData(
        color: RelayColors.darkTextSecondary,
      ),
      textTheme: _darkTextTheme,
    );
  }

  static const TextTheme _darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: RelayColors.darkTextPrimary,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: RelayColors.darkTextPrimary,
      letterSpacing: -0.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: RelayColors.darkTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: RelayColors.darkTextPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: RelayColors.darkTextPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: RelayColors.darkTextPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: RelayColors.darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: RelayColors.darkTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: RelayColors.darkTextMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: RelayColors.darkTextPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: RelayColors.darkTextSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: RelayColors.darkTextMuted,
      letterSpacing: 0.5,
    ),
  );

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: RelayColors.primary,
        secondary: RelayColors.primaryDark,
        surface: RelayColors.lightSurface,
        error: RelayColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RelayColors.lightTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: RelayColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: RelayColors.lightSurface,
        foregroundColor: RelayColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: RelayColors.lightTextPrimary,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: RelayColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: RelayColors.lightBorderSubtle,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RelayColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RelayColors.primary,
          minimumSize: const Size(double.infinity, buttonHeight),
          side: const BorderSide(color: RelayColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RelayColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RelayColors.lightSurfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: RelayColors.lightBorderDefault,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: RelayColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: RelayColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: RelayColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: RelayColors.danger, width: 2),
        ),
        hintStyle: const TextStyle(color: RelayColors.lightTextMuted),
        labelStyle: const TextStyle(color: RelayColors.lightTextSecondary),
        errorStyle: const TextStyle(color: RelayColors.danger),
      ),
      dividerTheme: const DividerThemeData(
        color: RelayColors.lightBorderSubtle,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RelayColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RelayColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RelayColors.lightTextPrimary,
        contentTextStyle: const TextStyle(color: RelayColors.lightSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RelayColors.lightSurfaceElevated,
        labelStyle: const TextStyle(color: RelayColors.lightTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      iconTheme: const IconThemeData(
        color: RelayColors.lightTextSecondary,
      ),
      textTheme: _lightTextTheme,
    );
  }

  static const TextTheme _lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: RelayColors.lightTextPrimary,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: RelayColors.lightTextPrimary,
      letterSpacing: -0.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: RelayColors.lightTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: RelayColors.lightTextPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: RelayColors.lightTextPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: RelayColors.lightTextPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: RelayColors.lightTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: RelayColors.lightTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: RelayColors.lightTextMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: RelayColors.lightTextPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: RelayColors.lightTextSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: RelayColors.lightTextMuted,
      letterSpacing: 0.5,
    ),
  );
}
