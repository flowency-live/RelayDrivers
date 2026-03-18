import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography tokens for premium chauffeur console.
///
/// Font: SF Pro Display (iOS) / Roboto (Android/Web).
/// Style: Clean, professional, authoritative. No quirky display fonts.
abstract class DesignTypography {
  // ─────────────────────────────────────────────────────────────────────────
  // FONT FAMILY
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary font family - system default for native feel
  /// iOS: SF Pro Display, Android: Roboto, Web: system-ui
  static const String fontFamily = '.SF Pro Display';

  // ─────────────────────────────────────────────────────────────────────────
  // DISPLAY STYLES - Large headers
  // ─────────────────────────────────────────────────────────────────────────

  /// Display large - hero numbers (earnings, stats)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
    color: DesignColors.textPrimary,
  );

  /// Display medium - page titles
  static const TextStyle displayMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.2,
    color: DesignColors.textPrimary,
  );

  /// Display small - section heroes
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: DesignColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // GREETING STYLES - "Good Evening, Daniel"
  // ─────────────────────────────────────────────────────────────────────────

  /// Greeting prefix - "Good Evening" (light weight)
  static const TextStyle greetingLight = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.2,
    color: DesignColors.textPrimary,
  );

  /// Greeting name - "Daniel" (semibold, emphasis)
  static const TextStyle greetingName = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: DesignColors.textPrimary,
  );

  /// Greeting subtitle - "Driving with BoardWalk Ltd"
  static const TextStyle greetingSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: DesignColors.textSecondary,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // HEADLINE STYLES
  // ─────────────────────────────────────────────────────────────────────────

  /// Headline large - major section headers
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.3,
    color: DesignColors.textPrimary,
  );

  /// Headline medium - card titles
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: DesignColors.textPrimary,
  );

  /// Headline small - subsection headers
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: DesignColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TITLE STYLES
  // ─────────────────────────────────────────────────────────────────────────

  /// Title large - list item primary text
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: DesignColors.textPrimary,
  );

  /// Title medium - card content headers
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: DesignColors.textPrimary,
  );

  /// Title small - compact list items
  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: DesignColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BODY STYLES
  // ─────────────────────────────────────────────────────────────────────────

  /// Body large - primary body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: DesignColors.textPrimary,
  );

  /// Body medium - default body text
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: DesignColors.textSecondary,
  );

  /// Body small - secondary content, descriptions
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: DesignColors.textSecondary,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // LABEL STYLES - UI elements
  // ─────────────────────────────────────────────────────────────────────────

  /// Label large - buttons, tabs
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: DesignColors.textPrimary,
  );

  /// Label medium - form labels, chips
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
    color: DesignColors.textSecondary,
  );

  /// Label small - captions, helper text
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
    color: DesignColors.textMuted,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION HEADER STYLE
  // ─────────────────────────────────────────────────────────────────────────

  /// Section header - "CURRENT JOB", "SCHEDULE", uppercase labels
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: DesignColors.textMuted,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SPECIAL PURPOSE STYLES
  // ─────────────────────────────────────────────────────────────────────────

  /// Card title - action tile headers (17px per design spec)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: DesignColors.textPrimary,
  );

  /// Job title - primary destination/location name
  static const TextStyle jobTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: DesignColors.textPrimary,
  );

  /// Schedule time - "04:45 pm" in schedule list
  static const TextStyle scheduleTime = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: DesignColors.textPrimary,
  );

  /// Schedule destination - location in schedule list
  static const TextStyle scheduleDestination = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: DesignColors.textSecondary,
  );

  /// Meta text - timestamps, distances, secondary info
  static const TextStyle meta = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: DesignColors.textSecondary,
  );

  /// Stat value - large earnings numbers
  static const TextStyle statLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.1,
    color: DesignColors.textPrimary,
  );

  /// Badge text - status badges, pills
  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Button text - action buttons
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.4,
  );

  /// Nav label - bottom navigation labels
  static const TextStyle navLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  /// Nav label active - selected bottom navigation
  static const TextStyle navLabelActive = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY - Get TextTheme for ThemeData
  // ─────────────────────────────────────────────────────────────────────────

  /// Build TextTheme for ThemeData
  static TextTheme get textTheme => const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
