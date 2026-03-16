import '../../../profile/domain/models/driver_profile.dart';
import '../../../documents/domain/models/document.dart';
import '../../../vehicles/domain/models/vehicle.dart';

/// Onboarding step status
enum OnboardingStepStatus {
  incomplete,
  inProgress,
  complete,
}

/// Individual onboarding step
class OnboardingStep {
  final String id;
  final int phase;
  final String title;
  final String description;
  final OnboardingStepStatus status;
  final String route;

  const OnboardingStep({
    required this.id,
    required this.phase,
    required this.title,
    required this.description,
    required this.status,
    required this.route,
  });

  OnboardingStep copyWith({
    String? id,
    int? phase,
    String? title,
    String? description,
    OnboardingStepStatus? status,
    String? route,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      route: route ?? this.route,
    );
  }
}

/// Progress tracking for a section with granular field-level detail
class SectionProgress {
  /// Section identifier ('profile', 'vehicles', 'documents')
  final String sectionId;

  /// Section display title
  final String title;

  /// Section description
  final String description;

  /// Number of completed items
  final int completedItems;

  /// Total number of items required
  final int totalItems;

  /// List of missing item names for display
  final List<String> missingItems;

  /// Route to navigate to for this section
  final String route;

  const SectionProgress({
    required this.sectionId,
    required this.title,
    required this.description,
    required this.completedItems,
    required this.totalItems,
    this.missingItems = const [],
    required this.route,
  });

  /// Progress percentage (0.0 to 1.0)
  double get percent => totalItems > 0 ? completedItems / totalItems : 0.0;

  /// Whether section is complete
  bool get isComplete => completedItems >= totalItems;

  /// Number of items remaining
  int get remainingItems => totalItems - completedItems;

  /// Human-readable progress string
  String get progressText => '$completedItems of $totalItems complete';
}

/// Onboarding progress
class OnboardingProgress {
  final List<OnboardingStep> steps;
  final int completedSteps;
  final int totalSteps;
  final bool isComplete;
  final OnboardingStep? currentStep;
  final int currentPhase;
  final bool phase1Complete;
  final bool phase2Complete;

  /// Section-level progress for home page tiles
  final SectionProgress profileProgress;
  final SectionProgress vehicleProgress;
  final SectionProgress documentProgress;

  const OnboardingProgress({
    required this.steps,
    required this.completedSteps,
    required this.totalSteps,
    required this.isComplete,
    this.currentStep,
    required this.currentPhase,
    required this.phase1Complete,
    required this.phase2Complete,
    required this.profileProgress,
    required this.vehicleProgress,
    required this.documentProgress,
  });

  double get progressPercent =>
      totalSteps > 0 ? completedSteps / totalSteps : 0.0;

  /// Get steps for a specific phase
  List<OnboardingStep> stepsForPhase(int phase) =>
      steps.where((s) => s.phase == phase).toList();
}

/// Onboarding service - pure domain logic
class OnboardingService {
  /// Required profile fields for completion calculation
  static const List<String> _requiredProfileFields = [
    'firstName',
    'lastName',
    'phone',
    'dateOfBirth',
    'address',
    'city',
    'postcode',
    'nationalInsurance',
    'dvlaLicenceNumber',
    'dvlaCheckCode',
  ];

