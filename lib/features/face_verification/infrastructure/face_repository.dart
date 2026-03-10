import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/face_registration.dart';

/// Face verification repository - handles API calls for face registration and verification
class FaceRepository {
  final DioClient _dioClient;

  FaceRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get face verification status for the current driver
  Future<FaceStatus> getFaceStatus() async {
    final response = await _dioClient.dio.get(ApiConfig.faceStatus);
    final data = response.data as Map<String, dynamic>;
    return FaceStatus.fromJson(data);
  }

  /// Request presigned URL for face image upload
  Future<FaceUploadUrl> getUploadUrl({required String contentType}) async {
    final response = await _dioClient.dio.post(
      ApiConfig.faceUploadUrl,
      data: {'contentType': contentType},
    );
    final data = response.data as Map<String, dynamic>;
    return FaceUploadUrl.fromJson(data);
  }

  /// Upload face image to S3 using presigned URL
  Future<void> uploadImage({
    required String uploadUrl,
    required Uint8List imageBytes,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    // Use separate Dio instance for S3 upload (no auth headers)
    final s3Dio = Dio();
    await s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable([imageBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': imageBytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );
  }

  /// Register face after successful upload
  Future<FaceRegistration> registerFace({required String s3Key}) async {
    final response = await _dioClient.dio.post(
      ApiConfig.faceRegister,
      data: {'s3Key': s3Key},
    );
    final data = response.data as Map<String, dynamic>;
    return FaceRegistration.fromJson(data);
  }

  /// Verify face against registered reference
  Future<FaceVerificationResult> verifyFace({
    required String s3Key,
    double? confidenceThreshold,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConfig.faceVerify,
      data: {
        's3Key': s3Key,
        if (confidenceThreshold != null) 'confidenceThreshold': confidenceThreshold,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return FaceVerificationResult.fromJson(data);
  }

  /// Full face registration flow:
  /// 1. Get presigned URL
  /// 2. Upload to S3
  /// 3. Register face
  Future<FaceRegistration> registerFaceImage({
    required Uint8List imageBytes,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    // Step 1: Get presigned URL
    final uploadUrl = await getUploadUrl(contentType: contentType);

    // Step 2: Upload to S3
    await uploadImage(
      uploadUrl: uploadUrl.uploadUrl,
      imageBytes: imageBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Register face
    return await registerFace(s3Key: uploadUrl.s3Key);
  }

  /// Full face verification flow:
  /// 1. Get presigned URL
  /// 2. Upload to S3
  /// 3. Verify face
  Future<FaceVerificationResult> verifyFaceImage({
    required Uint8List imageBytes,
    required String contentType,
    double? confidenceThreshold,
    Function(double)? onProgress,
  }) async {
    // Step 1: Get presigned URL
    final uploadUrl = await getUploadUrl(contentType: contentType);

    // Step 2: Upload to S3
    await uploadImage(
      uploadUrl: uploadUrl.uploadUrl,
      imageBytes: imageBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Verify face
    return await verifyFace(
      s3Key: uploadUrl.s3Key,
      confidenceThreshold: confidenceThreshold,
    );
  }
}
