import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/components/route/route_timeline.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/currency.dart';
import '../../application/jobs_providers.dart';
import '../../domain/models/job.dart';
import '../widgets/job_list_card.dart';
import '../widgets/job_status_badge.dart';

/// Job detail: full route, fare, notes, and the lifecycle controls
/// (accept/decline for offered jobs; status advance for active jobs) driven by
/// the same state machine the backend enforces.
class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // If the list hasn't been loaded yet (e.g. arriving via deep link/push),
    // load it so this job resolves.
    Future.microtask(() {
      if (ref.read(jobByIdProvider(widget.jobId)) == null) {
        ref.read(jobsStateProvider.notifier).loadJobs();
      }
    });
  }

  Future<void> _run(Future<JobActionResult> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Action failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(jobByIdProvider(widget.jobId));
    final jobsState = ref.watch(jobsStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Job details'),
      ),
      body: SafeArea(
        top: false,
        child: job == null
            ? _resolvePlaceholder(jobsState)
            : ListView(
                padding: const EdgeInsets.all(DesignSpacing.lg),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.bookingId ?? job.jobId,
                          style: DesignTypography.headlineSmall.copyWith(
                            color: isDark
                                ? DesignColors.textPrimary
                                : DesignColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      JobStatusBadge(status: job.status),
                    ],
                  ),
                  const SizedBox(height: DesignSpacing.lg),
                  _Card(
                    isDark: isDark,
                    child: RouteTimeline(
                      pickupAddress: job.pickupAddress,
                      pickupTime: formatScheduledTime(job.scheduledDateTime),
                      dropoffAddress: job.dropoffAddress,
                      dropoffTime: 'Destination',
                    ),
                  ),
                  const SizedBox(height: DesignSpacing.md),
                  _DetailRow(
                    label: 'Fare',
                    value: Currency.formatPence(job.fare),
                    isDark: isDark,
                  ),
                  if (job.vehicleType != null)
                    _DetailRow(
                      label: 'Vehicle',
                      value: job.vehicleType!,
                      isDark: isDark,
                    ),
                  if (job.notes != null && job.notes!.isNotEmpty)
                    _DetailRow(
                      label: 'Notes',
                      value: job.notes!,
                      isDark: isDark,
                    ),
                  if (job.status.requiresLocationTracking &&
                      locationTrackingSupported) ...[
                    const SizedBox(height: DesignSpacing.md),
                    _LocationBanner(isDark: isDark),
                  ],
                  const SizedBox(height: DesignSpacing.xl),
                  _Actions(job: job, busy: _busy, onRun: _run),
                ],
              ),
      ),
    );
  }

  Widget _resolvePlaceholder(JobsState state) {
    if (state is JobsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: DesignSpacing.md),
              Text(state.message, textAlign: TextAlign.center),
              const SizedBox(height: DesignSpacing.lg),
              FilledButton(
                onPressed: () =>
                    ref.read(jobsStateProvider.notifier).loadJobs(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _Actions extends ConsumerWidget {
  final Job job;
  final bool busy;
  final Future<void> Function(Future<JobActionResult> Function()) onRun;

  const _Actions({required this.job, required this.busy, required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(jobsStateProvider.notifier);

    if (busy) {
      return const Center(child: CircularProgressIndicator());
    }

    // Offered: accept or decline.
    if (job.status == DriverJobStatus.offered) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onRun(() => notifier.declineJob(job.jobId)),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignColors.danger,
                padding:
                    const EdgeInsets.symmetric(vertical: DesignSpacing.md),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: DesignSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: () => onRun(() => notifier.acceptJob(job.jobId)),
              style: FilledButton.styleFrom(
                backgroundColor: DesignColors.accent,
                padding:
                    const EdgeInsets.symmetric(vertical: DesignSpacing.md),
              ),
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    }

    // Active: advance through the state machine one step at a time.
    final next = job.status.nextStatus;
    if (job.status.isActive && next != null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () =>
              onRun(() => notifier.advanceStatus(job.jobId, next)),
          style: FilledButton.styleFrom(
            backgroundColor: DesignColors.accent,
            padding: const EdgeInsets.symmetric(vertical: DesignSpacing.md),
          ),
          child: Text(job.status.advanceLabel ?? 'Continue'),
        ),
      );
    }

    // Terminal: nothing to do.
    return Center(
      child: Text(
        'This job is ${job.status.displayName.toLowerCase()}.',
        style: DesignTypography.bodySmall,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: DesignTypography.bodySmall.copyWith(
                color: isDark
                    ? DesignColors.textMuted
                    : DesignColors.lightTextMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DesignTypography.bodyMedium.copyWith(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final bool isDark;

  const _LocationBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSpacing.md),
      decoration: BoxDecoration(
        color: DesignColors.info.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DesignRadii.cardCompact),
        border: Border.all(color: DesignColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, size: 18, color: DesignColors.info),
          const SizedBox(width: DesignSpacing.sm),
          Expanded(
            child: Text(
              'Sharing your live location for this job',
              style: DesignTypography.bodySmall.copyWith(
                color: DesignColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
