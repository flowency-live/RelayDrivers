import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/onboarding_data.dart';
import '../domain/services/dvla_licence_service.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/models/driver_profile.dart';
import '../../vehicles/application/vehicle_providers.dart';
import '../../documents/application/document_providers.dart';
import '../../documents/domain/models/document.dart';
import '../../face_verification/application/face_providers.dart';

/// Wizard step enum
enum WizardStep {
  personalDetails,    // Phase 1, Step 1
  drivingLicence,     // Phase 1, Step 2
  phvDriverLicence,   // Phase 1, Step 3
  vehicleRegistration,// Phase 2, Step 1
  phvVehicleLicence,  // Phase 2, Step 2
  insurance,          // Phase 2, Step 3
  faceVerification,   // Phase 3
  complete,
}

extension WizardStepExtension on WizardStep {
  int get phase {
    switch (this) {
      case WizardStep.personalDetails:
      case WizardStep.drivingLicence:
      case WizardStep.phvDriverLicence:
        return 1;
      case WizardStep.vehicleRegistration:
      case WizardStep.phvVehicleLicence:
      case WizardStep.insurance:
        return 2;
      case WizardStep.faceVerification:
      case WizardStep.complete:
        return 3;
    }
  }

  String get title {
    switch (this) {
      case WizardStep.personalDetails:
        return 'Personal Details';
      case WizardStep.drivingLicence:
        return 'UK Driving Licence';
      case WizardStep.phvDriverLicence:
        return 'PHV Driver Licence';
      case WizardStep.vehicleRegistration:
        return 'Your Vehicle';
      case WizardStep.phvVehicleLicence:
        return 'PHV Vehicle Licence';
      case WizardStep.insurance:
        return 'Private Hire Insurance';
      case WizardStep.faceVerification:
        return 'Identity Verification';
      case WizardStep.complete:
        return 'Complete';
    }
  }

  String get phaseTitle {
    switch (phase) {
      case 1:
        return 'About You';
      case 2:
        return 'About Your Vehicle';
      case 3:
        return 'Identity';
      default:
        return '';
    }
  }

  int get stepInPhase {
    switch (this) {
      case WizardStep.personalDetails:
        return 1;
      case WizardStep.drivingLicence:
        return 2;
      case WizardStep.phvDriverLicence:
        return 3;
      case WizardStep.vehicleRegistration:
        return 1;
      case WizardStep.phvVehicleLicence:
        return 2;
      case WizardStep.insurance:
        return 3;
      case WizardStep.faceVerification:
        return 1;
      case WizardStep.complete:
        return 1;
    }
  }

  int get totalStepsInPhase {
    switch (phase) {
      case 1:
        return 3;
      case 2:
        return 3;
      case 3:
        return 1;
      default:
        return 1;
    }
  }
}

