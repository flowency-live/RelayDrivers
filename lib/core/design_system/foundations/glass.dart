import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';

/// Glass morphism utilities for premium card effects.
///
/// Creates the frosted glass look with:
/// - Backdrop blur
/// - Semi-transparent fill
/// - Subtle white border (10% opacity)
/// - Soft shadows

/// Glass morphism container widget.
///
/// Usage:
/// ```dart
/// GlassContainer(
///   borderRadius: DesignRadii.card,
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: YourContent(),
///   ),
/// )
/// ```
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

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = DesignRadii.card,
    this.blurSigma = 20,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.shadow,
    this.padding,
    this.margin,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Use glass effect only in dark mode
    if (!isDark) {
      return _buildLightModeCard(context);
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow ?? DesignShadows.glass,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: _buildCardContent(context, isDark: true),
        ),
      ),
    );
  }

  Widget _buildLightModeCard(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: DesignColors.lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: DesignColors.lightBorderSubtle,
          width: borderWidth,
        ),
        boxShadow: DesignShadows.cardLight,
      ),
      child: _buildCardContent(context, isDark: false),
    );
  }

  Widget _buildCardContent(BuildContext context, {required bool isDark}) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? DesignColors.glassBackground
                : DesignColors.lightSurface),
        borderRadius: BorderRadius.circular(borderRadius),
        border: isDark
            ? Border.all(
                color: borderColor ?? DesignColors.glassBorder,
                width: borderWidth,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null && enabled) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Elevated glass container with more prominent shadow.
class GlassContainerElevated extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassContainerElevated({
    super.key,
    required this.child,
    this.borderRadius = DesignRadii.card,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: borderRadius,
      blurSigma: 25,
      backgroundColor: DesignColors.surfaceElevated.withOpacity(0.7),
      shadow: DesignShadows.glassElevated,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Glass pill/badge container.
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
      blurSigma: 15,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
      onTap: onTap,
      child: child,
    );
  }
}

/// Glass button with blur effect.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.borderRadius = DesignRadii.button,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: borderRadius,
      blurSigma: 15,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
      onTap: enabled && !isLoading ? onPressed : null,
      enabled: enabled,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DesignColors.textPrimary,
              ),
            )
          : child,
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
