import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/pwa_install_banner.dart';
import '../../../auth/application/providers.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../steps/personal_details_step.dart';
import '../steps/driving_licence_step.dart';
import '../steps/phv_driver_licence_step.dart';
import '../steps/vehicle_registration_step.dart';
import '../steps/phv_vehicle_licence_step.dart';
import '../steps/insurance_step.dart';
import '../steps/face_verification_step.dart';

/// Main onboarding wizard page
/// Orchestrates the multi-step onboarding flow
class OnboardingWizardPage extends ConsumerStatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  ConsumerState<OnboardingWizardPage> createState() =>
      _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  @override
  void initState() {
    super.initState();
    // Reset wizard state when page loads
    // Provider will automatically load existing data
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(onboardingWizardProvider);
    final user = ref.watch(currentUserProvider);

    // Listen for completion
    ref.listen<OnboardingWizardState>(onboardingWizardProvider, (previous, next) {
      if (next.currentStep == WizardStep.complete) {
        // Show completion screen
        _showCompletionScreen();
      }
    });

    if (wizardState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Render the current step
    return _buildCurrentStep(wizardState.currentStep);
  }

  Widget _buildCurrentStep(WizardStep step) {
    switch (step) {
      case WizardStep.personalDetails:
        return const PersonalDetailsStep();
      case WizardStep.drivingLicence:
        return const DrivingLicenceStep();
      case WizardStep.phvDriverLicence:
        return const PhvDriverLicenceStep();
      case WizardStep.vehicleRegistration:
        return const VehicleRegistrationStep();
      case WizardStep.phvVehicleLicence:
        return const PhvVehicleLicenceStep();
      case WizardStep.insurance:
        return const InsuranceStep();
      case WizardStep.faceVerification:
        return const FaceVerificationStep();
      case WizardStep.complete:
        return const _CompletionView();
    }
  }

  void _showCompletionScreen() {
    // Navigate to completion view (handled by step rendering)
  }
}

/// Completion view shown when all steps are done
class _CompletionView extends ConsumerWidget {
  const _CompletionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    // Check if this is an existing driver joining a new operator
    final isExistingDriver = user?.hasCompletedOnboardingBefore ?? false;
    final newOperatorName = user?.operators
        .where((op) => op.isInvited)
        .map((op) => op.tenantId)
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PWA Install Banner at top
              const PwaInstallBanner(),
              const Spacer(),

              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExistingDriver ? Icons.person_add : Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                isExistingDriver ? 'Welcome Back!' : 'You\'re All Set!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                isExistingDriver
                    ? 'Your profile has been shared with $newOperatorName. '
                        'They\'ll review your details and let you know when you\'re approved.'
                    : 'Your profile is complete and ready for review. '
                        'You\'ll be notified once your documents have been verified.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              // Driver-owned info banner
              if (isExistingDriver) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your documents are yours. You control which operators can see them.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
