import 'package:flutter/material.dart';

/// Premium executive chauffeur color palette.
///
/// Brand: Purple/violet spectrum - sophisticated, premium, executive.
/// NOT cyan/teal. NOT green. NOT startup SaaS colors.
abstract class DesignColors {
  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE - Primary palette (executive chauffeur aesthetic)
  // ─────────────────────────────────────────────────────────────────────────

  /// Deepest background - behind city blur
  static const Color background = Color(0xFF080B14);

  /// Card backgrounds, surfaces - let background bleed through
  static const Color surface = Color(0xFF0F1420);

  /// Elevated cards, modals
  static const Color surfaceElevated = Color(0xFF151B2B);

  /// Highest elevation (popovers, tooltips)
  static const Color surfaceHighest = Color(0xFF1C2438);

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary text - white
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - muted
  static const Color textSecondary = Color(0xFFB0B8C4);

  /// Tertiary text - very muted (placeholders, hints)
  static const Color textMuted = Color(0xFF6B7280);

  /// Disabled text
  static const Color textDisabled = Color(0xFF4B5563);

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND ACCENT - Purple/Violet (executive, premium)
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary brand accent - selection, CTAs, active states
  static const Color accent = Color(0xFF8B5CF6);

  /// Lighter accent - hover states
  static const Color accentLight = Color(0xFFA78BFA);

  /// Darker accent - pressed states
  static const Color accentDark = Color(0xFF7C3AED);

  /// Accent with glow effect (for decorative shadows)
  static const Color accentGlow = Color(0x608B5CF6);

  /// Accent muted background (15% opacity)
  static const Color accentMuted = Color(0x268B5CF6);

  /// Secondary accent - complementary purple
  static const Color accentSecondary = Color(0xFFC084FC);

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS COLORS
  // ─────────────────────────────────────────────────────────────────────────

  /// Success - confirmations, completed
  static const Color success = Color(0xFF10B981);
  static const Color successMuted = Color(0x2610B981);

  /// Warning - Amber for alerts, pending states
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningMuted = Color(0x26F59E0B);

  /// Error/Danger - Critical alerts, destructive actions
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerMuted = Color(0x26EF4444);

  /// Info - Informational messages
  static const Color info = Color(0xFF3B82F6);
  static const Color infoMuted = Color(0x263B82F6);

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION ACCENTS (soft glow style, not corporate bars)
  // ─────────────────────────────────────────────────────────────────────────

  /// Profile section - indigo/purple
  static const Color profileAccent = Color(0xFF8B5CF6);

  /// Vehicles section - purple tint
  static const Color vehicleAccent = Color(0xFFA78BFA);

  /// Documents section - light purple
  static const Color documentAccent = Color(0xFFC084FC);

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS MORPHISM - Premium translucent cards
  // ─────────────────────────────────────────────────────────────────────────

  /// Glass card background - 4% white, let city blur show
  static const Color glassBackground = Color(0x0AFFFFFF);

  /// Glass border - 8% white
  static const Color glassBorder = Color(0x14FFFFFF);

  /// Glass inner highlight - 5% white (top edge glow)
  static const Color glassHighlight = Color(0x0DFFFFFF);

  /// Glass shadow - deep for depth
  static const Color glassShadow = Color(0x59000000);

  /// Glass background elevated - 6% white
  static const Color glassBackgroundElevated = Color(0x0FFFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // BORDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Subtle border - card edges
  static const Color borderSubtle = Color(0xFF1E2A3E);

  /// Default border - inputs
  static const Color borderDefault = Color(0xFF2D3E54);

  /// Focus border - focused inputs
  static const Color borderFocus = accent;

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT MODE
  // ─────────────────────────────────────────────────────────────────────────

  /// Light mode background
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Light mode surface (cards)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light mode elevated surface
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  /// Light mode primary text
  static const Color lightTextPrimary = Color(0xFF0F172A);

  /// Light mode secondary text
  static const Color lightTextSecondary = Color(0xFF64748B);

  /// Light mode muted text
  static const Color lightTextMuted = Color(0xFF94A3B8);

  /// Light mode subtle border
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);

  /// Light mode default border
  static const Color lightBorderDefault = Color(0xFFCBD5E1);

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /// Get background color based on brightness
  static Color getBackground(Brightness brightness) =>
      brightness == Brightness.dark ? background : lightBackground;

  /// Get surface color based on brightness
  static Color getSurface(Brightness brightness) =>
      brightness == Brightness.dark ? surface : lightSurface;

  /// Get elevated surface color based on brightness
  static Color getSurfaceElevated(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceElevated : lightSurfaceElevated;

  /// Get primary text color based on brightness
  static Color getTextPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimary : lightTextPrimary;

  /// Get secondary text color based on brightness
  static Color getTextSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondary : lightTextSecondary;

  /// Get muted text color based on brightness
  static Color getTextMuted(Brightness brightness) =>
      brightness == Brightness.dark ? textMuted : lightTextMuted;

  /// Get subtle border color based on brightness
  static Color getBorderSubtle(Brightness brightness) =>
      brightness == Brightness.dark ? borderSubtle : lightBorderSubtle;

  /// Get default border color based on brightness
  static Color getBorderDefault(Brightness brightness) =>
      brightness == Brightness.dark ? borderDefault : lightBorderDefault;
}
