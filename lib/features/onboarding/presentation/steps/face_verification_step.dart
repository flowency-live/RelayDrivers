import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../widgets/wizard_scaffold.dart';
import '../../../face_verification/application/face_providers.dart';

/// Phase 3: Face Verification
/// Final step - capture selfie for identity verification
class FaceVerificationStep extends ConsumerStatefulWidget {
  const FaceVerificationStep({super.key});

  @override
  ConsumerState<FaceVerificationStep> createState() =>
      _FaceVerificationStepState();
}

class _FaceVerificationStepState extends ConsumerState<FaceVerificationStep> {
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Check if face is already registered
    ref.read(faceVerificationStateProvider.notifier).loadStatus();
  }

  Future<void> _startFaceVerification() async {
    setState(() => _isVerifying = true);

    try {
      // Navigate to face registration page
      if (mounted) {
        context.push(AppRoutes.faceRegistration);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _goBack() {
    ref.read(onboardingWizardProvider.notifier).previousStep();
  }

  void _completeOnboarding() {
    ref.read(onboardingWizardProvider.notifier).completeFaceVerification();
    ref.read(onboardingWizardProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faceState = ref.watch(faceVerificationStateProvider);
    final hasFaceRegistered = ref.watch(hasFaceRegisteredProvider);
    final wizardData = ref.watch(onboardingWizardProvider).data;

    // Check if face was verified in this session or previously
    final isVerified = hasFaceRegistered || wizardData.faceVerified;

    return WizardScaffold(
      step: WizardStep.faceVerification,
      canGoNext: isVerified,
      onBack: _goBack,
      onNext: _completeOnboarding,
      nextLabel: 'Complete',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon/illustration
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withAlpha(25)
                          : theme.colorScheme.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.check_circle : Icons.face,
                      size: 80,
                      color: isVerified
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    isVerified
                        ? 'Identity Verified!'
                        : 'Verify Your Identity',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    isVerified
                        ? 'Your face has been registered for identity verification. '
                            'You\'re all set to complete onboarding.'
                        : 'Take a quick selfie to verify your identity. '
                            'This helps keep the platform safe and secure.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (!isVerified) ...[
                    const SizedBox(height: 32),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tips for a good photo',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _TipItem(
                            icon: Icons.wb_sunny_outlined,
                            text: 'Good lighting on your face',
                          ),
                          _TipItem(
                            icon: Icons.face,
                            text: 'Look directly at the camera',
                          ),
                          _TipItem(
                            icon: Icons.visibility_off,
                            text: 'Remove glasses or hats',
                          ),
                          _TipItem(
                            icon: Icons.center_focus_strong,
                            text: 'Keep your face centered',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start verification button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isVerifying ? null : _startFaceVerification,
                        icon: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(
                          _isVerifying ? 'Opening camera...' : 'Start Verification',
                        ),
                      ),
                    ),
                  ],

                  if (isVerified) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ready to complete onboarding',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
