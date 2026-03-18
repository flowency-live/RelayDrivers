import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Premium blur backgrounds for chauffeur console.
///
/// Features:
/// - Daily rotation option (changes background each day)
/// - Desaturated, toned premium aesthetic
/// - Dark overlay for readability
/// - Gradient fade for depth
///
/// Asset requirements:
/// - Place images in: assets/backgrounds/
/// - Format: WebP for best compression
/// - Size: 1080px wide minimum
abstract class BackgroundAssets {
  // ─────────────────────────────────────────────────────────────────────────
  // PREMIUM BACKGROUNDS (rotate daily)
  // ─────────────────────────────────────────────────────────────────────────

  /// List of backgrounds for daily rotation
  static const List<String> backgrounds = [
    'assets/backgrounds/bg1.webp',
    'assets/backgrounds/bg2.webp',
    'assets/backgrounds/bg3.webp',
    'assets/backgrounds/bg4.webp',
    'assets/backgrounds/bg5.webp',
    'assets/backgrounds/bg6.webp',
    'assets/backgrounds/bg7.webp',
    'assets/backgrounds/bg8.webp',
    'assets/backgrounds/bg9.webp',
  ];

  /// Default fallback background
  static const String defaultBackground = 'assets/backgrounds/bg1.webp';

  /// Get background for current day (rotates daily)
  static String getBackgroundForToday() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final index = dayOfYear % backgrounds.length;
    return backgrounds[index];
  }

  /// Get specific background by index
  static String getBackgroundByIndex(int index) {
    if (index < 0 || index >= backgrounds.length) {
      return defaultBackground;
    }
    return backgrounds[index];
  }
}

/// Premium background widget with city blur and overlays.
///
/// Usage:
/// ```dart
/// PremiumBackground(
///   child: Scaffold(
///     backgroundColor: Colors.transparent,
///     body: YourContent(),
///   ),
/// )
/// ```
class PremiumBackground extends StatelessWidget {
  /// Content to display over background
  final Widget child;

  /// Overlay opacity (0.4 - 0.55 for visible background)
  final double overlayOpacity;

  /// Whether to use daily rotation
  final bool rotateDailyBackground;

  /// Specific background index (overrides rotation)
  final int? backgroundIndex;

  /// Custom background asset path (overrides all)
  final String? customBackground;

  /// Whether to apply blur to the image
  final bool applyBlur;

  /// Blur intensity (lower = more visible city)
  final double blurSigma;

  /// Whether to show gradient overlay
  final bool showGradient;

  const PremiumBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.45,
    this.rotateDailyBackground = true,
    this.backgroundIndex,
    this.customBackground,
    this.applyBlur = true,
    this.blurSigma = 3.0,
    this.showGradient = true,
  });

  String get _backgroundAsset {
    if (customBackground != null) {
      return customBackground!;
    }
    if (backgroundIndex != null) {
      return BackgroundAssets.getBackgroundByIndex(backgroundIndex!);
    }
    if (rotateDailyBackground) {
      return BackgroundAssets.getBackgroundForToday();
    }
    return BackgroundAssets.defaultBackground;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Light mode: Premium soft gradient with subtle depth
    if (brightness == Brightness.light) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Subtle city image (very light)
          _buildLightBackgroundImage(),

          // Layer 2: Light overlay - subtle so city shows through
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DesignColors.lightBackground.withOpacity(0.45),
                    DesignColors.lightBackground.withOpacity(0.50),
                    DesignColors.lightBackground.withOpacity(0.55),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Layer 3: Subtle purple brand glow at top
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.8),
                  radius: 1.2,
                  colors: [
                    DesignColors.accent.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Layer 4: Content
          child,
        ],
      );
    }

    // Dark mode: Background blur with overlays
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: City background image
        _buildBackgroundImage(),

        // Layer 2: Dark overlay for readability
        _buildDarkOverlay(),

        // Layer 3: Gradient fade (optional)
        if (showGradient) _buildGradientOverlay(),

        // Layer 4: Subtle purple brand glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.5),
                radius: 1.5,
                colors: [
                  DesignColors.accent.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Layer 5: Content
        child,
      ],
    );
  }

  Widget _buildLightBackgroundImage() {
    Widget image = Image.asset(
      _backgroundAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Slightly desaturated but keep warmth visible
      colorBlendMode: BlendMode.saturation,
      color: Colors.grey.withOpacity(0.5),
      errorBuilder: (context, error, stackTrace) {
        return Container(color: DesignColors.lightBackground);
      },
    );

    // Gentle blur to maintain city visibility
    image = ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 6.0,
        sigmaY: 6.0,
        tileMode: TileMode.clamp,
      ),
      child: image,
    );

    return Positioned.fill(child: image);
  }

  Widget _buildBackgroundImage() {
    Widget image = Image.asset(
      _backgroundAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Color filter to desaturate and add blue tint
      colorBlendMode: BlendMode.saturation,
      color: Colors.grey.withOpacity(0.6), // Reduces saturation
      errorBuilder: (context, error, stackTrace) {
        // Fallback to solid color if image fails to load
        return Container(color: DesignColors.background);
      },
    );

    // Apply blur if enabled
    if (applyBlur) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: image,
      );
    }

    return Positioned.fill(child: image);
  }

  Widget _buildDarkOverlay() {
    return Positioned.fill(
      child: Container(
        color: DesignColors.background.withOpacity(overlayOpacity),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              DesignColors.background.withOpacity(0.3),
              DesignColors.background.withOpacity(0.7),
              DesignColors.background,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Simplified background for pages that don't need the full city blur.
/// Uses solid color in both light and dark modes.
class SolidBackground extends StatelessWidget {
  final Widget child;

  const SolidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      color: DesignColors.getBackground(brightness),
      child: child,
    );
  }
}

/// Background for modal sheets (semi-transparent with blur).
class ModalBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const ModalBackground({
    super.key,
    required this.child,
    this.opacity = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: DesignColors.surface.withOpacity(opacity),
          child: child,
        ),
      ),
    );
  }
}

/// Premium auth background - ALWAYS uses dark premium styling.
///
/// Auth screens (login, invite, OTP) should always look premium,
/// regardless of the app's current theme mode. This creates a
/// consistent, impressive first impression.
class PremiumAuthBackground extends StatelessWidget {
  final Widget child;

  /// Overlay opacity (0.4 - 0.55 for visible background on auth screens)
  final double overlayOpacity;

  /// Whether to apply stronger blur
  final bool applyBlur;

  const PremiumAuthBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.40,
    this.applyBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    // Auth screens always use premium dark styling
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: City background image
        _buildBackgroundImage(),

        // Layer 2: Subtle dark overlay - city visible through
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DesignColors.background.withOpacity(overlayOpacity),
                  DesignColors.background.withOpacity(overlayOpacity + 0.10),
                  DesignColors.background.withOpacity(overlayOpacity + 0.15),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Layer 3: Subtle purple brand gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.5),
                radius: 1.5,
                colors: [
                  DesignColors.accent.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Layer 4: Content
        child,
      ],
    );
  }

  Widget _buildBackgroundImage() {
    final asset = BackgroundAssets.getBackgroundForToday();

    Widget image = Image.asset(
      asset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      colorBlendMode: BlendMode.saturation,
      color: Colors.grey.withOpacity(0.5),
      errorBuilder: (context, error, stackTrace) {
        return Container(color: DesignColors.background);
      },
    );

    if (applyBlur) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 4.0,
          sigmaY: 4.0,
          tileMode: TileMode.clamp,
        ),
        child: image,
      );
    }

    return Positioned.fill(child: image);
  }
}
