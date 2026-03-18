import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/foundations/glass.dart';
import '../../../onboarding/domain/services/onboarding_service.dart';

/// Premium home page action tile with glass morphism
///
/// Design specs:
/// - Glass card with translucent background (no colored left bar)
/// - Soft glow icon container instead of corporate colored box
/// - Operational status language instead of percentages
/// - Purple brand accent throughout
class HomeActionTile extends StatelessWidget {
  const HomeActionTile({
    super.key,
    required this.progress,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final SectionProgress progress;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return _buildLightModeTile(context);
    }

    // Dark mode: Premium glass card with soft glow icon
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(DesignSpacing.lg),
        child: Row(
          children: [
            // Soft glow icon container
            GlowIconContainer(
              icon: icon,
              color: accentColor,
              size: 52,
              iconSize: 24,
            ),
            const SizedBox(width: DesignSpacing.lg),

            // Title, description, and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.title,
                    style: DesignTypography.cardTitle.copyWith(
                      color: DesignColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.description,
                    style: DesignTypography.meta.copyWith(
                      color: DesignColors.textSecondary,
                    ),
                  ),
                  // Operational status instead of percentage
                  if (!progress.isComplete && progress.remainingItems > 0) ...[
                    const SizedBox(height: 8),
                    _buildStatusIndicator(progress),
                  ],
                ],
              ),
            ),

            const SizedBox(width: DesignSpacing.md),

            // Status indicator or completion check
            _buildTrailingIndicator(progress),
          ],
        ),
      ),
    );
  }

  Widget _buildLightModeTile(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(DesignSpacing.lg),
            decoration: BoxDecoration(
              // More translucent to show city background through
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.55),
                  Colors.white.withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: accentColor.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Light mode icon container with soft glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.12),
                        accentColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: DesignSpacing.lg),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.title,
                        style: DesignTypography.cardTitle.copyWith(
                          color: DesignColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress.description,
                        style: DesignTypography.meta.copyWith(
                          color: DesignColors.lightTextSecondary,
                        ),
                      ),
                      if (!progress.isComplete && progress.remainingItems > 0) ...[
                        const SizedBox(height: 8),
                        _buildStatusIndicator(progress, isLight: true),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: DesignSpacing.md),
                _buildTrailingIndicator(progress, isLight: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Operational status indicator - replaces percentage-based progress
  Widget _buildStatusIndicator(SectionProgress progress, {bool isLight = false}) {
    final String statusText;
    final Color statusColor;

    if (progress.remainingItems == 1) {
      statusText = '1 item needs attention';
      statusColor = DesignColors.warning;
    } else if (progress.remainingItems <= 3) {
      statusText = '${progress.remainingItems} items need attention';
      statusColor = DesignColors.warning;
    } else {
      statusText = 'Setup required';
      statusColor = DesignColors.warning;
    }

    // Wrap in semi-transparent pill for better contrast in light mode
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLight
            ? statusColor.withOpacity(0.15)
            : statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(
            color: statusColor,
            size: 6,
            animated: true,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: DesignTypography.labelSmall.copyWith(
              color: isLight ? Colors.black.withOpacity(0.85) : statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Trailing indicator - check mark when complete, chevron when not
  Widget _buildTrailingIndicator(SectionProgress progress, {bool isLight = false}) {
    if (progress.isComplete) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: DesignColors.success.withOpacity(0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DesignColors.success.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: DesignColors.success,
          size: 18,
        ),
      );
    }

    return Icon(
      Icons.chevron_right_rounded,
      color: isLight ? DesignColors.lightTextMuted : DesignColors.textMuted,
      size: 24,
    );
  }
}

/// Simple action tile without progress - premium glass version
class SimpleActionTile extends StatelessWidget {
  const SimpleActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return _buildLightMode(context);
    }

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(DesignSpacing.lg),
        child: Row(
          children: [
            GlowIconContainer(
              icon: icon,
              color: accentColor,
              size: 52,
              iconSize: 24,
            ),
            const SizedBox(width: DesignSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTypography.cardTitle.copyWith(
                      color: DesignColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: DesignTypography.meta.copyWith(
                      color: DesignColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: DesignColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightMode(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(DesignSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.55),
                  Colors.white.withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: accentColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.12),
                        accentColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: DesignSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DesignTypography.cardTitle.copyWith(
                          color: DesignColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: DesignTypography.meta.copyWith(
                          color: DesignColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: DesignColors.lightTextMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
