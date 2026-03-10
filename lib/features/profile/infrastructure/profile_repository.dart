import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/driver_profile.dart';

/// Profile repository - handles API calls for driver profile
class ProfileRepository {
  final DioClient _dioClient;

  ProfileRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get current driver profile
  Future<DriverProfile> getProfile() async {
    final response = await _dioClient.dio.get(ApiConfig.profile);
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, profile: {...} }
    final profileData = data['profile'] ?? data['driver'] ?? data;
    return DriverProfile.fromJson(profileData as Map<String, dynamic>);
  }

  /// Update driver profile
  Future<DriverProfile> updateProfile(ProfileUpdateRequest request) async {
    final response = await _dioClient.dio.put(
      ApiConfig.profile,
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, profile: {...} }
    final profileData = data['profile'] ?? data['driver'] ?? data;
    return DriverProfile.fromJson(profileData as Map<String, dynamic>);
  }
}
