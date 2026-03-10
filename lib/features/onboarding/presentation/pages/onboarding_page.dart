import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/application/providers.dart';
import '../../application/onboarding_providers.dart';
import '../../domain/services/onboarding_service.dart';

/// Onboarding page - guides new drivers through setup
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    // Load all required data for onboarding calculation
    _loadData();
  }

  Future<void> _loadData() async {
    // Trigger loading of profile, vehicles, and documents
    // These are already loaded by their respective pages, but ensure they're loaded
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final progress = ref.watch(onboardingProgressProvider);
    final service = ref.watch(onboardingServiceProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If onboarding is complete, show completion screen briefly then redirect
    if (progress.isComplete) {
      return _CompletionScreen(
        onContinue: () => context.go(AppRoutes.home),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                service.getGreeting(user.firstName),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s get you set up to start accepting jobs.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withAlpha(179),
                    ),
              ),
              const SizedBox(height: 24),

              // Progress indicator
              _ProgressIndicator(progress: progress),
              const SizedBox(height: 32),

              // Steps list
              Expanded(
                child: ListView.builder(
                  itemCount: progress.steps.length,
                  itemBuilder: (context, index) {
                    final step = progress.steps[index];
                    final isActive = step == progress.currentStep;
                    return _StepCard(
                      step: step,
                      stepNumber: index + 1,
                      isActive: isActive,
                      onTap: () => context.push(step.route),
                    );
                  },
                ),
              ),

              // Continue button for current step
              if (progress.currentStep != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(progress.currentStep!.route),
                    child: Text('Continue: ${progress.currentStep!.title}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final OnboardingProgress progress;

  const _ProgressIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.completedSteps} of ${progress.totalSteps} steps complete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${(progress.progressPercent * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.progressPercent,
            minHeight: 8,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withAlpha(50),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final OnboardingStep step;
  final int stepNumber;
  final bool isActive;
  final VoidCallback onTap;

  const _StepCard({
    required this.step,
    required this.stepNumber,
    required this.isActive,
    required this.onTap,
  });

  Color _getStatusColor(BuildContext context) {
    switch (step.status) {
      case OnboardingStepStatus.complete:
        return const Color(0xFF2ECC71);
      case OnboardingStepStatus.inProgress:
        return const Color(0xFFF39C12);
      case OnboardingStepStatus.incomplete:
        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _getStatusIcon() {
    switch (step.status) {
      case OnboardingStepStatus.complete:
        return Icons.check_circle;
      case OnboardingStepStatus.inProgress:
        return Icons.pending;
      case OnboardingStepStatus.incomplete:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withAlpha(25)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: step.status != OnboardingStepStatus.complete ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withAlpha(50),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Step number / status icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step.status == OnboardingStepStatus.complete
                        ? Icon(
                            Icons.check,
                            color: statusColor,
                            size: 24,
                          )
                        : Text(
                            '$stepNumber',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Step info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration:
                                  step.status == OnboardingStepStatus.complete
                                      ? TextDecoration.lineThrough
                                      : null,
                              color: step.status == OnboardingStepStatus.complete
                                  ? Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color
                                      ?.withAlpha(128)
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withAlpha(179),
                            ),
                      ),
                    ],
                  ),
                ),

                // Status icon / arrow
                Icon(
                  step.status == OnboardingStepStatus.complete
                      ? _getStatusIcon()
                      : Icons.chevron_right,
                  color: statusColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const _CompletionScreen({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success animation/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2ECC71),
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'You\'re All Set!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Your profile is complete and ready for review. '
                'You\'ll be notified once your documents have been verified.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withAlpha(179),
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
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
