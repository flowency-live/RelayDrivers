import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/face_providers.dart';
import '../../domain/models/face_registration.dart';
import '../widgets/face_capture_widget.dart';

/// Face verification page - verify driver identity against registered face
class FaceVerificationPage extends ConsumerStatefulWidget {
  final VoidCallback? onVerificationSuccess;
  final VoidCallback? onVerificationFailed;

  const FaceVerificationPage({
    super.key,
    this.onVerificationSuccess,
    this.onVerificationFailed,
  });

  @override
  ConsumerState<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends ConsumerState<FaceVerificationPage> {
  @override
  void initState() {
    super.initState();
    // Reset state and load current status
    Future.microtask(() {
      ref.read(faceVerificationStateProvider.notifier).reset();
      ref.read(faceVerificationStateProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceVerificationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity'),
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
                      Icons.security,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verify Your Identity',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take a selfie to confirm your identity matches your registered face.',
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
          ? _buildCaptureWidget(false, null, null)
          : _buildNoFaceRegistered(),
      FaceVerificationVerifying(:final progress) => _buildCaptureWidget(true, progress, null),
      FaceVerificationVerified(:final result) => _buildResult(result),
      FaceVerificationError(:final message) => _buildCaptureWidget(false, null, message),
      _ => _buildCaptureWidget(false, null, null),
    };
  }

  Widget _buildNoFaceRegistered() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.warning_amber,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No Face Registered',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You need to register your face before you can verify your identity.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _buildCaptureWidget(bool isLoading, double? progress, String? error) {
    return FaceCaptureWidget(
      isLoading: isLoading,
      progress: progress,
      errorMessage: error,
      onImageCaptured: (bytes, contentType) async {
        final verified = await ref.read(faceVerificationStateProvider.notifier).verifyFace(
              imageBytes: bytes,
              contentType: contentType,
            );
        if (verified && widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!();
        } else if (!verified && widget.onVerificationFailed != null) {
          widget.onVerificationFailed!();
        }
      },
    );
  }

  Widget _buildResult(FaceVerificationResult result) {
    final verified = result.verified;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: verified ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                verified ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: verified ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                verified ? 'Identity Verified' : 'Verification Failed',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                verified
                    ? 'Your identity has been confirmed.'
                    : 'The face does not match your registered image.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${result.confidence.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!verified) ...[
          FilledButton(
            onPressed: () {
              ref.read(faceVerificationStateProvider.notifier).reset();
              ref.read(faceVerificationStateProvider.notifier).loadStatus();
            },
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 12),
        ],
        if (verified)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          )
        else
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
