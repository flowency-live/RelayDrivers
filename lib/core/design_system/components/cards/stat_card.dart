import 'dart:ui';
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

/// Earnings today card - Large stat display
///
/// Matches mockup: Large currency amount in glass card
/// Features:
/// - Large prominent number
/// - Section header
/// - Optional trend indicator
class EarningsTodayCard extends StatelessWidget {
  final String amount;
  final int? completedJobs;
  final String? trend;
  final bool isTrendPositive;
  final VoidCallback? onTap;

  const EarningsTodayCard({
    super.key,
    required this.amount,
    this.completedJobs,
    this.trend,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignRadii.card),
          child: BackdropFilter(
            filter: isDark
                ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              padding: const EdgeInsets.all(DesignSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignColors.glassBackground
                    : DesignColors.lightSurface,
                borderRadius: BorderRadius.circular(DesignRadii.card),
                border: Border.all(
                  color: isDark
                      ? DesignColors.glassBorder
                      : DesignColors.lightBorderSubtle,
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Earnings Today',
                        style: DesignTypography.sectionHeader.copyWith(
                          color: isDark
                              ? DesignColors.textMuted
                              : DesignColors.lightTextMuted,
                        ),
                      ),
                      if (trend != null)
                        _TrendBadge(
                          trend: trend!,
                          isPositive: isTrendPositive,
                          isDark: isDark,
                        ),
                    ],
                  ),

                  const SizedBox(height: DesignSpacing.md),

                  // Large amount
                  Text(
                    amount,
                    style: DesignTypography.statLarge.copyWith(
                      color: isDark
                          ? DesignColors.textPrimary
                          : DesignColors.lightTextPrimary,
                    ),
                  ),

                  // Completed jobs count
                  if (completedJobs != null) ...[
                    const SizedBox(height: DesignSpacing.xs),
                    Text(
                      '$completedJobs job${completedJobs == 1 ? '' : 's'} completed',
                      style: DesignTypography.bodySmall.copyWith(
                        color: isDark
                            ? DesignColors.textSecondary
                            : DesignColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trend badge showing percentage change
class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool isPositive;
  final bool isDark;

  const _TrendBadge({
    required this.trend,
    required this.isPositive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? DesignColors.success : DesignColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpacing.sm,
        vertical: DesignSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignRadii.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: DesignTypography.badge.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic stat card for various metrics
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final accent = accentColor ?? DesignColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? DesignColors.surface.withOpacity(0.5)
              : DesignColors.lightSurface,
          borderRadius: BorderRadius.circular(DesignRadii.card),
          border: Border.all(
            color: isDark
                ? DesignColors.borderSubtle
                : DesignColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + label
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: DesignSpacing.sm),
                ],
                Text(
                  label,
                  style: DesignTypography.labelSmall.copyWith(
                    color: isDark
                        ? DesignColors.textSecondary
                        : DesignColors.lightTextSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignSpacing.sm),

            // Value
            Text(
              value,
              style: DesignTypography.headlineMedium.copyWith(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat row for inline display
class CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const CompactStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DesignTypography.bodySmall.copyWith(
            color: isDark
                ? DesignColors.textSecondary
                : DesignColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: DesignTypography.bodyMedium.copyWith(
            color: valueColor ??
                (isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
