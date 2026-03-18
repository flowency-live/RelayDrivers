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

  /// Overlay opacity (0.7 - 0.85 for readability)
  final double overlayOpacity;

  /// Whether to use daily rotation
  final bool rotateDailyBackground;

  /// Specific background index (overrides rotation)
  final int? backgroundIndex;

  /// Custom background asset path (overrides all)
  final String? customBackground;

  /// Whether to apply blur to the image
  final bool applyBlur;

  /// Blur intensity
  final double blurSigma;

  /// Whether to show gradient overlay
  final bool showGradient;

  const PremiumBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.75,
    this.rotateDailyBackground = true,
    this.backgroundIndex,
    this.customBackground,
    this.applyBlur = true,
    this.blurSigma = 4.0,
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

    // Light mode: Simple solid background, no city image
    if (brightness == Brightness.light) {
      return Container(
        color: DesignColors.lightBackground,
        child: child,
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

        // Layer 4: Content
        child,
      ],
    );
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
