import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/job.dart';

/// Repository for the driver-jobs API (jobs list, accept/decline, status
/// advance). Uses the shared [DioClient] so the JWT + X-Tenant-Id interceptor
/// and token refresh apply automatically.
class JobsRepository {
  final DioClient _dioClient;

  JobsRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// GET /driver/jobs - list jobs offered/assigned to the driver.
  /// [status] optionally filters server-side; [limit] 1..200.
  Future<List<Job>> getJobs({DriverJobStatus? status, int limit = 100}) async {
    final response = await _dioClient.dio.get(
      ApiConfig.jobs,
      queryParameters: {
        if (status != null) 'status': status.apiValue,
        'limit': limit,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final jobsData = data['jobs'] as List<dynamic>? ?? [];
    return jobsData
        .map((j) => Job.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// POST /driver/jobs/{id}/accept - accept an offered job.
  Future<Job> acceptJob(String jobId) async {
    final response = await _dioClient.dio.post(ApiConfig.jobAccept(jobId));
    return _jobFromResponse(response);
  }

  /// POST /driver/jobs/{id}/decline - decline an offered job.
  Future<Job> declineJob(String jobId) async {
    final response = await _dioClient.dio.post(ApiConfig.jobDecline(jobId));
    return _jobFromResponse(response);
  }

  /// POST /driver/jobs/{id}/status - advance through the state machine.
  ///
  /// [target] must be one of en_route|arrived|picked_up|completed. Illegal
  /// transitions are rejected server-side with 409; callers should also guard
  /// with [DriverJobStatus.canAdvanceTo] before invoking.
  Future<Job> updateStatus(String jobId, DriverJobStatus target) async {
    final response = await _dioClient.dio.post(
      ApiConfig.jobStatus(jobId),
      data: {'status': target.apiValue},
    );
    return _jobFromResponse(response);
  }

  Job _jobFromResponse(Response<dynamic> response) {
    final data = response.data as Map<String, dynamic>;
    final jobData = data['job'] as Map<String, dynamic>;
    return Job.fromJson(jobData);
  }
}
