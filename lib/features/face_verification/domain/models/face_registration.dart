/// Face registration status and verification models

/// Face registration status from backend
class FaceRegistration {
  final String faceId;
  final double confidence;
  final String status;
  final DateTime registeredAt;

  FaceRegistration({
    required this.faceId,
    required this.confidence,
    required this.status,
    required this.registeredAt,
  });

  factory FaceRegistration.fromJson(Map<String, dynamic> json) {
    return FaceRegistration(
      faceId: json['faceId'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      status: json['status'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }

  bool get isActive => status == 'active';
}

/// Face verification result from backend
class FaceVerificationResult {
  final bool verified;
  final double confidence;
  final DateTime verifiedAt;

  FaceVerificationResult({
    required this.verified,
    required this.confidence,
    required this.verifiedAt,
  });

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    return FaceVerificationResult(
      verified: json['verified'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
    );
  }
}

/// Face status response combining registration status and driver verification state
class FaceStatus {
  final bool hasRegisteredFace;
  final FaceRegistration? registration;
  final bool faceVerified;
  final DateTime? faceVerifiedAt;

  FaceStatus({
    required this.hasRegisteredFace,
    this.registration,
    required this.faceVerified,
    this.faceVerifiedAt,
  });

  factory FaceStatus.fromJson(Map<String, dynamic> json) {
    return FaceStatus(
      hasRegisteredFace: json['hasRegisteredFace'] as bool? ?? false,
      registration: json['registration'] != null
          ? FaceRegistration.fromJson(json['registration'] as Map<String, dynamic>)
          : null,
      faceVerified: json['faceVerified'] as bool? ?? false,
      faceVerifiedAt: json['faceVerifiedAt'] != null
          ? DateTime.parse(json['faceVerifiedAt'] as String)
          : null,
    );
  }
}

/// Presigned URL response for face image upload
class FaceUploadUrl {
  final String uploadUrl;
  final String s3Key;

  FaceUploadUrl({
    required this.uploadUrl,
    required this.s3Key,
  });

  factory FaceUploadUrl.fromJson(Map<String, dynamic> json) {
    return FaceUploadUrl(
      uploadUrl: json['uploadUrl'] as String,
      s3Key: json['s3Key'] as String,
    );
  }
}
