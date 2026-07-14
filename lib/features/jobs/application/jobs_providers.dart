import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/job.dart';
import '../infrastructure/jobs_repository.dart';
import '../../../core/services/location_service.dart';

/// Jobs repository provider.
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return JobsRepository(dioClient: dioClient);
});

/// Jobs list state.
sealed class JobsState {
  const JobsState();
}

class JobsInitial extends JobsState {
  const JobsInitial();
}

class JobsLoading extends JobsState {
  const JobsLoading();
}

class JobsLoaded extends JobsState {
  final List<Job> jobs;
  const JobsLoaded(this.jobs);
}

class JobsError extends JobsState {
  final String message;
  const JobsError(this.message);
}

/// Result of a job lifecycle action (accept/decline/advance). Carries either
/// the updated job or a user-facing error message, without disturbing the
/// loaded list state.
class JobActionResult {
  final Job? job;
  final String? error;

  const JobActionResult._({this.job, this.error});

  factory JobActionResult.success(Job job) => JobActionResult._(job: job);
  factory JobActionResult.failure(String error) =>
      JobActionResult._(error: error);

  bool get isSuccess => error == null;
}

/// Notifier owning the driver's job list and lifecycle actions.
class JobsNotifier extends StateNotifier<JobsState> {
  final JobsRepository _repository;
  final Ref _ref;

  JobsNotifier({required JobsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const JobsInitial());

  /// Load jobs from the API (full-screen loading state).
  Future<void> loadJobs() async {
    state = const JobsLoading();
    try {
      final jobs = await _repository.getJobs();
      state = JobsLoaded(jobs);
      _syncLocationTracking(jobs);
    } catch (e) {
      state = JobsError(_parseError(e));
    }
  }

  /// Refresh jobs without dropping the current list (used by pull-to-refresh
  /// and by push-notification handlers on a new-job message).
  Future<void> refresh() async {
    try {
      final jobs = await _repository.getJobs();
      state = JobsLoaded(jobs);
      _syncLocationTracking(jobs);
    } catch (_) {
      // Keep the current state on a background refresh failure.
    }
  }

  /// Accept an offered job.
  Future<JobActionResult> acceptJob(String jobId) async {
    return _mutate(() => _repository.acceptJob(jobId));
  }

  /// Decline an offered job.
  Future<JobActionResult> declineJob(String jobId) async {
    return _mutate(() => _repository.declineJob(jobId));
  }

  /// Advance a job to its next lifecycle status. Rejects illegal transitions
  /// client-side before hitting the API (which also enforces this with 409).
  Future<JobActionResult> advanceStatus(
      String jobId, DriverJobStatus target) async {
    final current = jobById(jobId);
    if (current != null && !current.status.canAdvanceTo(target)) {
      return JobActionResult.failure(
        'Illegal transition ${current.status.apiValue} -> ${target.apiValue}',
      );
    }
    return _mutate(() => _repository.updateStatus(jobId, target));
  }

  /// Run an action that returns an updated job, merge it into the list, and
  /// re-sync location tracking. On failure the loaded list is preserved and
  /// the error is returned to the caller (not dumped into [state]).
  Future<JobActionResult> _mutate(Future<Job> Function() action) async {
    try {
      final updated = await action();
      final currentJobs = _currentJobs();
      final index = currentJobs.indexWhere((j) => j.jobId == updated.jobId);
      final merged = [...currentJobs];
      if (index >= 0) {
        merged[index] = updated;
      } else {
        merged.add(updated);
      }
      state = JobsLoaded(merged);
      _syncLocationTracking(merged);
      return JobActionResult.success(updated);
    } catch (e) {
      return JobActionResult.failure(_parseError(e));
    }
  }

  List<Job> _currentJobs() {
    final s = state;
    return s is JobsLoaded ? s.jobs : const [];
  }

  Job? jobById(String jobId) {
    for (final job in _currentJobs()) {
      if (job.jobId == jobId) return job;
    }
    return null;
  }

  /// Start/stop live location tracking based on whether any job is currently
  /// in a status that requires it (en_route / arrived).
  void _syncLocationTracking(List<Job> jobs) {
    Job? trackable;
    for (final job in jobs) {
      if (job.status.requiresLocationTracking) {
        trackable = job;
        break;
      }
    }
    final controller = _ref.read(locationTrackingProvider);
    if (trackable != null) {
      controller.startForJob(trackable.jobId);
    } else {
      controller.stop();
    }
  }

  /// Parse an error into a user-facing message, surfacing 409 illegal-transition
  /// and 404 not-found responses from the driver-jobs API.
  String _parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      final code = error.response?.statusCode;
      if (code == 401) return 'Your session has expired. Please sign in again.';
    }
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Jobs state provider.
final jobsStateProvider =
    StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final repository = ref.watch(jobsRepositoryProvider);
  return JobsNotifier(repository: repository, ref: ref);
});

/// Convenience provider for the full job list.
final jobsListProvider = Provider<List<Job>>((ref) {
  final state = ref.watch(jobsStateProvider);
  return state is JobsLoaded ? state.jobs : const [];
});

/// Offered jobs awaiting accept/decline.
final offeredJobsProvider = Provider<List<Job>>((ref) {
  return ref
      .watch(jobsListProvider)
      .where((j) => j.status == DriverJobStatus.offered)
      .toList();
});

/// Active (accepted/en_route/arrived/picked_up) jobs, in-progress first.
final activeJobsProvider = Provider<List<Job>>((ref) {
  return ref.watch(jobsListProvider).where((j) => j.status.isActive).toList();
});

/// Completed jobs.
final completedJobsProvider = Provider<List<Job>>((ref) {
  return ref
      .watch(jobsListProvider)
      .where((j) => j.status == DriverJobStatus.completed)
      .toList();
});

/// The single most relevant current job for the home screen: the active job
/// furthest through the lifecycle, else the soonest offered job.
final currentJobProvider = Provider<Job?>((ref) {
  final active = ref.watch(activeJobsProvider);
  if (active.isNotEmpty) {
    final sorted = [...active]
      ..sort((a, b) => b.status.index.compareTo(a.status.index));
    return sorted.first;
  }
  final offered = ref.watch(offeredJobsProvider);
  if (offered.isEmpty) return null;
  final sorted = [...offered]..sort((a, b) {
      final at = a.scheduledDateTime;
      final bt = b.scheduledDateTime;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });
  return sorted.first;
});

/// Look up a single job by id from the loaded list.
final jobByIdProvider = Provider.family<Job?, String>((ref, jobId) {
  final jobs = ref.watch(jobsListProvider);
  for (final job in jobs) {
    if (job.jobId == jobId) return job;
  }
  return null;
});
