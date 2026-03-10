import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/driver_profile.dart';
import '../infrastructure/profile_repository.dart';

/// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ProfileRepository(dioClient: dioClient);
});

/// Profile state
sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final DriverProfile profile;
  const ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

class ProfileSaving extends ProfileState {
  final DriverProfile profile;
  const ProfileSaving(this.profile);
}

/// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial());

  /// Load profile from API
  Future<void> loadProfile() async {
    state = const ProfileLoading();

    try {
      final profile = await _repository.getProfile();
      state = ProfileLoaded(profile);
    } catch (e) {
      state = ProfileError(_parseError(e));
    }
  }

  /// Update profile
  Future<bool> updateProfile(ProfileUpdateRequest request) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return false;

    state = ProfileSaving(currentState.profile);

    try {
      final updated = await _repository.updateProfile(request);
      state = ProfileLoaded(updated);
      return true;
    } catch (e) {
      state = ProfileError(_parseError(e));
      return false;
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Profile state provider
final profileStateProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository: repository);
});

/// Current profile provider (convenience)
final currentProfileProvider = Provider<DriverProfile?>((ref) {
  final state = ref.watch(profileStateProvider);
  if (state is ProfileLoaded) return state.profile;
  if (state is ProfileSaving) return state.profile;
  return null;
});
