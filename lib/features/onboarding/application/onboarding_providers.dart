import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/profile_providers.dart';
import '../../vehicles/application/vehicle_providers.dart';
import '../../documents/application/document_providers.dart';
import '../../face_verification/application/face_providers.dart';
import '../domain/services/onboarding_service.dart';

/// Onboarding service provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Onboarding progress provider
final onboardingProgressProvider = Provider<OnboardingProgress>((ref) {
  final service = ref.watch(onboardingServiceProvider);
  final profile = ref.watch(currentProfileProvider);
  final vehicles = ref.watch(vehicleListProvider);
  final documents = ref.watch(documentListProvider);
  final hasFaceRegistered = ref.watch(hasFaceRegisteredProvider);

  return service.calculateProgress(
    profile: profile,
    vehicles: vehicles,
    documents: documents,
    hasFaceRegistered: hasFaceRegistered,
  );
});

/// Is onboarding complete provider
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  final progress = ref.watch(onboardingProgressProvider);
  return progress.isComplete;
});

/// Current onboarding step provider
final currentOnboardingStepProvider = Provider<OnboardingStep?>((ref) {
  final progress = ref.watch(onboardingProgressProvider);
  return progress.currentStep;
});
