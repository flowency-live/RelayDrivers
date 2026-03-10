import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/document.dart';

/// Document repository - handles API calls for driver documents
class DocumentRepository {
  final DioClient _dioClient;

  DocumentRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get all documents for the current driver
  Future<List<DriverDocument>> getDocuments() async {
    final response = await _dioClient.dio.get(ApiConfig.documents);
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, documents: [...] }
    final documentsData = data['documents'] as List<dynamic>? ?? [];
    return documentsData
        .map((d) => DriverDocument.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// Request presigned URL for document upload
  /// Backend: POST /v2/driver/documents/upload-url
  Future<PresignedUrlResponse> getPresignedUrl({
    required DocumentUploadRequest request,
    required String contentType,
    required String fileName,
  }) async {
    final response = await _dioClient.dio.post(
      '${ApiConfig.documents}/upload-url',
      data: {
        'documentType': request.documentType.apiValue,
        'expiryDate': request.expiryDate,
        'vehicleVrn': request.vehicleVrn,
        'contentType': contentType,
        'fileName': fileName,
        'licenseNumber': request.licenseNumber,
        'issuingAuthority': request.issuingAuthority,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return PresignedUrlResponse.fromJson(data);
  }

  /// Upload file to presigned URL (direct to S3)
  Future<void> uploadFile({
    required String uploadUrl,
    required Uint8List fileBytes,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    // Use a separate Dio instance for S3 upload (no auth headers)
    final s3Dio = Dio();
    await s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );
  }

  /// Create document record after successful upload
  /// Backend: POST /v2/driver/documents
  Future<DriverDocument> createDocument({
    required String documentId,
    required String documentType,
    required String expiryDate,
    required String s3Key,
    String? vehicleVrn,
    String? licenseNumber,
    String? issuingAuthority,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConfig.documents,
      data: {
        'documentId': documentId,
        'documentType': documentType,
        'expiryDate': expiryDate,
        's3Key': s3Key,
        'vehicleVrn': vehicleVrn,
        'licenseNumber': licenseNumber,
        'issuingAuthority': issuingAuthority,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final documentData = data['document'] as Map<String, dynamic>;
    return DriverDocument.fromJson(documentData);
  }

  /// Delete a document
  /// Backend: DELETE /v2/driver/documents/{documentId}
  Future<void> deleteDocument(String documentId) async {
    await _dioClient.dio.delete('${ApiConfig.documents}/$documentId');
  }

  /// Full document upload flow:
  /// 1. Get presigned URL
  /// 2. Upload to S3
  /// 3. Create document record
  Future<DriverDocument> uploadDocument({
    required DocumentUploadRequest request,
    required Uint8List fileBytes,
    required String fileName,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    // Step 1: Get presigned URL from backend
    final presignedResponse = await getPresignedUrl(
      request: request,
      contentType: contentType,
      fileName: fileName,
    );

    // Step 2: Upload file directly to S3
    await uploadFile(
      uploadUrl: presignedResponse.uploadUrl,
      fileBytes: fileBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Step 3: Create document record in database
    final document = await createDocument(
      documentId: presignedResponse.documentId,
      documentType: request.documentType.apiValue,
      expiryDate: request.expiryDate,
      s3Key: presignedResponse.s3Key,
      vehicleVrn: request.vehicleVrn,
      licenseNumber: request.licenseNumber,
      issuingAuthority: request.issuingAuthority,
    );

    return document;
  }
}
