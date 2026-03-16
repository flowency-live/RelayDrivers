import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/driver_profile.dart';

/// Profile photo upload URL response
class ProfilePhotoUploadUrlResponse {
  final String uploadUrl;
  final String s3Key;
  final int expiresIn;

  ProfilePhotoUploadUrlResponse({
    required this.uploadUrl,
    required this.s3Key,
    required this.expiresIn,
  });

  factory ProfilePhotoUploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return ProfilePhotoUploadUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      s3Key: json['s3Key'] as String,
      expiresIn: json['expiresIn'] as int? ?? 300,
    );
  }
}

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

  /// Get presigned URL for profile photo upload
  Future<ProfilePhotoUploadUrlResponse> getProfilePhotoUploadUrl({
    required String contentType,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConfig.profilePhotoUploadUrl,
      data: {'contentType': contentType},
    );
    final data = response.data as Map<String, dynamic>;
    return ProfilePhotoUploadUrlResponse.fromJson(data);
  }

  /// Upload photo to S3 using presigned URL
  Future<void> uploadPhotoToS3({
    required String uploadUrl,
    required Uint8List photoBytes,
    required String contentType,
    void Function(double)? onProgress,
  }) async {
    // Use a plain Dio instance (no auth interceptors) for S3 upload
    final plainDio = Dio();
    await plainDio.put(
      uploadUrl,
      data: Stream.fromIterable([photoBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': photoBytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );
  }

  /// Save profile photo record after S3 upload
  Future<String> saveProfilePhoto({required String s3Key}) async {
    final response = await _dioClient.dio.post(
      ApiConfig.profilePhoto,
      data: {'s3Key': s3Key},
    );
    final data = response.data as Map<String, dynamic>;
    return data['profilePhotoUrl'] as String;
  }

  /// Upload profile photo (full flow: get URL, upload to S3, save record)
  Future<String?> uploadProfilePhoto({
    required Uint8List photoBytes,
    required String contentType,
    void Function(double)? onProgress,
  }) async {
    // Step 1: Get presigned URL
    final uploadUrlResponse = await getProfilePhotoUploadUrl(
      contentType: contentType,
    );

    // Step 2: Upload to S3
    await uploadPhotoToS3(
      uploadUrl: uploadUrlResponse.uploadUrl,
      photoBytes: photoBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Save record and get public URL
    final profilePhotoUrl = await saveProfilePhoto(s3Key: uploadUrlResponse.s3Key);
    return profilePhotoUrl;
  }
}
