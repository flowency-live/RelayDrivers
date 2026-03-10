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
  final String title;
  final String description;
  final OnboardingStepStatus status;
  final String route;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.route,
  });

  OnboardingStep copyWith({
    String? id,
    String? title,
    String? description,
    OnboardingStepStatus? status,
    String? route,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
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

  const OnboardingProgress({
    required this.steps,
    required this.completedSteps,
    required this.totalSteps,
    required this.isComplete,
    this.currentStep,
  });

  double get progressPercent => totalSteps > 0 ? completedSteps / totalSteps : 0.0;
}

/// Onboarding service - pure domain logic
class OnboardingService {
  /// Calculate onboarding progress from profile, vehicles, and documents
  OnboardingProgress calculateProgress({
    DriverProfile? profile,
    required List<Vehicle> vehicles,
    required List<DriverDocument> documents,
  }) {
    final steps = <OnboardingStep>[];

    // Step 1: Complete profile
    final profileComplete = _isProfileComplete(profile);
    steps.add(OnboardingStep(
      id: 'profile',
      title: 'Complete Your Profile',
      description: 'Add your personal details and contact information',
      status: profileComplete
          ? OnboardingStepStatus.complete
          : profile != null
              ? OnboardingStepStatus.inProgress
              : OnboardingStepStatus.incomplete,
      route: '/profile',
    ));

    // Step 2: Add a vehicle
    final hasVehicle = vehicles.isNotEmpty;
    steps.add(OnboardingStep(
      id: 'vehicle',
      title: 'Add Your Vehicle',
      description: 'Register your vehicle with DVLA details',
      status: hasVehicle
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/vehicles',
    ));

    // Step 3: Upload driver license
    final hasDriverLicense = documents.any(
      (d) => d.documentType == DocumentType.phvDriverLicense,
    );
    steps.add(OnboardingStep(
      id: 'driver_license',
      title: 'PHV Driver License',
      description: 'Upload your Private Hire Vehicle driver license',
      status: hasDriverLicense
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/documents',
    ));

    // Step 4: Upload driver insurance
    final hasDriverInsurance = documents.any(
      (d) => d.documentType == DocumentType.driverInsurance,
    );
    steps.add(OnboardingStep(
      id: 'driver_insurance',
      title: 'Driver Insurance',
      description: 'Upload proof of your driver insurance',
      status: hasDriverInsurance
          ? OnboardingStepStatus.complete
          : OnboardingStepStatus.incomplete,
      route: '/documents',
    ));

    // Step 5: Upload vehicle license (if has vehicle)
    if (hasVehicle) {
      final hasVehicleLicense = documents.any(
        (d) => d.documentType == DocumentType.phvVehicleLicense,
      );
      steps.add(OnboardingStep(
        id: 'vehicle_license',
        title: 'PHV Vehicle License',
        description: 'Upload your vehicle\'s PHV plate/license',
        status: hasVehicleLicense
            ? OnboardingStepStatus.complete
            : OnboardingStepStatus.incomplete,
        route: '/documents',
      ));

      // Step 6: Upload vehicle insurance (if has vehicle)
      final hasVehicleInsurance = documents.any(
        (d) => d.documentType == DocumentType.vehicleInsurance,
      );
      steps.add(OnboardingStep(
        id: 'vehicle_insurance',
        title: 'Vehicle Insurance',
        description: 'Upload proof of vehicle insurance',
        status: hasVehicleInsurance
            ? OnboardingStepStatus.complete
            : OnboardingStepStatus.incomplete,
        route: '/documents',
      ));
    }

    final completedSteps =
        steps.where((s) => s.status == OnboardingStepStatus.complete).length;
    final isComplete = completedSteps == steps.length;

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
