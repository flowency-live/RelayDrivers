import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/face_providers.dart';
import '../../domain/models/face_registration.dart';
import '../widgets/face_capture_widget.dart';

/// Face registration page - register driver's reference face image
class FaceRegistrationPage extends ConsumerStatefulWidget {
  final VoidCallback? onRegistrationComplete;

  const FaceRegistrationPage({super.key, this.onRegistrationComplete});

  @override
  ConsumerState<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends ConsumerState<FaceRegistrationPage> {
  @override
  void initState() {
    super.initState();
    // Load current face status
    Future.microtask(() {
      ref.read(faceVerificationStateProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceVerificationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Register Your Face',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This reference image will be used to verify your identity before jobs.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Handle different states
              _buildContent(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(FaceVerificationState state) {
    return switch (state) {
      FaceVerificationInitial() || FaceVerificationLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      FaceVerificationLoaded(:final status) => status.hasRegisteredFace
          ? _buildAlreadyRegistered(status)
          : _buildCaptureWidget(false, null, null),
      FaceVerificationRegistering(:final progress) => _buildCaptureWidget(true, progress, null),
      FaceVerificationRegistered(:final registration) => _buildSuccess(registration),
      FaceVerificationError(:final message) => _buildCaptureWidget(false, null, message),
      _ => _buildCaptureWidget(false, null, null),
    };
  }

  Widget _buildAlreadyRegistered(FaceStatus status) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Face Already Registered',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Registered on ${_formatDate(status.registration!.registeredAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${status.registration!.confidence.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Option to re-register
        OutlinedButton.icon(
          onPressed: () {
            ref.read(faceVerificationStateProvider.notifier).reset();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Register New Face'),
        ),
        if (widget.onRegistrationComplete != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.onRegistrationComplete,
            child: const Text('Continue'),
          ),
        ],
      ],
    );
  }

  Widget _buildCaptureWidget(bool isLoading, double? progress, String? error) {
    return FaceCaptureWidget(
      isLoading: isLoading,
      progress: progress,
      errorMessage: error,
      onImageCaptured: (bytes, contentType) {
        ref.read(faceVerificationStateProvider.notifier).registerFace(
              imageBytes: bytes,
              contentType: contentType,
            );
      },
    );
  }

  Widget _buildSuccess(FaceRegistration registration) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Face Registered Successfully',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${registration.confidence.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (widget.onRegistrationComplete != null)
          FilledButton(
            onPressed: widget.onRegistrationComplete,
            child: const Text('Continue'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
