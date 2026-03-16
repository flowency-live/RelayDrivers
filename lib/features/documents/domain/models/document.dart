/// Document types supported by the system
/// 3 required documents for drivers:
/// 1. PHV Driver Licence - driver specific, issued by local council
/// 2. PHV Vehicle Licence - per vehicle, issued by local council
/// 3. Hire & Reward Insurance - may cover multiple vehicles in one policy
enum DocumentType {
  phvDriverLicence('phv_driver_licence', 'PHV Driver Licence', 'driver'),
  phvVehicleLicence('phv_vehicle_licence', 'PHV Vehicle Licence', 'vehicle'),
  hireRewardInsurance('hire_reward_insurance', 'Hire & Reward Insurance', 'vehicle');

  final String apiValue;
  final String displayName;
  final String belongsTo;

  const DocumentType(this.apiValue, this.displayName, this.belongsTo);

  bool get isVehicleDocument => belongsTo == 'vehicle';

  /// Short description for each document type
  String get description {
    return switch (this) {
      DocumentType.phvDriverLicence =>
        'Your private hire driver licence issued by the local council',
      DocumentType.phvVehicleLicence =>
        'The vehicle licence plate/badge for this specific vehicle',
      DocumentType.hireRewardInsurance =>
        'Hire & Reward insurance covering your private hire work',
    };
  }

  /// Icon for each document type
  String get iconName {
    return switch (this) {
      DocumentType.phvDriverLicence => 'badge',
      DocumentType.phvVehicleLicence => 'directions_car',
      DocumentType.hireRewardInsurance => 'security',
    };
  }

  static DocumentType fromApiValue(String value) {
    // Handle both old and new API values for backwards compatibility
    final normalized = value.toLowerCase().replaceAll('-', '_');
    return DocumentType.values.firstWhere(
      (e) => e.apiValue == normalized ||
             // Legacy mappings
             (normalized == 'phv_driver_license' && e == DocumentType.phvDriverLicence) ||
             (normalized == 'driver_insurance' && e == DocumentType.hireRewardInsurance) ||
             (normalized == 'phv_vehicle_license' && e == DocumentType.phvVehicleLicence) ||
             (normalized == 'vehicle_insurance' && e == DocumentType.hireRewardInsurance),
      orElse: () => DocumentType.phvDriverLicence,
    );
  }
}

/// Document status
enum DocumentStatus {
  pendingReview('pending_review', 'Pending Review'),
  verified('verified', 'Verified'),
  rejected('rejected', 'Rejected'),
  expired('expired', 'Expired');

  final String apiValue;
  final String displayName;

  const DocumentStatus(this.apiValue, this.displayName);

  static DocumentStatus fromApiValue(String value) {
    return DocumentStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => DocumentStatus.pendingReview,
    );
  }
}

/// Driver document model
/// v4.0: Driver-owned architecture - documents are owned by driver and shared with operators
class DriverDocument {
  final String documentId;
  final DocumentType documentType;
  final String belongsTo;
  final String? vehicleVrn;
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? issueDate;
  final String expiryDate;
  final DocumentStatus status;
  final String? fileName;
  final String? verifiedBy;
  final String? verifiedAt;
  final String? rejectionReason;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  /// v4.0: List of operator IDs this document is shared with
  final List<String> sharedWith;

  const DriverDocument({
    required this.documentId,
    required this.documentType,
    required this.belongsTo,
    this.vehicleVrn,
    this.licenseNumber,
    this.issuingAuthority,
    this.issueDate,
    required this.expiryDate,
    required this.status,
    this.fileName,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.sharedWith = const [],
  });

  /// Check if document is shared with a specific operator
  bool isSharedWith(String operatorId) {
    return sharedWith.contains(operatorId);
  }

