import 'package:flutter/material.dart';
import 'colors.dart';

/// Shadow tokens for elevation and depth effects.
///
/// Design direction: Subtle, premium shadows. No harsh drop shadows.
abstract class DesignShadows {
  // ─────────────────────────────────────────────────────────────────────────
  // ELEVATION LEVELS
  // ─────────────────────────────────────────────────────────────────────────

  /// Level 0 - No elevation (flat)
  static List<BoxShadow> get none => [];

  /// Level 1 - Subtle elevation (cards at rest)
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Level 2 - Medium elevation (hovered cards, inputs)
  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Level 3 - High elevation (floating elements, modals)
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];

  /// Level 4 - Highest elevation (overlays, popovers)
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS MORPHISM SHADOWS
  // ─────────────────────────────────────────────────────────────────────────

  /// Glass card shadow - subtle dark shadow
  static List<BoxShadow> get glass => [
        BoxShadow(
          color: DesignColors.glassShadow,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Glass elevated shadow - more prominent
  static List<BoxShadow> get glassElevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // ACCENT GLOW SHADOWS
  // ─────────────────────────────────────────────────────────────────────────

  /// Accent glow - for route dots, active elements
  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: DesignColors.accentGlow,
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  /// Success glow - for On Duty indicator
  static List<BoxShadow> get successGlow => [
        BoxShadow(
          color: DesignColors.success.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  /// Warning glow
  static List<BoxShadow> get warningGlow => [
        BoxShadow(
          color: DesignColors.warning.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  /// Danger glow
  static List<BoxShadow> get dangerGlow => [
        BoxShadow(
          color: DesignColors.danger.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC SHADOWS - Component-specific
  // ─────────────────────────────────────────────────────────────────────────

  /// Card shadow (dark mode)
  static List<BoxShadow> get card => glass;

  /// Card shadow (light mode)
  static List<BoxShadow> get cardLight => md;

  /// Elevated card shadow
  static List<BoxShadow> get cardElevated => glassElevated;

  /// Bottom nav shadow
  static List<BoxShadow> get bottomNav => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];

  /// Button pressed shadow (inset effect simulation)
  static List<BoxShadow> get buttonPressed => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Input focus shadow
  static List<BoxShadow> get inputFocus => [
        BoxShadow(
          color: DesignColors.accent.withOpacity(0.2),
          blurRadius: 4,
          spreadRadius: 1,
        ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY - Get shadow based on brightness
  // ─────────────────────────────────────────────────────────────────────────

  /// Get card shadow based on theme brightness
  static List<BoxShadow> getCardShadow(Brightness brightness) =>
      brightness == Brightness.dark ? card : cardLight;
}