  /// Calculate onboarding progress from profile, vehicles, documents, and face status
  ///
  /// 2-Phase onboarding structure + Final step:
  /// Phase 1 - Driver Setup:
  ///   1. Complete profile with DVLA licence number + check code
  ///   2. Upload PHV Driver Licence
  ///
  /// Phase 2 - Vehicle Setup:
  ///   3. Add vehicle (VRN triggers DVLA lookup)
  ///   4. Upload PHV Vehicle Licence
  ///   5. Upload Hire & Reward Insurance
  ///
  /// Final Step:
  ///   6. Verify identity with face registration
  OnboardingProgress calculateProgress({
    DriverProfile? profile,
    required List<Vehicle> vehicles,
    required List<DriverDocument> documents,
    bool hasFaceRegistered = false,
  }) {
    final steps = <OnboardingStep>[];

    // Calculate section progress first
    final profileProgress = _calculateProfileProgress(profile);
    final vehicleProgress = _calculateVehicleProgress(vehicles);
    final documentProgress = _calculateDocumentProgress(documents, vehicles);

    // ============================================================
    // PHASE 1: Driver Setup
    // ============================================================

    // Step 1: Complete profile with DVLA details
    final profileComplete = _isProfileComplete(profile);
    final hasDvlaDetails = profile?.hasDvlaDetails ?? false;
    final phase1ProfileComplete = profileComplete && hasDvlaDetails;

    steps.add(OnboardingStep(
      id: 'profile',
      phase: 1,
      title: 'Your Details',
      description: 'Personal info and UK driving licence details',
      status: phase1ProfileComplete
          ? OnboardingStepStatus.complete
          : profile != null
              ? OnboardingStepStatus.inProgress
              : OnboardingStepStatus.incomplete,
      route: '/profile',
    ));

    // Step 2: Upload PHV Driver Licence
    final hasDriverLicense = documents.any(
      (d) => d.documentType == DocumentType.phvDriverLicence,
    );
    steps.add(OnboardingStep(
      id: 'phv_driver_licence',
      phase: 1,
      title: 'PHV Driver Licence',
      description: 'Upload your private hire driver licence',
      status: hasDriverLicense
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/documents',
    ));

    // Check Phase 1 completion
    final phase1Steps = steps.where((s) => s.phase == 1).toList();
    final phase1Complete = phase1Steps.every(
      (s) => s.status == OnboardingStepStatus.complete,
    );

    // ============================================================
    // PHASE 2: Vehicle Setup
    // ============================================================

    // Step 3: Add a vehicle (VRN triggers DVLA lookup)
    final hasVehicle = vehicles.isNotEmpty;
    steps.add(OnboardingStep(
      id: 'vehicle',
      phase: 2,
      title: 'Add Your Vehicle',
      description: 'Register vehicle for DVLA tax/MOT check',
      status: hasVehicle
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/vehicles',
    ));

    // Step 4: Upload PHV Vehicle Licence
    final hasVehicleLicense = documents.any(
      (d) => d.documentType == DocumentType.phvVehicleLicence,
    );
    steps.add(OnboardingStep(
      id: 'phv_vehicle_licence',
      phase: 2,
      title: 'PHV Vehicle Licence',
      description: 'Upload your vehicle plate/licence',
      status: hasVehicleLicense
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/documents',
    ));

    // Step 5: Upload Hire & Reward Insurance
    final hasVehicleInsurance = documents.any(
      (d) => d.documentType == DocumentType.hireRewardInsurance,
    );
    steps.add(OnboardingStep(
      id: 'vehicle_insurance',
      phase: 2,
      title: 'Hire & Reward Insurance',
      description: 'Upload private hire insurance certificate',
      status: hasVehicleInsurance
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/documents',
    ));

    // Check Phase 2 completion
    final phase2Steps = steps.where((s) => s.phase == 2).toList();
    final phase2Complete = phase2Steps.every(
      (s) => s.status == OnboardingStepStatus.complete,
    );

    // ============================================================
    // FINAL STEP: Identity Verification (Phase 3)
    // ============================================================

    // Step 6: Face verification (only shown after Phase 2 complete)
    steps.add(OnboardingStep(
      id: 'face_verification',
      phase: 3,
      title: 'Verify Your Identity',
      description: 'Take a selfie for identity verification',
      status: hasFaceRegistered
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/face-registration',
    ));

    final completedSteps =
        steps.where((s) => s.status == OnboardingStepStatus.complete).length;
    final isComplete = phase1Complete && phase2Complete && hasFaceRegistered;

    // Determine current phase
    int currentPhase;
    if (!phase1Complete) {
      currentPhase = 1;
    } else if (!phase2Complete) {
      currentPhase = 2;
    } else {
      currentPhase = 3;
    }

    // Find first incomplete step
    OnboardingStep? currentStep;
    for (final step in steps) {
      if (step.status != OnboardingStepStatus.complete) {
        currentStep = step;
        break;
      }
    }

    return OnboardingProgress(
      steps: steps,
      completedSteps: completedSteps,
      totalSteps: steps.length,
      isComplete: isComplete,
      currentStep: currentStep,
      currentPhase: currentPhase,
      phase1Complete: phase1Complete,
      phase2Complete: phase2Complete,
      profileProgress: profileProgress,
      vehicleProgress: vehicleProgress,
      documentProgress: documentProgress,
    );
  }

