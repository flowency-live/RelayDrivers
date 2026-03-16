import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../onboarding/domain/services/onboarding_service.dart';

/// Home page action tile with progress ring
///
/// Displays a section card with:
/// - Left accent bar in section color
/// - Icon, title, and description
/// - Progress ring showing completion percentage
/// - Missing items hint when incomplete
class HomeActionTile extends StatelessWidget {
  const HomeActionTile({
    super.key,
    required this.progress,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  /// Section progress data
  final SectionProgress progress;

  /// Accent color for left bar and icon
  final Color accentColor;

  /// Section icon
  final IconData icon;

  /// Tap callback
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? RelayColors.darkSurface1 : RelayColors.lightSurface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: AppTheme.accentBarWidth,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                _IconBadge(
                  icon: icon,
                  color: accentColor,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),

                // Title, description, and missing items
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? RelayColors.darkTextSecondary
                                  : RelayColors.lightTextSecondary,
                            ),
                      ),
                      // Show missing items hint when incomplete
                      if (!progress.isComplete &&
                          progress.remainingItems > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${progress.remainingItems} ${progress.remainingItems == 1 ? 'item' : 'items'} remaining',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: RelayColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Progress ring
                AnimatedProgressRing(
                  progress: progress.percent,
                  size: 48,
                  strokeWidth: 4,
                  progressColor: accentColor,
                  showPercentage: true,
                  showCheckWhenComplete: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon badge with background
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 30 : 20),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: color.withAlpha(isDark ? 50 : 40),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}

/// Simple action tile without progress (for non-onboarding sections)
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

    return Material(
      color: isDark ? RelayColors.darkSurface1 : RelayColors.lightSurface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: AppTheme.accentBarWidth,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _IconBadge(
                  icon: icon,
                  color: accentColor,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? RelayColors.darkTextSecondary
                                  : RelayColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? RelayColors.darkTextMuted
                      : RelayColors.lightTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
