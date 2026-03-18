import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens/colors.dart';
import 'tokens/typography.dart';
import 'tokens/radii.dart';

/// Premium chauffeur console theme.
///
/// Assembles design tokens into Flutter ThemeData.
/// Supports both dark (primary) and light modes.
class DesignTheme {
  DesignTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME (Primary - City blur background)
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Colors
        colorScheme: const ColorScheme.dark(
          primary: DesignColors.accent,
          onPrimary: Colors.black,
          secondary: DesignColors.accentLight,
          onSecondary: Colors.black,
          surface: DesignColors.surface,
          onSurface: DesignColors.textPrimary,
          error: DesignColors.danger,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: DesignColors.surface,
        cardColor: DesignColors.surface,
        dividerColor: DesignColors.borderSubtle,

        // Typography
        textTheme: DesignTypography.textTheme,
        fontFamily: DesignTypography.fontFamily,

        // App bar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: DesignColors.textPrimary),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        // Bottom nav
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: DesignColors.surface,
          selectedItemColor: DesignColors.accent,
          unselectedItemColor: DesignColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: DesignTypography.navLabelActive,
          unselectedLabelStyle: DesignTypography.navLabel,
        ),

        // Cards
        cardTheme: CardThemeData(
          color: DesignColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignRadii.card),
            side: const BorderSide(
              color: DesignColors.borderSubtle,
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),

        // Elevated button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.accent,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignRadii.button),
            ),
            textStyle: DesignTypography.button,
          ),
        ),

        // Outlined button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignColors.textPrimary,
            side: BorderSide(
              color: DesignColors.textMuted.withOpacity(0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignRadii.button),
            ),
            textStyle: DesignTypography.button,
          ),
        ),

        // Text button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DesignColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: DesignTypography.button,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DesignColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.danger, width: 2),
          ),
          labelStyle: DesignTypography.labelMedium,
          hintStyle: DesignTypography.bodyMedium.copyWith(
            color: DesignColors.textMuted,
          ),
          errorStyle: DesignTypography.labelSmall.copyWith(
            color: DesignColors.danger,
          ),
        ),

        // Chips
        chipTheme: ChipThemeData(
          backgroundColor: DesignColors.surfaceElevated,
          selectedColor: DesignColors.accentMuted,
          disabledColor: DesignColors.surface,
          labelStyle: DesignTypography.badge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignRadii.badge),
          ),
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: DesignColors.surfaceElevated,
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignRadii.modal),
          ),
          titleTextStyle: DesignTypography.headlineMedium,
          contentTextStyle: DesignTypography.bodyMedium,
        ),

        // Bottom sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: DesignColors.surface,
          modalBackgroundColor: DesignColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(DesignRadii.modal),
              topRight: Radius.circular(DesignRadii.modal),
            ),
          ),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: DesignColors.surfaceHighest,
          contentTextStyle: DesignTypography.bodyMedium.copyWith(
            color: DesignColors.textPrimary,
          ),
          actionTextColor: DesignColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignRadii.card),
          ),
        ),

        // Progress indicators
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: DesignColors.accent,
          linearTrackColor: DesignColors.surfaceElevated,
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DesignColors.accent;
            }
            return DesignColors.textMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DesignColors.accentMuted;
            }
            return DesignColors.surfaceElevated;
          }),
        ),

        // List tile
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          titleTextStyle: DesignTypography.titleMedium,
          subtitleTextStyle: DesignTypography.bodySmall,
          iconColor: DesignColors.textSecondary,
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: DesignColors.textSecondary,
          size: 24,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: DesignColors.borderSubtle,
          thickness: 1,
          space: 1,
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Colors
        colorScheme: const ColorScheme.light(
          primary: DesignColors.accent,
          onPrimary: Colors.white,
          secondary: DesignColors.accentDark,
          onSecondary: Colors.white,
          surface: DesignColors.lightSurface,
          onSurface: DesignColors.lightTextPrimary,
          error: DesignColors.danger,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: DesignColors.lightBackground,
        canvasColor: DesignColors.lightSurface,
        cardColor: DesignColors.lightSurface,
        dividerColor: DesignColors.lightBorderSubtle,

        // Typography
        textTheme: DesignTypography.textTheme.apply(
          bodyColor: DesignColors.lightTextPrimary,
          displayColor: DesignColors.lightTextPrimary,
        ),
        fontFamily: DesignTypography.fontFamily,

        // App bar
        appBarTheme: const AppBarTheme(
          backgroundColor: DesignColors.lightSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignColors.lightTextPrimary,
          ),
          iconTheme: IconThemeData(color: DesignColors.lightTextPrimary),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),

        // Bottom nav
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: DesignColors.lightSurface,
          selectedItemColor: DesignColors.accent,
          unselectedItemColor: DesignColors.lightTextMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: DesignTypography.navLabelActive,
          unselectedLabelStyle: DesignTypography.navLabel,
        ),

        // Cards
        cardTheme: CardThemeData(
          color: DesignColors.lightSurface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignRadii.card),
          ),
          margin: EdgeInsets.zero,
        ),

        // Elevated button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.accent,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignRadii.button),
            ),
            textStyle: DesignTypography.button,
          ),
        ),

        // Outlined button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignColors.lightTextPrimary,
            side: BorderSide(
              color: DesignColors.lightBorderDefault,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignRadii.button),
            ),
            textStyle: DesignTypography.button,
          ),
        ),

        // Text button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DesignColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: DesignTypography.button,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DesignColors.lightSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.lightBorderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.lightBorderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignRadii.input),
            borderSide: const BorderSide(color: DesignColors.danger, width: 2),
          ),
          labelStyle: DesignTypography.labelMedium.copyWith(
            color: DesignColors.lightTextSecondary,
          ),
          hintStyle: DesignTypography.bodyMedium.copyWith(
            color: DesignColors.lightTextMuted,
          ),
          errorStyle: DesignTypography.labelSmall.copyWith(
            color: DesignColors.danger,
          ),
        ),

        // Progress indicators
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: DesignColors.accent,
          linearTrackColor: DesignColors.lightBorderSubtle,
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: DesignColors.lightTextSecondary,
          size: 24,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: DesignColors.lightBorderSubtle,
          thickness: 1,
          space: 1,
        ),
      );
}