  /// Calculate profile section progress with field-level detail
  SectionProgress _calculateProfileProgress(DriverProfile? profile) {
    if (profile == null) {
      return SectionProgress(
        sectionId: 'profile',
        title: 'My Profile',
        description: 'Personal details, licence info',
        completedItems: 0,
        totalItems: _requiredProfileFields.length,
        missingItems: _requiredProfileFields
            .map((f) => _fieldDisplayName(f))
            .toList(),
        route: '/profile',
      );
    }

    final completed = <String>[];
    final missing = <String>[];

    // Check each required field
    for (final field in _requiredProfileFields) {
      final value = _getProfileFieldValue(profile, field);
      if (value != null && value.isNotEmpty) {
        completed.add(field);
      } else {
        missing.add(_fieldDisplayName(field));
      }
    }

    return SectionProgress(
      sectionId: 'profile',
      title: 'My Profile',
      description: 'Personal details, licence info',
      completedItems: completed.length,
      totalItems: _requiredProfileFields.length,
      missingItems: missing,
      route: '/profile',
    );
  }

  /// Calculate vehicle section progress
  SectionProgress _calculateVehicleProgress(List<Vehicle> vehicles) {
    // For vehicles, we just need at least one vehicle
    final hasVehicle = vehicles.isNotEmpty;

    return SectionProgress(
      sectionId: 'vehicles',
      title: 'Vehicles',
      description: 'Manage your vehicles',
      completedItems: hasVehicle ? 1 : 0,
      totalItems: 1,
      missingItems: hasVehicle ? [] : ['Add at least one vehicle'],
      route: '/vehicles',
    );
  }

  /// Calculate document section progress
  SectionProgress _calculateDocumentProgress(
    List<DriverDocument> documents,
    List<Vehicle> vehicles,
  ) {
    final required = <String>[];
    final missing = <String>[];

    // PHV Driver Licence is always required
    required.add('PHV Driver Licence');
    final hasDriverLicence = documents.any(
      (d) => d.documentType == DocumentType.phvDriverLicence,
    );
    if (!hasDriverLicence) {
      missing.add('PHV Driver Licence');
    }

    // If we have vehicles, we need vehicle documents
    if (vehicles.isNotEmpty) {
      // PHV Vehicle Licence (one per vehicle)
      required.add('PHV Vehicle Licence');
      final hasVehicleLicence = documents.any(
        (d) => d.documentType == DocumentType.phvVehicleLicence,
      );
      if (!hasVehicleLicence) {
        missing.add('PHV Vehicle Licence');
      }

      // Vehicle Insurance (one per vehicle)
      required.add('Vehicle Insurance');
      final hasInsurance = documents.any(
        (d) => d.documentType == DocumentType.hireRewardInsurance,
      );
      if (!hasInsurance) {
        missing.add('Vehicle Insurance');
      }
    }

    return SectionProgress(
      sectionId: 'documents',
      title: 'Documents',
      description: 'Upload documents',
      completedItems: required.length - missing.length,
      totalItems: required.length,
      missingItems: missing,
      route: '/documents',
    );
  }

  /// Get a profile field value by name
  String? _getProfileFieldValue(DriverProfile profile, String field) {
    return switch (field) {
      'firstName' => profile.firstName,
      'lastName' => profile.lastName,
      'phone' => profile.phone,
      'dateOfBirth' => profile.dateOfBirth,
      'address' => profile.address,
      'city' => profile.city,
      'postcode' => profile.postcode,
      'nationalInsurance' => profile.nationalInsurance,
      'dvlaLicenceNumber' => profile.dvlaLicenceNumber,
      'dvlaCheckCode' => profile.dvlaCheckCode,
      _ => null,
    };
  }

  /// Get human-readable name for a profile field
  String _fieldDisplayName(String field) {
    return switch (field) {
      'firstName' => 'First Name',
      'lastName' => 'Last Name',
      'phone' => 'Phone Number',
      'dateOfBirth' => 'Date of Birth',
      'address' => 'Address',
      'city' => 'City',
      'postcode' => 'Postcode',
      'nationalInsurance' => 'National Insurance',
      'dvlaLicenceNumber' => 'Licence Number',
      'dvlaCheckCode' => 'Check Code',
      _ => field,
    };
  }

  /// Check if profile has minimum required fields
  bool _isProfileComplete(DriverProfile? profile) {
    if (profile == null) return false;

    return profile.firstName.isNotEmpty &&
        profile.lastName.isNotEmpty &&
        profile.email.isNotEmpty &&
        profile.phone != null &&
        profile.phone!.isNotEmpty;
  }

  /// Get greeting based on time of day
  String getGreeting(String firstName) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    return '$greeting, $firstName';
  }
}
