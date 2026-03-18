import 'package:flutter/material.dart';

/// Premium chauffeur console color palette.
///
/// Design direction: Executive, calm, less Uber, more private chauffeur.
/// Background: Deep navy with city blur (dark mode) / clean white (light mode).
/// Accent: Cyan/teal for active states, route lines, interactive elements.
abstract class DesignColors {
  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE - Primary palette (from mockups)
  // ─────────────────────────────────────────────────────────────────────────

  /// Deepest background - behind city blur
  static const Color background = Color(0xFF0A0E1A);

  /// Card backgrounds, surfaces
  static const Color surface = Color(0xFF121829);

  /// Elevated cards, modals
  static const Color surfaceElevated = Color(0xFF1A2235);

  /// Highest elevation (popovers, tooltips)
  static const Color surfaceHighest = Color(0xFF242D42);

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
  // ACCENT - Cyan/Teal (from mockup route lines, active states)
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary accent - used for nav selection, CTAs, route lines
  static const Color accent = Color(0xFF00D4AA);

  /// Lighter accent - hover states
  static const Color accentLight = Color(0xFF4AEDC4);

  /// Darker accent - pressed states
  static const Color accentDark = Color(0xFF00A88A);

  /// Accent with glow effect (for decorative shadows)
  static const Color accentGlow = Color(0x4000D4AA);

  /// Accent muted background (15% opacity)
  static const Color accentMuted = Color(0x2600D4AA);

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS COLORS
  // ─────────────────────────────────────────────────────────────────────────

  /// Success - On Duty green, confirmations
  static const Color success = Color(0xFF22C55E);
  static const Color successMuted = Color(0x2622C55E);

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
  // SECTION ACCENTS (from mockup onboarding cards)
  // ─────────────────────────────────────────────────────────────────────────

  /// Profile section - purple/indigo
  static const Color profileAccent = Color(0xFF6366F1);

  /// Vehicles section - green
  static const Color vehicleAccent = Color(0xFF22C55E);

  /// Documents section - amber
  static const Color documentAccent = Color(0xFFF59E0B);

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS MORPHISM
  // ─────────────────────────────────────────────────────────────────────────

  /// Glass card background (10% surface)
  static const Color glassBackground = Color(0x1A1A2235);

  /// Glass border (10% white)
  static const Color glassBorder = Color(0x1AFFFFFF);

  /// Glass inner highlight (5% white)
  static const Color glassHighlight = Color(0x0DFFFFFF);

  /// Glass shadow
  static const Color glassShadow = Color(0x40000000);

  // ─────────────────────────────────────────────────────────────────────────
  // BORDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Subtle border - card edges
  static const Color borderSubtle = Color(0xFF2D3E54);

  /// Default border - inputs
  static const Color borderDefault = Color(0xFF3D4E64);

  /// Focus border - focused inputs
  static const Color borderFocus = accent;

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT MODE
  // ─────────────────────────────────────────────────────────────────────────

  /// Light mode background
  static const Color lightBackground = Color(0xFFF5F7FA);

  /// Light mode surface (cards)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light mode elevated surface
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  /// Light mode primary text
  static const Color lightTextPrimary = Color(0xFF1A1A2E);

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
