import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Premium glass morphism utilities.
///
/// Creates depth and premium feel with:
/// - Strong backdrop blur (12-18px sigma)
/// - Semi-transparent fill (4-8% white)
/// - Subtle white border (8% opacity)
/// - Deep shadows for elevation
/// - Background MUST bleed through

/// Premium glass container - allows background to show through.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enabled;
  final bool elevated;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.blurSigma = 12,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow,
    this.padding,
    this.margin,
    this.onTap,
    this.enabled = true,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Light mode: clean white cards
    if (!isDark) {
      return _buildLightModeCard(context);
    }

    // Dark mode: glass morphism with city blur visible
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow ??
            [
              BoxShadow(
                color: DesignColors.glassShadow,
                blurRadius: elevated ? 32 : 24,
                offset: const Offset(0, 8),
                spreadRadius: elevated ? 4 : 0,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: _buildGlassContent(context),
        ),
      ),
    );
  }

  Widget _buildGlassContent(BuildContext context) {
    final bgColor = backgroundColor ??
        (elevated
            ? DesignColors.glassBackgroundElevated
            : DesignColors.glassBackground);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? DesignColors.glassBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (onTap != null && enabled) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: DesignColors.accent.withOpacity(0.1),
          highlightColor: DesignColors.accent.withOpacity(0.05),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildLightModeCard(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: DesignColors.lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: DesignColors.lightBorderSubtle,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null && enabled) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Glass card with elevated styling (more blur, deeper shadow).
class GlassContainerElevated extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassContainerElevated({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: borderRadius,
      blurSigma: 18,
      elevated: true,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Glass pill/badge - smaller with tight blur.
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassPill({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: DesignRadii.badge,
      blurSigma: 10,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
      onTap: onTap,
      child: child,
    );
  }
}

/// Premium action button with glass styling.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.borderRadius = 12,
    this.padding,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isPrimary) {
      // Solid brand button with glow
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              DesignColors.accent,
              DesignColors.accentDark,
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: DesignColors.accentGlow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && !isLoading ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      );
    }

    return GlassContainer(
      borderRadius: borderRadius,
      blurSigma: 10,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
      onTap: enabled && !isLoading ? onPressed : null,
      enabled: enabled,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
            )
          : child,
    );
  }
}

/// Soft glow icon container - replaces heavy colored boxes.
class GlowIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  const GlowIconContainer({
    super.key,
    required this.icon,
    this.color,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? DesignColors.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: iconColor.withOpacity(isDark ? 0.9 : 1.0),
        size: iconSize,
      ),
    );
  }
}

/// Status indicator dot with glow.
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool animated;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Simple glass card - convenient shorthand for common card use case.
/// Replaces corporate-style cards with glass morphism.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blurSigma: elevated ? 16 : 12,
      elevated: elevated,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Decorative glass highlight effect (inner glow).
class GlassHighlight extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassHighlight({
    super.key,
    required this.child,
    this.borderRadius = DesignRadii.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignColors.glassHighlight,
            Colors.transparent,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: child,
    );
  }
}
