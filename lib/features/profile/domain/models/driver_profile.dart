/// Tenant contact information for support
class TenantContact {
  final String? companyName;
  final String? supportEmail;
  final String? supportPhone;

  const TenantContact({
    this.companyName,
    this.supportEmail,
    this.supportPhone,
  });

  factory TenantContact.fromJson(Map<String, dynamic> json) {
    return TenantContact(
      companyName: json['companyName'] as String?,
      supportEmail: json['supportEmail'] as String?,
      supportPhone: json['supportPhone'] as String?,
    );
  }
}

/// Driver profile model with editable fields
class DriverProfile {
  final String driverId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final String? postcode;
  final String? city;
  final String? dateOfBirth;
  final String? nationalInsurance;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Profile photo URL (S3 presigned URL or CloudFront URL)
  final String? profilePhotoUrl;

  // DVLA Licence details (Phase 1 onboarding)
  final String? dvlaLicenceNumber;
  final String? dvlaCheckCode;
  final String? dvlaLicenceExpiry;

  // Tenant contact info (for status card and support)
  final TenantContact? tenant;

  const DriverProfile({
    required this.driverId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.postcode,
    this.city,
    this.dateOfBirth,
    this.nationalInsurance,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.profilePhotoUrl,
    this.dvlaLicenceNumber,
    this.dvlaCheckCode,
    this.dvlaLicenceExpiry,
    this.tenant,
  });

  String get fullName => '$firstName $lastName';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      driverId: json['driverId'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      postcode: json['postcode'] as String?,
      city: json['city'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      nationalInsurance: json['nationalInsurance'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      dvlaLicenceNumber: json['dvlaLicenceNumber'] as String?,
      dvlaCheckCode: json['dvlaCheckCode'] as String?,
      dvlaLicenceExpiry: json['dvlaLicenceExpiry'] as String?,
      tenant: json['tenant'] != null
          ? TenantContact.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (postcode != null) 'postcode': postcode,
      if (city != null) 'city': city,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (nationalInsurance != null) 'nationalInsurance': nationalInsurance,
      'status': status,
      if (dvlaLicenceNumber != null) 'dvlaLicenceNumber': dvlaLicenceNumber,
      if (dvlaCheckCode != null) 'dvlaCheckCode': dvlaCheckCode,
      if (dvlaLicenceExpiry != null) 'dvlaLicenceExpiry': dvlaLicenceExpiry,
    };
  }

  DriverProfile copyWith({
    String? driverId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? postcode,
    String? city,
    String? dateOfBirth,
    String? nationalInsurance,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePhotoUrl,
    String? dvlaLicenceNumber,
    String? dvlaCheckCode,
    String? dvlaLicenceExpiry,
    TenantContact? tenant,
  }) {
    return DriverProfile(
      driverId: driverId ?? this.driverId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationalInsurance: nationalInsurance ?? this.nationalInsurance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      dvlaLicenceNumber: dvlaLicenceNumber ?? this.dvlaLicenceNumber,
      dvlaCheckCode: dvlaCheckCode ?? this.dvlaCheckCode,
      dvlaLicenceExpiry: dvlaLicenceExpiry ?? this.dvlaLicenceExpiry,
      tenant: tenant ?? this.tenant,
    );
  }

  /// Check if DVLA licence details are complete (required for Phase 1)
  bool get hasDvlaDetails =>
      dvlaLicenceNumber != null &&
      dvlaLicenceNumber!.isNotEmpty &&
      dvlaCheckCode != null &&
      dvlaCheckCode!.isNotEmpty;
}

/// Profile update request - only includes editable fields
class ProfileUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String? postcode;
  final String? city;
  final String? dateOfBirth;
  final String? nationalInsurance;
  final String? dvlaLicenceNumber;
  final String? dvlaCheckCode;
  final String? dvlaLicenceExpiry;

  const ProfileUpdateRequest({
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.postcode,
    this.city,
    this.dateOfBirth,
    this.nationalInsurance,
    this.dvlaLicenceNumber,
    this.dvlaCheckCode,
    this.dvlaLicenceExpiry,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (phone != null) map['phone'] = phone;
    if (address != null) map['address'] = address;
    if (postcode != null) map['postcode'] = postcode;
    if (city != null) map['city'] = city;
    if (dateOfBirth != null) map['dateOfBirth'] = dateOfBirth;
    if (nationalInsurance != null) map['nationalInsurance'] = nationalInsurance;
    if (dvlaLicenceNumber != null) map['dvlaLicenceNumber'] = dvlaLicenceNumber;
    if (dvlaCheckCode != null) map['dvlaCheckCode'] = dvlaCheckCode;
    if (dvlaLicenceExpiry != null) map['dvlaLicenceExpiry'] = dvlaLicenceExpiry;
    return map;
  }
}