  /// Create a copy with updated sharedWith list
  DriverDocument copyWithSharedWith(List<String> newSharedWith) {
    return DriverDocument(
      documentId: documentId,
      documentType: documentType,
      belongsTo: belongsTo,
      vehicleVrn: vehicleVrn,
      licenseNumber: licenseNumber,
      issuingAuthority: issuingAuthority,
      issueDate: issueDate,
      expiryDate: expiryDate,
      status: status,
      fileName: fileName,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      rejectionReason: rejectionReason,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sharedWith: newSharedWith,
    );
  }

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    final docType = DocumentType.fromApiValue(json['documentType'] as String);

    // Parse sharedWith array (v4.0 driver-owned architecture)
    final sharedWithRaw = json['sharedWith'];
    final List<String> sharedWith = sharedWithRaw is List
        ? sharedWithRaw.map((e) => e.toString()).toList()
        : const [];

    return DriverDocument(
      documentId: json['documentId'] as String,
      documentType: docType,
      belongsTo: json['belongsTo'] as String? ?? docType.belongsTo,
      // Backend may use 'vrn' or 'vehicleVrn'
      vehicleVrn: json['vrn'] as String? ?? json['vehicleVrn'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      issuingAuthority: json['issuingAuthority'] as String?,
      issueDate: json['issueDate'] as String?,
      expiryDate: json['expiryDate'] as String? ?? '',
      status: DocumentStatus.fromApiValue(json['status'] as String? ?? 'pending_review'),
      fileName: json['fileName'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
      // Backend may use 'uploadedAt' or 'createdAt'
      createdAt: json['uploadedAt'] as String? ?? json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      sharedWith: sharedWith,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'documentType': documentType.apiValue,
      'belongsTo': belongsTo,
      if (vehicleVrn != null) 'vehicleVrn': vehicleVrn,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (issuingAuthority != null) 'issuingAuthority': issuingAuthority,
      if (issueDate != null) 'issueDate': issueDate,
      'expiryDate': expiryDate,
      'status': status.apiValue,
      if (fileName != null) 'fileName': fileName,
      if (verifiedBy != null) 'verifiedBy': verifiedBy,
      if (verifiedAt != null) 'verifiedAt': verifiedAt,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      'sharedWith': sharedWith,
    };
  }

  /// Check if document is expiring soon (within 30 days)
  bool get isExpiringSoon {
    try {
      final expiry = DateTime.parse(expiryDate);
      final daysUntilExpiry = expiry.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if document is expired
  bool get isExpired {
    try {
      final expiry = DateTime.parse(expiryDate);
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Days until expiry (negative if expired)
  int get daysUntilExpiry {
    try {
      final expiry = DateTime.parse(expiryDate);
      return expiry.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverDocument && other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.hashCode;
}

/// Request for uploading a new document
class DocumentUploadRequest {
  final DocumentType documentType;
  final String expiryDate;
  final String? vehicleVrn;
  final String? licenseNumber;
  final String? issuingAuthority;

  const DocumentUploadRequest({
    required this.documentType,
    required this.expiryDate,
    this.vehicleVrn,
    this.licenseNumber,
    this.issuingAuthority,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType.apiValue,
      'expiryDate': expiryDate,
      if (vehicleVrn != null) 'vehicleVrn': vehicleVrn,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (issuingAuthority != null) 'issuingAuthority': issuingAuthority,
    };
  }
}

/// Response from presigned URL request
/// Backend returns: { uploadUrl, documentId, expiresIn, s3Key, documentType, expiryDate, vehicleVrn }
class PresignedUrlResponse {
  final String uploadUrl;
  final String documentId;
  final int expiresIn;
  final String s3Key;
  final String documentType;
  final String expiryDate;
  final String? vehicleVrn;

  const PresignedUrlResponse({
    required this.uploadUrl,
    required this.documentId,
    required this.expiresIn,
    required this.s3Key,
    required this.documentType,
    required this.expiryDate,
    this.vehicleVrn,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      documentId: json['documentId'] as String,
      expiresIn: json['expiresIn'] as int,
      s3Key: json['s3Key'] as String,
      documentType: json['documentType'] as String,
      expiryDate: json['expiryDate'] as String,
      vehicleVrn: json['vehicleVrn'] as String?,
    );
  }
}
