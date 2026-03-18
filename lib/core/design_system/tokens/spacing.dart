/// Spacing tokens for consistent margins and padding.
///
/// Based on 4px grid with common multipliers.
abstract class DesignSpacing {
  // ─────────────────────────────────────────────────────────────────────────
  // BASE SPACING SCALE
  // ─────────────────────────────────────────────────────────────────────────

  /// 4px - Minimal spacing
  static const double xxs = 4;

  /// 8px - Tight spacing
  static const double xs = 8;

  /// 12px - Compact spacing
  static const double sm = 12;

  /// 16px - Default spacing
  static const double md = 16;

  /// 20px - Comfortable spacing
  static const double lg = 20;

  /// 24px - Generous spacing
  static const double xl = 24;

  /// 32px - Section spacing
  static const double xxl = 32;

  /// 40px - Large section spacing
  static const double xxxl = 40;

  /// 48px - Page section spacing
  static const double huge = 48;

  /// 64px - Major section dividers
  static const double massive = 64;

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC SPACING - Component-specific
  // ─────────────────────────────────────────────────────────────────────────

  /// Card internal padding
  static const double cardPadding = md;

  /// Card internal padding - compact variant
  static const double cardPaddingCompact = sm;

  /// Card internal padding - large variant
  static const double cardPaddingLarge = xl;

  /// List item vertical padding
  static const double listItemPadding = sm;

  /// Section gap - between cards/sections
  static const double sectionGap = lg;

  /// Page horizontal padding (safe area)
  static const double pageHorizontal = md;

  /// Page top padding (after safe area)
  static const double pageTop = md;

  /// Page bottom padding (before nav)
  static const double pageBottom = xl;

  /// Bottom nav height
  static const double bottomNavHeight = 80;

  /// Input vertical padding
  static const double inputVertical = sm;

  /// Input horizontal padding
  static const double inputHorizontal = md;

  /// Button vertical padding
  static const double buttonVertical = 14;

  /// Button horizontal padding
  static const double buttonHorizontal = lg;

  /// Icon-text gap
  static const double iconTextGap = xs;

  /// Badge padding horizontal
  static const double badgePaddingH = sm;

  /// Badge padding vertical
  static const double badgePaddingV = xxs;

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT SIZES
  // ─────────────────────────────────────────────────────────────────────────

  /// Small avatar size
  static const double avatarSm = 32;

  /// Medium avatar size
  static const double avatarMd = 40;

  /// Large avatar size
  static const double avatarLg = 56;

  /// Extra large avatar (profile)
  static const double avatarXl = 80;

  /// Icon size - small
  static const double iconSm = 16;

  /// Icon size - medium (default)
  static const double iconMd = 24;

  /// Icon size - large
  static const double iconLg = 32;

  /// Route timeline dot size
  static const double routeDotSize = 16;

  /// Route timeline line width
  static const double routeLineWidth = 2;

  /// Route timeline line height
  static const double routeLineHeight = 40;

  /// Left accent bar width (onboarding cards)
  static const double accentBarWidth = 4;

  /// Progress bar height
  static const double progressBarHeight = 6;

  // ─────────────────────────────────────────────────────────────────────────
  // LAYOUT CONSTANTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Maximum content width (for tablets/desktop)
  static const double maxContentWidth = 428;

  /// Map preview height
  static const double mapPreviewHeight = 140;

  /// Job card min height
  static const double jobCardMinHeight = 180;
}
