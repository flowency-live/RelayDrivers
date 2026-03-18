import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../application/calendar_providers.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/working_hours_card.dart';
import '../widgets/blocked_periods_list.dart';
import '../widgets/add_block_sheet.dart';

/// Calendar page for managing driver availability
///
/// Shows:
/// - Month navigation and calendar grid
/// - Working hours summary
/// - List of blocked periods
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  void initState() {
    super.initState();
    // Load availability data on mount
    Future.microtask(() {
      ref.read(calendarStateProvider.notifier).loadAvailability();
    });
  }

  void _showAddBlockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBlockSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Calendar',
          style: DesignTypography.headlineMedium.copyWith(
            color: isDark
                ? DesignColors.textPrimary
                : Colors.white,
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: DesignColors.accent,
            ),
            onPressed: _showAddBlockSheet,
            tooltip: 'Block time off',
          ),
        ],
      ),
      body: _buildBody(calendarState, isDark),
    );
  }

  Widget _buildBody(CalendarState state, bool isDark) {
    if (state is CalendarLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: DesignColors.accent,
        ),
      );
    }

    if (state is CalendarError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: DesignColors.danger,
            ),
            const SizedBox(height: DesignSpacing.md),
            Text(
              'Failed to load calendar',
              style: DesignTypography.bodyLarge.copyWith(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: DesignSpacing.sm),
            Text(
              state.message,
              style: DesignTypography.bodySmall.copyWith(
                color: isDark
                    ? DesignColors.textSecondary
                    : DesignColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.read(calendarStateProvider.notifier).loadAvailability();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignColors.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is CalendarLoaded || state is CalendarSaving) {
      return _buildCalendarContent(isDark);
    }

    // Initial state - show loading
    return Center(
      child: CircularProgressIndicator(
        color: DesignColors.accent,
      ),
    );
  }

  Widget _buildCalendarContent(bool isDark) {
    final viewingMonth = ref.watch(viewingMonthProvider);
    final blocks = ref.watch(monthBlocksProvider);
    final isSaving = ref.watch(calendarIsSavingProvider);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month header with navigation
              _MonthHeader(
                month: viewingMonth,
                onPrevious: () {
                  ref.read(calendarStateProvider.notifier).previousMonth();
                },
                onNext: () {
                  ref.read(calendarStateProvider.notifier).nextMonth();
                },
                isDark: isDark,
              ),

              const SizedBox(height: DesignSpacing.md),

              // Calendar grid
              const CalendarGrid(),

              const SizedBox(height: DesignSpacing.xl),

              // Working hours card
              const WorkingHoursCard(),

              const SizedBox(height: DesignSpacing.lg),

              // Blocked periods list
              _SectionHeader(
                title: 'Blocked Periods',
                trailing: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: DesignColors.accent,
                    size: 20,
                  ),
                  onPressed: _showAddBlockSheet,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Block time off',
                ),
                isDark: isDark,
              ),

              const SizedBox(height: DesignSpacing.sm),

              if (blocks.isEmpty)
                _EmptyBlocksMessage(isDark: isDark)
              else
                const BlockedPeriodsList(),

              const SizedBox(height: DesignSpacing.xxl),
            ],
          ),
        ),

        // Saving indicator overlay
        if (isSaving)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: DesignColors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Month header with navigation arrows
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isDark;

  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.isDark,
  });

  String get _monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: isDark
                ? DesignColors.textSecondary
                : Colors.white.withOpacity(0.9),
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
          ),
          onPressed: onPrevious,
          tooltip: 'Previous month',
        ),
        const SizedBox(width: DesignSpacing.md),
        Text(
          _monthName,
          style: DesignTypography.headlineSmall.copyWith(
            color: isDark
                ? DesignColors.textPrimary
                : Colors.white,
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        ),
        const SizedBox(width: DesignSpacing.md),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: isDark
                ? DesignColors.textSecondary
                : Colors.white.withOpacity(0.9),
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
          ),
          onPressed: onNext,
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

/// Section header with optional trailing widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: DesignTypography.sectionHeader.copyWith(
            color: isDark
                ? DesignColors.textMuted
                : Colors.white.withOpacity(0.85),
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Empty state message for blocked periods
class _EmptyBlocksMessage extends StatelessWidget {
  final bool isDark;

  const _EmptyBlocksMessage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(DesignSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? DesignColors.surface.withOpacity(0.5)
                : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? DesignColors.borderSubtle
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
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 32,
                color: isDark
                    ? DesignColors.textMuted
                    : DesignColors.lightTextSecondary,
              ),
              const SizedBox(height: DesignSpacing.sm),
              Text(
                'No blocked periods',
                style: DesignTypography.bodyMedium.copyWith(
                  color: isDark
                      ? DesignColors.textSecondary
                      : DesignColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: DesignSpacing.xxs),
              Text(
                'Tap + to block time off',
                style: DesignTypography.bodySmall.copyWith(
                  color: isDark
                      ? DesignColors.textMuted
                      : DesignColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
