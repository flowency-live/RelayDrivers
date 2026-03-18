import 'dart:ui';
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

/// Schedule preview card - upcoming bookings list
///
/// Matches mockup: Time | Location | Price in compact rows
/// Features:
/// - Glass morphism container
/// - Section header with "View All" link
/// - Compact schedule items
class SchedulePreviewCard extends StatelessWidget {
  final List<ScheduleItemData> items;
  final VoidCallback? onViewAll;

  const SchedulePreviewCard({
    super.key,
    required this.items,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (items.isEmpty) {
      return _EmptySchedule(isDark: isDark);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignRadii.card),
        child: BackdropFilter(
          filter: isDark
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSpacing.lg,
                    DesignSpacing.lg,
                    DesignSpacing.lg,
                    DesignSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule',
                        style: DesignTypography.sectionHeader.copyWith(
                          color: isDark
                              ? DesignColors.textMuted
                              : DesignColors.lightTextMuted,
                        ),
                      ),
                      if (onViewAll != null)
                        GestureDetector(
                          onTap: onViewAll,
                          child: Text(
                            'View All',
                            style: DesignTypography.labelSmall.copyWith(
                              color: DesignColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Schedule items
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == items.length - 1;

                  return _ScheduleItem(
                    item: item,
                    showDivider: !isLast,
                    isDark: isDark,
                  );
                }),

                const SizedBox(height: DesignSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data model for schedule item
class ScheduleItemData {
  final String time;
  final String location;
  final String? price;
  final VoidCallback? onTap;

  const ScheduleItemData({
    required this.time,
    required this.location,
    this.price,
    this.onTap,
  });
}

/// Individual schedule item row
class _ScheduleItem extends StatelessWidget {
  final ScheduleItemData item;
  final bool showDivider;
  final bool isDark;

  const _ScheduleItem({
    required this.item,
    required this.showDivider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpacing.lg,
              vertical: DesignSpacing.md,
            ),
            child: Row(
              children: [
                // Time
                SizedBox(
                  width: 70,
                  child: Text(
                    item.time,
                    style: DesignTypography.scheduleTime.copyWith(
                      color: isDark
                          ? DesignColors.textSecondary
                          : DesignColors.lightTextSecondary,
                    ),
                  ),
                ),

                // Location
                Expanded(
                  child: Text(
                    item.location,
                    style: DesignTypography.bodyMedium.copyWith(
                      color: isDark
                          ? DesignColors.textPrimary
                          : DesignColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Price
                if (item.price != null)
                  Text(
                    item.price!,
                    style: DesignTypography.bodyMedium.copyWith(
                      color: isDark
                          ? DesignColors.textSecondary
                          : DesignColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          if (showDivider)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
              child: Container(
                height: 1,
                color: isDark
                    ? DesignColors.borderSubtle
                    : DesignColors.lightBorderSubtle,
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state for no scheduled bookings
class _EmptySchedule extends StatelessWidget {
  final bool isDark;

  const _EmptySchedule({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
      padding: const EdgeInsets.all(DesignSpacing.xl),
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
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 32,
            color: isDark
                ? DesignColors.textMuted
                : DesignColors.lightTextMuted,
          ),
          const SizedBox(height: DesignSpacing.md),
          Text(
            'No upcoming bookings',
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
