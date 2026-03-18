import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../application/calendar_providers.dart';
import '../../domain/models/availability_block.dart';
import '../../domain/models/working_pattern.dart';
import 'add_block_sheet.dart';

/// Calendar grid showing days of the month
///
/// Each day cell shows:
/// - Day number
/// - Availability status indicator
/// - Booking indicator (if any)
class CalendarGrid extends ConsumerWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewingMonth = ref.watch(viewingMonthProvider);
    final workingPattern = ref.watch(workingPatternProvider);
    final blocks = ref.watch(availabilityBlocksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Day of week headers
        _WeekdayHeaders(isDark: isDark),
        const SizedBox(height: DesignSpacing.sm),
        // Calendar days
        _CalendarDays(
          month: viewingMonth,
          workingPattern: workingPattern,
          blocks: blocks,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Weekday header row (M T W T F S S)
class _WeekdayHeaders extends StatelessWidget {
  final bool isDark;

  const _WeekdayHeaders({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: DesignTypography.labelSmall.copyWith(
                color: isDark
                    ? DesignColors.textMuted
                    : DesignColors.lightTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Grid of calendar days
class _CalendarDays extends StatelessWidget {
  final DateTime month;
  final WorkingPattern workingPattern;
  final List<AvailabilityBlock> blocks;
  final bool isDark;

  const _CalendarDays({
    required this.month,
    required this.workingPattern,
    required this.blocks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();

    return Column(
      children: [
        for (int week = 0; week < days.length; week += 7)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignSpacing.xs),
            child: Row(
              children: [
                for (int i = 0; i < 7 && week + i < days.length; i++)
                  Expanded(
                    child: _DayCell(
                      day: days[week + i],
                      workingPattern: workingPattern,
                      blocks: blocks,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<DateTime?> _generateDays() {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Find what day of week the month starts (1 = Monday, 7 = Sunday)
    final startWeekday = firstDay.weekday;

    // Generate list with null padding for days before the month starts
    final days = <DateTime?>[];

    // Add padding for days before the month starts
    for (int i = 1; i < startWeekday; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    // Pad to complete the last week if needed
    while (days.length % 7 != 0) {
      days.add(null);
    }

    return days;
  }
}

/// Individual day cell
class _DayCell extends StatelessWidget {
  final DateTime? day;
  final WorkingPattern workingPattern;
  final List<AvailabilityBlock> blocks;
  final bool isDark;

  const _DayCell({
    required this.day,
    required this.workingPattern,
    required this.blocks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox(height: 44);
    }

    final status = _getDayStatus();
    final isToday = _isToday();

    return GestureDetector(
      onTap: () => _onDayTap(context),
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getBackgroundColor(status, isToday),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: DesignColors.accent, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Day number
            Text(
              '${day!.day}',
              style: DesignTypography.bodyMedium.copyWith(
                color: _getTextColor(status),
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),

            // Status indicator dot
            if (status != DayStatus.available && status != DayStatus.notWorking)
              Positioned(
                bottom: 4,
                child: _StatusIndicator(status: status),
              ),
          ],
        ),
      ),
    );
  }

  DayStatus _getDayStatus() {
    final isWorkingDay = workingPattern.isWorkingDay(day!);

    if (!isWorkingDay) return DayStatus.notWorking;

    final dayBlocks = blocks.where((b) => b.isForDate(day!)).toList();

    if (dayBlocks.any((b) => !b.available && b.isAllDay)) {
      return DayStatus.blocked;
    }

    if (dayBlocks.any((b) => !b.available)) {
      return DayStatus.partiallyBlocked;
    }

    // TODO: Check for bookings when API supports it
    // if (hasBookings) return DayStatus.hasBooking;

    return DayStatus.available;
  }

  bool _isToday() {
    final now = DateTime.now();
    return day!.year == now.year &&
        day!.month == now.month &&
        day!.day == now.day;
  }

  Color _getBackgroundColor(DayStatus status, bool isToday) {
    if (isToday) {
      return isDark
          ? DesignColors.accent.withOpacity(0.15)
          : DesignColors.accent.withOpacity(0.1);
    }

    switch (status) {
      case DayStatus.blocked:
        return isDark
            ? DesignColors.danger.withOpacity(0.15)
            : DesignColors.danger.withOpacity(0.1);
      case DayStatus.partiallyBlocked:
        return isDark
            ? DesignColors.warning.withOpacity(0.15)
            : DesignColors.warning.withOpacity(0.1);
      case DayStatus.hasBooking:
        return isDark
            ? DesignColors.success.withOpacity(0.15)
            : DesignColors.success.withOpacity(0.1);
      case DayStatus.notWorking:
        return isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1);
      case DayStatus.available:
        return Colors.transparent;
    }
  }

  Color _getTextColor(DayStatus status) {
    if (status == DayStatus.notWorking) {
      return isDark ? DesignColors.textMuted : DesignColors.lightTextMuted;
    }

    return isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary;
  }

  void _onDayTap(BuildContext context) {
    // Only allow blocking future dates or today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(day!.year, day!.month, day!.day);

    if (selectedDay.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot block past dates'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showAddBlockSheet(context, initialDate: day);
  }
}

/// Small indicator dot for day status
class _StatusIndicator extends StatelessWidget {
  final DayStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;

    switch (status) {
      case DayStatus.blocked:
        color = DesignColors.danger;
        icon = null;
      case DayStatus.partiallyBlocked:
        color = DesignColors.warning;
        icon = null;
      case DayStatus.hasBooking:
        color = DesignColors.success;
        icon = Icons.event;
      default:
        return const SizedBox.shrink();
    }

    if (icon != null) {
      return Icon(icon, size: 8, color: color);
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