/// Onboarding wizard state
class OnboardingWizardState {
  final WizardStep currentStep;
  final OnboardingData data;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const OnboardingWizardState({
    this.currentStep = WizardStep.personalDetails,
    this.data = const OnboardingData(),
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  OnboardingWizardState copyWith({
    WizardStep? currentStep,
    OnboardingData? data,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return OnboardingWizardState(
      currentStep: currentStep ?? this.currentStep,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Progress percentage (0.0 - 1.0)
  double get progress {
    final stepIndex = WizardStep.values.indexOf(currentStep);
    return stepIndex / (WizardStep.values.length - 1);
  }

  /// Overall step number (1-7)
  int get overallStepNumber {
    return WizardStep.values.indexOf(currentStep) + 1;
  }
}

/// Onboarding wizard notifier
class OnboardingWizardNotifier extends StateNotifier<OnboardingWizardState> {
  final Ref _ref;

  OnboardingWizardNotifier(this._ref) : super(const OnboardingWizardState()) {
    _loadExistingData();
  }

  /// Load existing data from profile/vehicles/documents
  Future<void> _loadExistingData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load profile data
      final profileState = _ref.read(profileStateProvider);
      if (profileState is ProfileLoaded) {
        final profile = profileState.profile;
        state = state.copyWith(
          data: state.data.copyWith(
            firstName: profile.firstName,
            lastName: profile.lastName,
            dateOfBirth: profile.dateOfBirth,
            address: profile.address,
            city: profile.city,
            postcode: profile.postcode,
            dvlaLicenceNumber: profile.dvlaLicenceNumber,
            dvlaCheckCode: profile.dvlaCheckCode,
            dvlaLicenceExpiry: profile.dvlaLicenceExpiry,
          ),
        );
      }

      // Load vehicle data
      final vehicles = _ref.read(vehicleListProvider);
      if (vehicles.isNotEmpty) {
        final vehicle = vehicles.first;
        state = state.copyWith(
          data: state.data.copyWith(
            vehicleVrn: vehicle.vrn,
            vehicleMake: vehicle.make,
            vehicleColour: vehicle.colour,
            vehicleMotStatus: vehicle.motStatus,
            vehicleTaxStatus: vehicle.taxStatus,
          ),
        );
      }

      // Load documents data
      final docState = _ref.read(documentStateProvider);
      if (docState is DocumentsLoaded) {
        for (final doc in docState.documents) {
          switch (doc.documentType) {
            case DocumentType.phvDriverLicense:
              state = state.copyWith(
                data: state.data.copyWith(
                  phvDriverLicenceNumber: doc.licenseNumber,
                  phvDriverLicenceAuthority: doc.issuingAuthority,
                  phvDriverLicenceExpiry: doc.expiryDate,
                  phvDriverLicenceUploaded: true,
                ),
              );
              break;
            case DocumentType.phvVehicleLicense:
              state = state.copyWith(
                data: state.data.copyWith(
                  phvVehicleLicenceNumber: doc.licenseNumber,
                  phvVehicleLicenceExpiry: doc.expiryDate,
                  phvVehicleLicenceUploaded: true,
                ),
              );
              break;
            case DocumentType.vehicleInsurance:
              state = state.copyWith(
                data: state.data.copyWith(
                  insurancePolicyNumber: doc.licenseNumber,
                  insuranceExpiry: doc.expiryDate,
                  insuranceUploaded: true,
                ),
              );
              break;
            default:
              break;
          }
        }
      }

      // Load face status
      final faceState = _ref.read(faceStatusProvider);
      faceState.whenData((status) {
        if (status.isRegistered) {
          state = state.copyWith(
            data: state.data.copyWith(faceVerified: true),
          );
        }
      });

      // Determine current step based on existing data
      _updateCurrentStep();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Update current step based on data completion
  void _updateCurrentStep() {
    final data = state.data;
    WizardStep step;

    if (!data.isPersonalDetailsComplete) {
      step = WizardStep.personalDetails;
    } else if (!data.isDrivingLicenceComplete) {
      step = WizardStep.drivingLicence;
    } else if (!data.isPhvDriverLicenceComplete) {
      step = WizardStep.phvDriverLicence;
    } else if (!data.isVehicleComplete) {
      step = WizardStep.vehicleRegistration;
    } else if (!data.isPhvVehicleLicenceComplete) {
      step = WizardStep.phvVehicleLicence;
    } else if (!data.isInsuranceComplete) {
      step = WizardStep.insurance;
    } else if (!data.faceVerified) {
      step = WizardStep.faceVerification;
    } else {
      step = WizardStep.complete;
    }

    state = state.copyWith(currentStep: step);
  }

  /// Save personal details to backend
  Future<bool> savePersonalDetails({
    required String firstName,
    required String lastName,
    String? middleName,
    required Gender gender,
    required String dateOfBirth,
    required String address,
    required String city,
    required String postcode,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Update local state first (gender and middleName stored locally for DVLA auto-generation)
      state = state.copyWith(
        data: state.data.copyWith(
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          gender: gender,
          dateOfBirth: dateOfBirth,
          address: address,
          city: city,
          postcode: postcode,
        ),
      );

      // Save to backend via profile repository
      // Note: gender and middleName not sent to backend (client-side only for DVLA calc)
      final profileNotifier = _ref.read(profileStateProvider.notifier);
      final success = await profileNotifier.updateProfile(
        ProfileUpdateRequest(
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          address: address,
          city: city,
          postcode: postcode,
        ),
      );

      if (!success) {
        state = state.copyWith(isSaving: false, error: 'Failed to save personal details');
        return false;
      }

      state = state.copyWith(isSaving: false, successMessage: 'Personal details saved');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Save driving licence details to backend
  Future<bool> saveDrivingLicence({
    required String licenceNumber,
    required String checkCode,
    String? expiryDate,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Update local state first
      state = state.copyWith(
        data: state.data.copyWith(
          dvlaLicenceNumber: licenceNumber,
          dvlaCheckCode: checkCode,
          dvlaLicenceExpiry: expiryDate,
        ),
      );

      // Save to backend via profile repository
      final profileNotifier = _ref.read(profileStateProvider.notifier);
      final success = await profileNotifier.updateProfile(
        ProfileUpdateRequest(
          dvlaLicenceNumber: licenceNumber,
          dvlaCheckCode: checkCode,
          dvlaLicenceExpiry: expiryDate,
        ),
      );

      if (!success) {
        state = state.copyWith(isSaving: false, error: 'Failed to save licence details');
        return false;
      }

      state = state.copyWith(isSaving: false, successMessage: 'Licence details saved');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Upload PHV driver licence document
  Future<bool> uploadPhvDriverLicence({
    required String authority,
    required String licenceNumber,
    required String expiryDate,
    required String photoPath,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Read file bytes
      final file = File(photoPath);
      final bytes = await file.readAsBytes();
      final fileName = photoPath.split('/').last;
      final contentType = _getContentType(fileName);

      // Upload via document repository
      final docRepository = _ref.read(documentRepositoryProvider);
      await docRepository.uploadDocument(
        request: DocumentUploadRequest(
          documentType: DocumentType.phvDriverLicense,
          expiryDate: expiryDate,
          licenseNumber: licenceNumber,
          issuingAuthority: authority,
        ),
        fileBytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );

      // Update local state
      state = state.copyWith(
        isSaving: false,
        data: state.data.copyWith(
          phvDriverLicenceAuthority: authority,
          phvDriverLicenceNumber: licenceNumber,
          phvDriverLicenceExpiry: expiryDate,
          phvDriverLicencePhotoPath: photoPath,
          phvDriverLicenceUploaded: true,
        ),
        successMessage: 'PHV Driver Licence uploaded',
      );

      // Refresh documents list
      _ref.read(documentStateProvider.notifier).loadDocuments();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Add vehicle via DVLA lookup
  Future<bool> addVehicle({required String vrn}) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Add vehicle via vehicle notifier
      final vehicleNotifier = _ref.read(vehicleStateProvider.notifier);
      final success = await vehicleNotifier.addVehicle(vrn);

      if (!success) {
        state = state.copyWith(isSaving: false, error: 'Failed to add vehicle');
        return false;
      }

      // Get updated vehicle details from state
      final vehicles = _ref.read(vehicleListProvider);
      final vehicle = vehicles.firstWhere(
        (v) => v.vrn.toUpperCase() == vrn.toUpperCase(),
        orElse: () => vehicles.first,
      );

      // Update local state
      state = state.copyWith(
        isSaving: false,
        data: state.data.copyWith(
          vehicleVrn: vehicle.vrn,
          vehicleMake: vehicle.make,
          vehicleColour: vehicle.colour,
          vehicleMotStatus: vehicle.motStatus,
          vehicleTaxStatus: vehicle.taxStatus,
        ),
        successMessage: 'Vehicle added',
      );

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Upload PHV vehicle licence document
  Future<bool> uploadPhvVehicleLicence({
    String? licenceNumber,
    required String expiryDate,
    required String photoPath,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Read file bytes
      final file = File(photoPath);
      final bytes = await file.readAsBytes();
      final fileName = photoPath.split('/').last;
      final contentType = _getContentType(fileName);

      // Upload via document repository
      final docRepository = _ref.read(documentRepositoryProvider);
      await docRepository.uploadDocument(
        request: DocumentUploadRequest(
          documentType: DocumentType.phvVehicleLicense,
          expiryDate: expiryDate,
          licenseNumber: licenceNumber,
          vehicleVrn: state.data.vehicleVrn,
        ),
        fileBytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );

      // Update local state
      state = state.copyWith(
        isSaving: false,
        data: state.data.copyWith(
          phvVehicleLicenceNumber: licenceNumber,
          phvVehicleLicenceExpiry: expiryDate,
          phvVehicleLicencePhotoPath: photoPath,
          phvVehicleLicenceUploaded: true,
        ),
        successMessage: 'PHV Vehicle Licence uploaded',
      );

      // Refresh documents list
      _ref.read(documentStateProvider.notifier).loadDocuments();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Upload insurance document
  Future<bool> uploadInsurance({
    String? policyNumber,
    required String expiryDate,
    required String photoPath,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Read file bytes
      final file = File(photoPath);
      final bytes = await file.readAsBytes();
      final fileName = photoPath.split('/').last;
      final contentType = _getContentType(fileName);

      // Upload via document repository
      final docRepository = _ref.read(documentRepositoryProvider);
      await docRepository.uploadDocument(
        request: DocumentUploadRequest(
          documentType: DocumentType.vehicleInsurance,
          expiryDate: expiryDate,
          licenseNumber: policyNumber,
          vehicleVrn: state.data.vehicleVrn,
        ),
        fileBytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );

      // Update local state
      state = state.copyWith(
        isSaving: false,
        data: state.data.copyWith(
          insurancePolicyNumber: policyNumber,
          insuranceExpiry: expiryDate,
          insurancePhotoPath: photoPath,
          insuranceUploaded: true,
        ),
        successMessage: 'Insurance uploaded',
      );

      // Refresh documents list
      _ref.read(documentStateProvider.notifier).loadDocuments();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Register face via Rekognition
  Future<bool> registerFace({required Uint8List imageBytes}) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // Register via face repository
      final faceRepository = _ref.read(faceRepositoryProvider);
      await faceRepository.registerFaceImage(
        imageBytes: imageBytes,
        contentType: 'image/jpeg',
      );

      // Update local state
      state = state.copyWith(
        isSaving: false,
        data: state.data.copyWith(faceVerified: true),
        successMessage: 'Face registered successfully',
      );

      // Refresh face status
      _ref.invalidate(faceStatusProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Update personal details (local only for backward compat)
  void updatePersonalDetails({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String address,
    required String city,
    required String postcode,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        postcode: postcode,
      ),
    );
  }

  /// Update driving licence details (local only for backward compat)
  void updateDrivingLicence({
    required String licenceNumber,
    required String checkCode,
    String? expiryDate,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        dvlaLicenceNumber: licenceNumber,
        dvlaCheckCode: checkCode,
        dvlaLicenceExpiry: expiryDate,
      ),
    );
  }

  /// Update PHV driver licence (local only)
  void updatePhvDriverLicence({
    required String authority,
    String? licenceNumber,
    String? expiryDate,
    String? photoPath,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        phvDriverLicenceAuthority: authority,
        phvDriverLicenceNumber: licenceNumber,
        phvDriverLicenceExpiry: expiryDate,
        phvDriverLicencePhotoPath: photoPath,
      ),
    );
  }

  /// Update vehicle details (local only)
  void updateVehicle({
    required String vrn,
    String? make,
    String? colour,
    String? motStatus,
    String? taxStatus,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        vehicleVrn: vrn,
        vehicleMake: make,
        vehicleColour: colour,
        vehicleMotStatus: motStatus,
        vehicleTaxStatus: taxStatus,
      ),
    );
  }

  /// Update PHV vehicle licence (local only)
  void updatePhvVehicleLicence({
    String? licenceNumber,
    String? expiryDate,
    String? photoPath,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        phvVehicleLicenceNumber: licenceNumber,
        phvVehicleLicenceExpiry: expiryDate,
        phvVehicleLicencePhotoPath: photoPath,
      ),
    );
  }

  /// Update insurance details (local only)
  void updateInsurance({
    String? policyNumber,
    String? expiryDate,
    String? photoPath,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        insurancePolicyNumber: policyNumber,
        insuranceExpiry: expiryDate,
        insurancePhotoPath: photoPath,
      ),
    );
  }

  /// Mark face verification complete (local only)
  void completeFaceVerification() {
    state = state.copyWith(
      data: state.data.copyWith(faceVerified: true),
    );
  }

  /// Go to next step
  void nextStep() {
    final currentIndex = WizardStep.values.indexOf(state.currentStep);
    if (currentIndex < WizardStep.values.length - 1) {
      state = state.copyWith(
        currentStep: WizardStep.values[currentIndex + 1],
      );
    }
  }

  /// Go to previous step
  void previousStep() {
    final currentIndex = WizardStep.values.indexOf(state.currentStep);
    if (currentIndex > 0) {
      state = state.copyWith(
        currentStep: WizardStep.values[currentIndex - 1],
      );
    }
  }

  /// Go to specific step
  void goToStep(WizardStep step) {
    state = state.copyWith(currentStep: step);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Set loading
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Get content type from file extension
  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Provider for onboarding wizard
final onboardingWizardProvider =
    StateNotifierProvider<OnboardingWizardNotifier, OnboardingWizardState>(
  (ref) => OnboardingWizardNotifier(ref),
);
