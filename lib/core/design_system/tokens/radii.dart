import 'package:flutter/material.dart';

/// Border radius tokens for consistent rounded corners.
///
/// Design direction: Softer than current 4px, more premium feel.
abstract class DesignRadii {
  // ─────────────────────────────────────────────────────────────────────────
  // BASE RADIUS SCALE
  // ─────────────────────────────────────────────────────────────────────────

  /// No radius - sharp corners
  static const double none = 0;

  /// 4px - Subtle rounding
  static const double xs = 4;

  /// 8px - Small elements (badges, chips)
  static const double sm = 8;

  /// 12px - Medium elements (inputs, small cards)
  static const double md = 12;

  /// 16px - Default cards
  static const double lg = 16;

  /// 20px - Large cards, modals
  static const double xl = 20;

  /// 24px - Pills, rounded buttons
  static const double xxl = 24;

  /// 28px - Bottom nav bar
  static const double xxxl = 28;

  /// Full circle (for avatar, dots)
  static const double full = 9999;

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC RADII - Component-specific
  // ─────────────────────────────────────────────────────────────────────────

  /// Card border radius
  static const double card = lg;

  /// Card border radius - compact variant
  static const double cardCompact = md;

  /// Button border radius
  static const double button = sm;

  /// Button border radius - pill style
  static const double buttonPill = xxl;

  /// Input border radius
  static const double input = sm;

  /// Badge/chip border radius
  static const double badge = xxl;

  /// Duty toggle border radius
  static const double dutyToggle = xxl;

  /// Bottom nav border radius
  static const double bottomNav = xxxl;

  /// Modal/sheet border radius
  static const double modal = xl;

  /// Avatar border radius (circular)
  static const double avatar = full;

  /// Progress bar border radius
  static const double progressBar = full;

  /// Map preview border radius
  static const double mapPreview = md;

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER RADIUS OBJECTS
  // ─────────────────────────────────────────────────────────────────────────

  /// All corners - card
  static BorderRadius get borderRadiusCard =>
      const BorderRadius.all(Radius.circular(card));

  /// All corners - button
  static BorderRadius get borderRadiusButton =>
      const BorderRadius.all(Radius.circular(button));

  /// All corners - input
  static BorderRadius get borderRadiusInput =>
      const BorderRadius.all(Radius.circular(input));

  /// All corners - badge/pill
  static BorderRadius get borderRadiusBadge =>
      const BorderRadius.all(Radius.circular(badge));

  /// All corners - bottom nav
  static BorderRadius get borderRadiusBottomNav =>
      const BorderRadius.all(Radius.circular(bottomNav));

  /// Top corners only - modal/sheet
  static BorderRadius get borderRadiusModalTop => const BorderRadius.only(
        topLeft: Radius.circular(modal),
        topRight: Radius.circular(modal),
      );

  /// Left corners only - accent bar container
  static BorderRadius get borderRadiusLeftAccent => const BorderRadius.only(
        topLeft: Radius.circular(card),
        bottomLeft: Radius.circular(card),
      );
}
