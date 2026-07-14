import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/utils/currency.dart';
import '../../application/earnings_providers.dart';
import '../../domain/models/earnings.dart';

/// Earnings screen: range selector, summary, and per-job breakdown.
class EarningsPage extends ConsumerStatefulWidget {
  const EarningsPage({super.key});

  @override
  ConsumerState<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends ConsumerState<EarningsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final range = ref.read(earningsRangeProvider);
      ref.read(earningsStateProvider.notifier).load(range);
    });
  }

  void _selectRange(EarningsRange range) {
    ref.read(earningsRangeProvider.notifier).state = range;
    ref.read(earningsStateProvider.notifier).load(range);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningsStateProvider);
    final selectedRange = ref.watch(earningsRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(earningsStateProvider.notifier).load(selectedRange),
          child: ListView(
            padding: const EdgeInsets.all(DesignSpacing.lg),
            children: [
              _RangeSelector(
                selected: selectedRange,
                onSelect: _selectRange,
                isDark: isDark,
              ),
              const SizedBox(height: DesignSpacing.lg),
              switch (state) {
                EarningsInitial() || EarningsLoading() => const Padding(
                    padding: EdgeInsets.only(top: DesignSpacing.huge),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                EarningsErrorState(:final message) => _ErrorView(
                    message: message,
                    onRetry: () => ref
                        .read(earningsStateProvider.notifier)
                        .load(selectedRange),
                  ),
                EarningsLoaded(:final summary) =>
                  _EarningsContent(summary: summary, isDark: isDark),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final EarningsRange selected;
  final ValueChanged<EarningsRange> onSelect;
  final bool isDark;

  const _RangeSelector({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignSpacing.sm,
      runSpacing: DesignSpacing.sm,
      children: EarningsRange.values.map((range) {
        final isSelected = range == selected;
        return GestureDetector(
          onTap: () => onSelect(range),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpacing.md,
              vertical: DesignSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? DesignColors.accent
                  : (isDark
                      ? DesignColors.surface.withOpacity(0.5)
                      : DesignColors.lightSurface),
              borderRadius: BorderRadius.circular(DesignRadii.badge),
              border: Border.all(
                color: isSelected
                    ? DesignColors.accent
                    : (isDark
                        ? DesignColors.borderSubtle
                        : DesignColors.lightBorderSubtle),
                width: 1,
              ),
            ),
            child: Text(
              range.label,
              style: DesignTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? DesignColors.textSecondary
                        : DesignColors.lightTextSecondary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EarningsContent extends StatelessWidget {
  final EarningsSummary summary;
  final bool isDark;

  const _EarningsContent({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(summary: summary, isDark: isDark),
        const SizedBox(height: DesignSpacing.xl),
        Text(
          'Completed jobs',
          style: DesignTypography.sectionHeader.copyWith(
            color:
                isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: DesignSpacing.md),
        if (summary.jobs.isEmpty)
          _EmptyBreakdown(isDark: isDark)
        else
          ...summary.jobs.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: DesignSpacing.sm),
              child: _JobEarningsRow(job: job, isDark: isDark),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final EarningsSummary summary;
  final bool isDark;

  const _SummaryCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.glassBackground : DesignColors.lightSurface,
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
          Text(
            'Gross earnings',
            style: DesignTypography.sectionHeader.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: DesignSpacing.xs),
          Text(
            Currency.formatPence(summary.grossEarnings),
            style: DesignTypography.statLarge.copyWith(
              color: isDark
                  ? DesignColors.textPrimary
                  : DesignColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: DesignSpacing.xs),
          Text(
            '${summary.completedJobs} of ${summary.totalJobs} job'
            '${summary.totalJobs == 1 ? '' : 's'} completed',
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: DesignSpacing.lg),
          Divider(
            height: 1,
            color: isDark
                ? DesignColors.borderSubtle
                : DesignColors.lightBorderSubtle,
          ),
          const SizedBox(height: DesignSpacing.md),
          _SummaryRow(
            label: 'Base fares',
            value: Currency.formatPence(summary.baseFares),
            isDark: isDark,
          ),
          const SizedBox(height: DesignSpacing.sm),
          _SummaryRow(
            label: 'Reimbursements',
            value: Currency.formatPence(summary.reimbursements),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
            color: isDark
                ? DesignColors.textPrimary
                : DesignColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _JobEarningsRow extends StatelessWidget {
  final EarningsJob job;
  final bool isDark;

  const _JobEarningsRow({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? DesignColors.surface.withOpacity(0.5)
            : DesignColors.lightSurface,
        borderRadius: BorderRadius.circular(DesignRadii.cardCompact),
        border: Border.all(
          color: isDark
              ? DesignColors.borderSubtle
              : DesignColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobId,
                  style: DesignTypography.titleSmall.copyWith(
                    color: isDark
                        ? DesignColors.textPrimary
                        : DesignColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.date}  -  fare ${Currency.formatPence(job.baseFare)}'
                  '${job.charges > 0 ? ' + ${Currency.formatPence(job.charges)}' : ''}',
                  style: DesignTypography.bodySmall.copyWith(
                    color: isDark
                        ? DesignColors.textSecondary
                        : DesignColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Currency.formatPence(job.total),
            style: DesignTypography.bodyMedium.copyWith(
              color: isDark
                  ? DesignColors.textPrimary
                  : DesignColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBreakdown extends StatelessWidget {
  final bool isDark;

  const _EmptyBreakdown({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Icons.receipt_long_outlined,
            size: 40,
            color:
                isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
          ),
          const SizedBox(height: DesignSpacing.md),
          Text(
            'No completed jobs in this period',
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignSpacing.huge),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DesignSpacing.md),
          Text('Failed to load earnings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DesignSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: DesignSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
