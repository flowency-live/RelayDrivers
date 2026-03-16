import 'package:flutter/material.dart';

/// Relay brand color system
/// Aligned with RelayPlatform design system
class RelayColors {
  RelayColors._();

  // ============================================
  // PRIMARY BRAND COLOR
  // ============================================

  /// Primary brand purple - used for CTAs, links, focus states
  static const Color primary = Color(0xFF6366F1);

  /// Lighter variant for hover/pressed states
  static const Color primaryLight = Color(0xFF818CF8);

  /// Darker variant for contrast
  static const Color primaryDark = Color(0xFF4F46E5);

  // ============================================
  // DARK MODE SURFACE HIERARCHY
  // ============================================

  /// Base background (darkest layer)
  static const Color darkSurfaceBase = Color(0xFF13161B);

  /// Level 1 surface (cards, elevated content)
  static const Color darkSurface1 = Color(0xFF1A1E25);

  /// Level 2 surface (modals, dropdowns)
  static const Color darkSurface2 = Color(0xFF21262E);

  /// Level 3 surface (highest elevation)
  static const Color darkSurface3 = Color(0xFF282E38);

  /// Dark mode borders
  static const Color darkBorderSubtle = Color(0xFF2D333D);
  static const Color darkBorderDefault = Color(0xFF373E4A);
  static const Color darkBorderStrong = Color(0xFF444D5C);

  /// Dark mode text
  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFB8BFC9);
  static const Color darkTextMuted = Color(0xFF7D8694);

  // ============================================
  // LIGHT MODE SURFACES
  // ============================================

  /// Light mode background
  static const Color lightBackground = Color(0xFFF5F7FA);

  /// Light mode cards/surfaces
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light mode elevated surface
  static const Color lightSurfaceElevated = Color(0xFFFAFAFA);

  /// Light mode borders
  static const Color lightBorderSubtle = Color(0xFFE5E7EB);
  static const Color lightBorderDefault = Color(0xFFD1D5DB);
  static const Color lightBorderStrong = Color(0xFF9CA3AF);

  /// Light mode text
  static const Color lightTextPrimary = Color(0xFF13161B);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // ============================================
  // STATUS COLORS (Consistent across modes)
  // ============================================

  /// Success - completed, verified, active
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successBackground = Color(0xFF10B98120);

  /// Warning - attention needed, pending
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningBackground = Color(0xFFF59E0B20);

  /// Danger - error, expired, critical
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);
  static const Color dangerBackground = Color(0xFFEF444420);

  /// Info - informational, neutral highlight
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoBackground = Color(0xFF3B82F620);

  // ============================================
  // SECTION ACCENT COLORS (for home tiles)
  // ============================================

  /// Profile section accent
  static const Color sectionProfile = primary;

  /// Vehicles section accent
  static const Color sectionVehicles = Color(0xFF10B981);

  /// Documents section accent
  static const Color sectionDocuments = Color(0xFFF59E0B);

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get surface color for elevation level in dark mode
  static Color darkSurfaceForElevation(int level) {
    return switch (level) {
      0 => darkSurfaceBase,
      1 => darkSurface1,
      2 => darkSurface2,
      _ => darkSurface3,
    };
  }

  /// Get text color based on brightness
  static Color textPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  }

  /// Get text secondary color based on brightness
  static Color textSecondary(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  /// Get background color based on brightness
  static Color background(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurfaceBase : lightBackground;
  }

  /// Get surface color based on brightness
  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface1 : lightSurface;
  }

  /// Get border color based on brightness
  static Color border(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkBorderDefault
        : lightBorderDefault;
  }
}
