import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/face_registration.dart';
import '../infrastructure/face_repository.dart';

/// Face repository provider
final faceRepositoryProvider = Provider<FaceRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FaceRepository(dioClient: dioClient);
});

/// Face verification state
sealed class FaceVerificationState {}

class FaceVerificationInitial extends FaceVerificationState {}

class FaceVerificationLoading extends FaceVerificationState {}

class FaceVerificationLoaded extends FaceVerificationState {
  final FaceStatus status;
  FaceVerificationLoaded(this.status);
}

class FaceVerificationRegistering extends FaceVerificationState {
  final double progress;
  FaceVerificationRegistering({this.progress = 0});
}

class FaceVerificationRegistered extends FaceVerificationState {
  final FaceRegistration registration;
  FaceVerificationRegistered(this.registration);
}

class FaceVerificationVerifying extends FaceVerificationState {
  final double progress;
  FaceVerificationVerifying({this.progress = 0});
}

class FaceVerificationVerified extends FaceVerificationState {
  final FaceVerificationResult result;
  FaceVerificationVerified(this.result);
}

class FaceVerificationError extends FaceVerificationState {
  final String message;
  FaceVerificationError(this.message);
}

/// Face verification state notifier
class FaceVerificationNotifier extends StateNotifier<FaceVerificationState> {
  final FaceRepository _repository;

  FaceVerificationNotifier(this._repository) : super(FaceVerificationInitial());

  /// Load face verification status
  Future<void> loadStatus() async {
    state = FaceVerificationLoading();
    try {
      final status = await _repository.getFaceStatus();
      state = FaceVerificationLoaded(status);
    } catch (e) {
      state = FaceVerificationError(e.toString());
    }
  }

  /// Register face image
  Future<bool> registerFace({
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    state = FaceVerificationRegistering();
    try {
      final registration = await _repository.registerFaceImage(
        imageBytes: imageBytes,
        contentType: contentType,
        onProgress: (progress) {
          state = FaceVerificationRegistering(progress: progress);
        },
      );
      state = FaceVerificationRegistered(registration);
      return true;
    } catch (e) {
      state = FaceVerificationError(e.toString());
      return false;
    }
  }

  /// Verify face image against registered reference
  Future<bool> verifyFace({
    required Uint8List imageBytes,
    required String contentType,
    double? confidenceThreshold,
  }) async {
    state = FaceVerificationVerifying();
    try {
      final result = await _repository.verifyFaceImage(
        imageBytes: imageBytes,
        contentType: contentType,
        confidenceThreshold: confidenceThreshold,
        onProgress: (progress) {
          state = FaceVerificationVerifying(progress: progress);
        },
      );
      state = FaceVerificationVerified(result);
      return result.verified;
    } catch (e) {
      state = FaceVerificationError(e.toString());
      return false;
    }
  }

  /// Reset to initial state
  void reset() {
    state = FaceVerificationInitial();
  }
}

/// Face verification state provider
final faceVerificationStateProvider =
    StateNotifierProvider<FaceVerificationNotifier, FaceVerificationState>((ref) {
  final repository = ref.watch(faceRepositoryProvider);
  return FaceVerificationNotifier(repository);
});

/// Convenience provider for current face status
final faceStatusProvider = Provider<FaceStatus?>((ref) {
  final state = ref.watch(faceVerificationStateProvider);
  if (state is FaceVerificationLoaded) {
    return state.status;
  }
  return null;
});

/// Provider for checking if face is registered
final hasFaceRegisteredProvider = Provider<bool>((ref) {
  final status = ref.watch(faceStatusProvider);
  return status?.hasRegisteredFace ?? false;
});

/// Provider for checking if face is verified
final isFaceVerifiedProvider = Provider<bool>((ref) {
  final status = ref.watch(faceStatusProvider);
  return status?.faceVerified ?? false;
});
