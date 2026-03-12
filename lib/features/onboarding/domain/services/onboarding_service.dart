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

  const OnboardingProgress({
    required this.steps,
    required this.completedSteps,
    required this.totalSteps,
    required this.isComplete,
    this.currentStep,
    required this.currentPhase,
    required this.phase1Complete,
    required this.phase2Complete,
  });

  double get progressPercent => totalSteps > 0 ? completedSteps / totalSteps : 0.0;

  /// Get steps for a specific phase
  List<OnboardingStep> stepsForPhase(int phase) =>
      steps.where((s) => s.phase == phase).toList();
}

/// Onboarding service - pure domain logic
class OnboardingService {
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
      (d) => d.documentType == DocumentType.phvDriverLicense,
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
      (d) => d.documentType == DocumentType.phvVehicleLicense,
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
      (d) => d.documentType == DocumentType.vehicleInsurance,
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
    );
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
