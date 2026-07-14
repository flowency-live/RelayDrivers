import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/earnings.dart';

/// Repository for GET /driver/earnings.
class EarningsRepository {
  final DioClient _dioClient;

  EarningsRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Fetch the earnings summary for an optional inclusive date range.
  /// [from]/[to] are YYYY-MM-DD; when omitted the backend picks a default.
  Future<EarningsSummary> getEarnings({String? from, String? to}) async {
    final response = await _dioClient.dio.get(
      ApiConfig.earnings,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return EarningsSummary.fromJson(data);
  }
}
