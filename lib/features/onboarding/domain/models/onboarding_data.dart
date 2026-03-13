import '../services/dvla_licence_service.dart';

/// Onboarding wizard data model
/// Holds all data collected during the onboarding wizard
class OnboardingData {
  // Phase 1 Step 1: Personal Details
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final Gender? gender;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? postcode;

  // Phase 1 Step 2: UK Driving Licence
  final String? dvlaLicenceNumber;
  final String? dvlaCheckCode;
  final String? dvlaLicenceExpiry;

  // Phase 1 Step 3: PHV Driver Licence
  final String? phvDriverLicenceNumber;
  final String? phvDriverLicenceAuthority;
  final String? phvDriverLicenceExpiry;
  final String? phvDriverLicencePhotoPath;
  final bool phvDriverLicenceUploaded;

  // Phase 2 Step 1: Vehicle
  final String? vehicleVrn;
  final String? vehicleMake;
  final String? vehicleColour;
  final String? vehicleMotStatus;
  final String? vehicleTaxStatus;

  // Phase 2 Step 2: PHV Vehicle Licence
  final String? phvVehicleLicenceNumber;
  final String? phvVehicleLicenceExpiry;
  final String? phvVehicleLicencePhotoPath;
  final bool phvVehicleLicenceUploaded;

  // Phase 2 Step 3: Insurance
  final String? insurancePolicyNumber;
  final String? insuranceExpiry;
  final String? insurancePhotoPath;
  final bool insuranceUploaded;

  // Phase 3: Face Verification
  final bool faceVerified;

  const OnboardingData({
    this.firstName,
    this.lastName,
    this.middleName,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.city,
    this.postcode,
    this.dvlaLicenceNumber,
    this.dvlaCheckCode,
    this.dvlaLicenceExpiry,
    this.phvDriverLicenceNumber,
    this.phvDriverLicenceAuthority,
    this.phvDriverLicenceExpiry,
    this.phvDriverLicencePhotoPath,
    this.phvDriverLicenceUploaded = false,
    this.vehicleVrn,
    this.vehicleMake,
    this.vehicleColour,
    this.vehicleMotStatus,
    this.vehicleTaxStatus,
    this.phvVehicleLicenceNumber,
    this.phvVehicleLicenceExpiry,
    this.phvVehicleLicencePhotoPath,
    this.phvVehicleLicenceUploaded = false,
    this.insurancePolicyNumber,
    this.insuranceExpiry,
    this.insurancePhotoPath,
    this.insuranceUploaded = false,
    this.faceVerified = false,
  });

