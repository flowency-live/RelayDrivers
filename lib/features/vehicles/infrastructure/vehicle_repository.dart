import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/vehicle.dart';

/// Vehicle repository - handles API calls for driver vehicles
class VehicleRepository {
  final DioClient _dioClient;

  VehicleRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get all vehicles for the current driver
  Future<List<Vehicle>> getVehicles() async {
    final response = await _dioClient.dio.get(ApiConfig.vehicles);
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, vehicles: [...] }
    final vehiclesData = data['vehicles'] as List<dynamic>? ?? [];
    return vehiclesData
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  /// Lookup vehicle by VRN (DVLA check without adding)
  Future<DvlaLookupResult> lookupVehicle(String vrn) async {
    final response = await _dioClient.dio.get(
      '${ApiConfig.vehicles}/lookup/$vrn',
    );
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, vehicle: {...} }
    final vehicleData = data['vehicle'] as Map<String, dynamic>;
    return DvlaLookupResult.fromJson(vehicleData);
  }

  /// Add a vehicle by VRN (performs DVLA lookup and adds)
  Future<Vehicle> addVehicle(String vrn) async {
    final response = await _dioClient.dio.post(
      ApiConfig.vehicles,
      data: {'vrn': vrn.toUpperCase().replaceAll(' ', '')},
    );
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, vehicle: {...} }
    final vehicleData = data['vehicle'] as Map<String, dynamic>;
    return Vehicle.fromJson(vehicleData);
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vrn) async {
    await _dioClient.dio.delete('${ApiConfig.vehicles}/$vrn');
  }

  /// Refresh DVLA data for a vehicle
  Future<Vehicle> refreshVehicle(String vrn) async {
    final response = await _dioClient.dio.post(
      '${ApiConfig.vehicles}/$vrn/refresh',
    );
    final data = response.data as Map<String, dynamic>;
    final vehicleData = data['vehicle'] as Map<String, dynamic>;
    return Vehicle.fromJson(vehicleData);
  }

  // ============================================================================
  // Vehicle Photos
  // ============================================================================

  /// Get presigned URL for vehicle photo upload
  Future<VehiclePhotoUploadUrl> getPhotoUploadUrl({
    required String vrn,
    required VehiclePhotoType photoType,
    required String contentType,
  }) async {
    final response = await _dioClient.dio.post(
      '${ApiConfig.vehicles}/$vrn/photos/upload-url',
      data: {
        'photoType': photoType.value,
        'contentType': contentType,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return VehiclePhotoUploadUrl.fromJson(data);
  }

  /// Upload photo bytes to presigned URL (direct to S3)
  Future<void> uploadPhotoToS3({
    required String uploadUrl,
    required Uint8List photoBytes,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    final s3Dio = Dio();
    await s3Dio.put(
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

  /// Create vehicle photo record after upload
  Future<VehiclePhoto> addVehiclePhoto({
    required String vrn,
    required String photoId,
    required VehiclePhotoType photoType,
    required String s3Key,
  }) async {
    final response = await _dioClient.dio.post(
      '${ApiConfig.vehicles}/$vrn/photos',
      data: {
        'photoId': photoId,
        'photoType': photoType.value,
        's3Key': s3Key,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final photoData = data['photo'] as Map<String, dynamic>;
    return VehiclePhoto.fromJson(photoData);
  }

  /// Get all photos for a vehicle
  Future<List<VehiclePhoto>> getVehiclePhotos(String vrn) async {
    final response = await _dioClient.dio.get(
      '${ApiConfig.vehicles}/$vrn/photos',
    );
    final data = response.data as Map<String, dynamic>;
    final photosData = data['photos'] as List<dynamic>? ?? [];
    return photosData
        .map((p) => VehiclePhoto.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Delete a vehicle photo
  Future<void> deleteVehiclePhoto({
    required String vrn,
    required String photoId,
  }) async {
    await _dioClient.dio.delete('${ApiConfig.vehicles}/$vrn/photos/$photoId');
  }

  /// Full photo upload flow:
  /// 1. Get presigned URL
  /// 2. Upload to S3
  /// 3. Create photo record
  Future<VehiclePhoto> uploadVehiclePhoto({
    required String vrn,
    required VehiclePhotoType photoType,
    required Uint8List photoBytes,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    // Step 1: Get presigned URL
    final uploadUrl = await getPhotoUploadUrl(
      vrn: vrn,
      photoType: photoType,
      contentType: contentType,
    );

    // Step 2: Upload to S3
    await uploadPhotoToS3(
      uploadUrl: uploadUrl.uploadUrl,
      photoBytes: photoBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Create photo record
    final photo = await addVehiclePhoto(
      vrn: vrn,
      photoId: uploadUrl.photoId,
      photoType: photoType,
      s3Key: uploadUrl.s3Key,
    );

    return photo;
  }
}

/// Response from photo upload URL endpoint
class VehiclePhotoUploadUrl {
  final String uploadUrl;
  final String photoId;
  final String s3Key;
  final String photoType;
  final int expiresIn;

  const VehiclePhotoUploadUrl({
    required this.uploadUrl,
    required this.photoId,
    required this.s3Key,
    required this.photoType,
    required this.expiresIn,
  });

  factory VehiclePhotoUploadUrl.fromJson(Map<String, dynamic> json) {
    return VehiclePhotoUploadUrl(
      uploadUrl: json['uploadUrl'] as String,
      photoId: json['photoId'] as String,
      s3Key: json['s3Key'] as String,
      photoType: json['photoType'] as String,
      expiresIn: json['expiresIn'] as int? ?? 300,
    );
  }
}
