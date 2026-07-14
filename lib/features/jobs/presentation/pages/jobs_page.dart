import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/router/app_router.dart';
import '../../application/jobs_providers.dart';
import '../../domain/models/job.dart';
import '../widgets/job_list_card.dart';

/// Bookings screen: the driver's jobs grouped into Offered, Active and
/// Completed sections. Replaces the former placeholder page.
class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(jobsStateProvider.notifier).loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobsStateProvider);
    final offered = ref.watch(offeredJobsProvider);
    final active = ref.watch(activeJobsProvider);
    final completed = ref.watch(completedJobsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Bookings'),
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          JobsInitial() || JobsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          JobsError(:final message) => _ErrorView(
              message: message,
              onRetry: () => ref.read(jobsStateProvider.notifier).loadJobs(),
            ),
          JobsLoaded() => RefreshIndicator(
              onRefresh: () => ref.read(jobsStateProvider.notifier).refresh(),
              child: (offered.isEmpty && active.isEmpty && completed.isEmpty)
                  ? _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(DesignSpacing.lg),
                      children: [
                        if (offered.isNotEmpty)
                          _JobSection(
                            title: 'New offers',
                            jobs: offered,
                            onTapJob: _openJob,
                          ),
                        if (active.isNotEmpty)
                          _JobSection(
                            title: 'Active',
                            jobs: active,
                            onTapJob: _openJob,
                          ),
                        if (completed.isNotEmpty)
                          _JobSection(
                            title: 'Completed',
                            jobs: completed,
                            onTapJob: _openJob,
                          ),
                      ],
                    ),
            ),
        },
      ),
    );
  }

  void _openJob(Job job) {
    context.push(AppRoutes.bookingDetailRoute(job.jobId));
  }
}

class _JobSection extends StatelessWidget {
  final String title;
  final List<Job> jobs;
  final void Function(Job) onTapJob;

  const _JobSection({
    required this.title,
    required this.jobs,
    required this.onTapJob,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignSpacing.md),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: DesignTypography.sectionHeader.copyWith(
                  color: isDark
                      ? DesignColors.textMuted
                      : DesignColors.lightTextMuted,
                ),
              ),
              const SizedBox(width: DesignSpacing.xs),
              Text(
                '(${jobs.length})',
                style: DesignTypography.sectionHeader.copyWith(
                  color: isDark
                      ? DesignColors.textMuted
                      : DesignColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
        ...jobs.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: DesignSpacing.sm),
            child: JobListCard(job: job, onTap: () => onTapJob(job)),
          ),
        ),
        const SizedBox(height: DesignSpacing.lg),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Wrap in a scroll view so pull-to-refresh works with an empty list.
    return ListView(
      children: [
        const SizedBox(height: DesignSpacing.massive),
        Icon(
          Icons.assignment_outlined,
          size: 64,
          color: isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
        ),
        const SizedBox(height: DesignSpacing.md),
        Center(
          child: Text(
            'No bookings yet',
            style: DesignTypography.bodyMedium.copyWith(
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(height: DesignSpacing.xs),
        Center(
          child: Text(
            'New job offers will appear here',
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: DesignSpacing.md),
            Text('Failed to load bookings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: DesignSpacing.xs),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: DesignSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