  OnboardingData copyWith({
    String? firstName,
    String? lastName,
    String? middleName,
    Gender? gender,
    String? dateOfBirth,
    String? address,
    String? city,
    String? postcode,
    String? dvlaLicenceNumber,
    String? dvlaCheckCode,
    String? dvlaLicenceExpiry,
    String? phvDriverLicenceNumber,
    String? phvDriverLicenceAuthority,
    String? phvDriverLicenceExpiry,
    String? phvDriverLicencePhotoPath,
    bool? phvDriverLicenceUploaded,
    String? vehicleVrn,
    String? vehicleMake,
    String? vehicleColour,
    String? vehicleMotStatus,
    String? vehicleTaxStatus,
    String? phvVehicleLicenceNumber,
    String? phvVehicleLicenceExpiry,
    String? phvVehicleLicencePhotoPath,
    bool? phvVehicleLicenceUploaded,
    String? insurancePolicyNumber,
    String? insuranceExpiry,
    String? insurancePhotoPath,
    bool? insuranceUploaded,
    bool? faceVerified,
  }) {
    return OnboardingData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      dvlaLicenceNumber: dvlaLicenceNumber ?? this.dvlaLicenceNumber,
      dvlaCheckCode: dvlaCheckCode ?? this.dvlaCheckCode,
      dvlaLicenceExpiry: dvlaLicenceExpiry ?? this.dvlaLicenceExpiry,
      phvDriverLicenceNumber: phvDriverLicenceNumber ?? this.phvDriverLicenceNumber,
      phvDriverLicenceAuthority: phvDriverLicenceAuthority ?? this.phvDriverLicenceAuthority,
      phvDriverLicenceExpiry: phvDriverLicenceExpiry ?? this.phvDriverLicenceExpiry,
      phvDriverLicencePhotoPath: phvDriverLicencePhotoPath ?? this.phvDriverLicencePhotoPath,
      phvDriverLicenceUploaded: phvDriverLicenceUploaded ?? this.phvDriverLicenceUploaded,
      vehicleVrn: vehicleVrn ?? this.vehicleVrn,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleColour: vehicleColour ?? this.vehicleColour,
      vehicleMotStatus: vehicleMotStatus ?? this.vehicleMotStatus,
      vehicleTaxStatus: vehicleTaxStatus ?? this.vehicleTaxStatus,
      phvVehicleLicenceNumber: phvVehicleLicenceNumber ?? this.phvVehicleLicenceNumber,
      phvVehicleLicenceExpiry: phvVehicleLicenceExpiry ?? this.phvVehicleLicenceExpiry,
      phvVehicleLicencePhotoPath: phvVehicleLicencePhotoPath ?? this.phvVehicleLicencePhotoPath,
      phvVehicleLicenceUploaded: phvVehicleLicenceUploaded ?? this.phvVehicleLicenceUploaded,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      insurancePhotoPath: insurancePhotoPath ?? this.insurancePhotoPath,
      insuranceUploaded: insuranceUploaded ?? this.insuranceUploaded,
      faceVerified: faceVerified ?? this.faceVerified,
    );
  }

  /// Check if Phase 1 Step 1 is complete
  bool get isPersonalDetailsComplete =>
      firstName != null &&
      firstName!.isNotEmpty &&
      lastName != null &&
      lastName!.isNotEmpty &&
      gender != null &&
      dateOfBirth != null &&
      address != null &&
      postcode != null;

  /// Check if Phase 1 Step 2 is complete
  bool get isDrivingLicenceComplete =>
      dvlaLicenceNumber != null &&
      dvlaLicenceNumber!.length == 16 &&
      dvlaCheckCode != null &&
      dvlaCheckCode!.isNotEmpty;

  /// Check if Phase 1 Step 3 is complete (uploaded or has photo path)
  bool get isPhvDriverLicenceComplete =>
      phvDriverLicenceUploaded ||
      (phvDriverLicencePhotoPath != null && phvDriverLicenceAuthority != null);

  /// Check if Phase 1 is complete
  bool get isPhase1Complete =>
      isPersonalDetailsComplete &&
      isDrivingLicenceComplete &&
      isPhvDriverLicenceComplete;

  /// Check if Phase 2 Step 1 is complete
  bool get isVehicleComplete =>
      vehicleVrn != null && vehicleVrn!.isNotEmpty;

  /// Check if Phase 2 Step 2 is complete (uploaded or has photo path)
  bool get isPhvVehicleLicenceComplete =>
      phvVehicleLicenceUploaded || phvVehicleLicencePhotoPath != null;

  /// Check if Phase 2 Step 3 is complete (uploaded or has photo path)
  bool get isInsuranceComplete =>
      insuranceUploaded || insurancePhotoPath != null;

  /// Check if Phase 2 is complete
  bool get isPhase2Complete =>
      isVehicleComplete &&
      isPhvVehicleLicenceComplete &&
      isInsuranceComplete;

  /// Check if Phase 3 is complete
  bool get isPhase3Complete => faceVerified;

  /// Check if all phases are complete
  bool get isComplete => isPhase1Complete && isPhase2Complete && isPhase3Complete;

  /// Get current step index (0-7)
  int get currentStepIndex {
    if (!isPersonalDetailsComplete) return 0;
    if (!isDrivingLicenceComplete) return 1;
    if (!isPhvDriverLicenceComplete) return 2;
    if (!isVehicleComplete) return 3;
    if (!isPhvVehicleLicenceComplete) return 4;
    if (!isInsuranceComplete) return 5;
    if (!faceVerified) return 6;
    return 7; // Complete
  }

  /// Total number of steps
  static const int totalSteps = 7;
}

/// UK PHV Licensing Authorities
class PhvAuthorities {
  static const List<String> authorities = [
    'Bournemouth, Christchurch and Poole Council',
    'Dorset Council',
    'Hampshire County Council',
    'Southampton City Council',
    'Portsmouth City Council',
    'Wiltshire Council',
    'Somerset Council',
    'Devon County Council',
    'Cornwall Council',
    'Bristol City Council',
    'Bath and North East Somerset Council',
    'Transport for London',
    'Other',
  ];
}
