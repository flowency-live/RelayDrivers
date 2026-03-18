import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../application/calendar_providers.dart';
import '../../domain/models/availability_block.dart';

/// List of blocked periods with swipe-to-delete
class BlockedPeriodsList extends ConsumerWidget {
  const BlockedPeriodsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(availabilityBlocksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter to only show unavailable blocks (blocked periods)
    final blockedPeriods = blocks.where((b) => !b.available).toList();

    // Sort by date (most recent first)
    blockedPeriods.sort((a, b) => a.date.compareTo(b.date));

    if (blockedPeriods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: blockedPeriods.map((block) {
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignSpacing.sm),
          child: _BlockedPeriodItem(
            block: block,
            isDark: isDark,
            onDelete: () => _confirmDelete(context, ref, block),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AvailabilityBlock block,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? DesignColors.surface : DesignColors.lightSurface,
        title: Text(
          'Remove Block',
          style: DesignTypography.headlineSmall.copyWith(
            color:
                isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this blocked period?',
          style: DesignTypography.bodyMedium.copyWith(
            color: isDark
                ? DesignColors.textSecondary
                : DesignColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? DesignColors.textSecondary
                    : DesignColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DesignColors.danger,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(calendarStateProvider.notifier)
          .removeBlock(block.blockId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Block removed' : 'Failed to remove block',
            ),
            backgroundColor: success ? DesignColors.success : DesignColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Individual blocked period item with swipe-to-delete
class _BlockedPeriodItem extends StatelessWidget {
  final AvailabilityBlock block;
  final bool isDark;
  final VoidCallback onDelete;

  const _BlockedPeriodItem({
    required this.block,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(block.blockId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignSpacing.lg),
        decoration: BoxDecoration(
          color: DesignColors.danger,
          borderRadius: BorderRadius.circular(DesignRadii.card),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false; // Dialog handles the actual deletion
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(DesignSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignColors.glassBackground
                  : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(DesignRadii.card),
              border: Border.all(
                color: isDark
                    ? DesignColors.glassBorder
                    : Colors.white.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
        child: Row(
          children: [
            // Date indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayOfMonth(),
                    style: DesignTypography.headlineSmall.copyWith(
                      color: DesignColors.danger,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _getMonthAbbrev(),
                    style: DesignTypography.labelSmall.copyWith(
                      color: DesignColors.danger,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: DesignSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.isAllDay ? 'All Day' : _formatTimeRange(),
                    style: DesignTypography.labelMedium.copyWith(
                      color: isDark
                          ? DesignColors.textPrimary
                          : DesignColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (block.note != null && block.note!.isNotEmpty) ...[
                    const SizedBox(height: DesignSpacing.xxs),
                    Text(
                      block.note!,
                      style: DesignTypography.bodySmall.copyWith(
                        color: isDark
                            ? DesignColors.textSecondary
                            : DesignColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Delete hint
            Icon(
              Icons.chevron_left,
              size: 20,
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  String _getDayOfMonth() {
    try {
      final parts = block.date.split('-');
      return parts[2];
    } catch (_) {
      return '--';
    }
  }

  String _getMonthAbbrev() {
    try {
      final date = DateTime.parse(block.date);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return months[date.month - 1];
    } catch (_) {
      return '---';
    }
  }

  String _formatTimeRange() {
    return '${block.startTime} - ${block.endTime}';
  }
}
