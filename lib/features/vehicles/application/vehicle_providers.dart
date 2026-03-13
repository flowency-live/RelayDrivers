import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/vehicle.dart';
import '../infrastructure/vehicle_repository.dart';

/// Vehicle repository provider
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return VehicleRepository(dioClient: dioClient);
});

/// Vehicle state
sealed class VehicleState {
  const VehicleState();
}

class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoading extends VehicleState {
  const VehicleLoading();
}

class VehicleLoaded extends VehicleState {
  final List<Vehicle> vehicles;
  const VehicleLoaded(this.vehicles);
}

class VehicleError extends VehicleState {
  final String message;
  const VehicleError(this.message);
}

class VehicleAdding extends VehicleState {
  final List<Vehicle> vehicles;
  const VehicleAdding(this.vehicles);
}

class VehicleDeleting extends VehicleState {
  final List<Vehicle> vehicles;
  final String deletingVrn;
  const VehicleDeleting(this.vehicles, this.deletingVrn);
}

/// Vehicle notifier
class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleRepository _repository;

  VehicleNotifier({required VehicleRepository repository})
      : _repository = repository,
        super(const VehicleInitial());

  /// Load vehicles from API
  Future<void> loadVehicles() async {
    state = const VehicleLoading();

    try {
      final vehicles = await _repository.getVehicles();
      state = VehicleLoaded(vehicles);
    } catch (e) {
      state = VehicleError(_parseError(e));
    }
  }

  /// Lookup vehicle by VRN (DVLA check)
  Future<DvlaLookupResult?> lookupVehicle(String vrn) async {
    try {
      return await _repository.lookupVehicle(vrn);
    } catch (e) {
      // Return null on lookup failure, caller handles error
      return null;
    }
  }

  /// Add a vehicle
  Future<bool> addVehicle(String vrn) async {
    final currentState = state;
    final currentVehicles = currentState is VehicleLoaded
        ? currentState.vehicles
        : currentState is VehicleAdding
            ? currentState.vehicles
            : <Vehicle>[];

    state = VehicleAdding(currentVehicles);

    try {
      final newVehicle = await _repository.addVehicle(vrn);
      state = VehicleLoaded([...currentVehicles, newVehicle]);
      return true;
    } catch (e) {
      state = VehicleError(_parseError(e));
      return false;
    }
  }

  /// Delete a vehicle
  Future<bool> deleteVehicle(String vrn) async {
    final currentState = state;
    if (currentState is! VehicleLoaded) return false;

    state = VehicleDeleting(currentState.vehicles, vrn);

    try {
      await _repository.deleteVehicle(vrn);
      final updatedVehicles =
          currentState.vehicles.where((v) => v.vrn != vrn).toList();
      state = VehicleLoaded(updatedVehicles);
      return true;
    } catch (e) {
      state = VehicleError(_parseError(e));
      return false;
    }
  }

  /// Refresh DVLA data for a vehicle
  Future<bool> refreshVehicle(String vrn) async {
    final currentState = state;
    if (currentState is! VehicleLoaded) return false;

    try {
      final refreshed = await _repository.refreshVehicle(vrn);
      final updatedVehicles = currentState.vehicles.map((v) {
        return v.vrn == vrn ? refreshed : v;
      }).toList();
      state = VehicleLoaded(updatedVehicles);
      return true;
    } catch (e) {
      // Keep current state on refresh failure
      return false;
    }
  }

  /// Upload a photo for a vehicle
  Future<VehiclePhoto?> uploadVehiclePhoto({
    required String vrn,
    required VehiclePhotoType photoType,
    required Uint8List photoBytes,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    try {
      final photo = await _repository.uploadVehiclePhoto(
        vrn: vrn,
        photoType: photoType,
        photoBytes: photoBytes,
        contentType: contentType,
        onProgress: onProgress,
      );

      // Update local state with new photo
      final currentState = state;
      if (currentState is VehicleLoaded) {
        final updatedVehicles = currentState.vehicles.map((v) {
          if (v.vrn == vrn) {
            return v.copyWith(photos: [...v.photos, photo]);
          }
          return v;
        }).toList();
        state = VehicleLoaded(updatedVehicles);
      }

      return photo;
    } catch (e) {
      return null;
    }
  }

  /// Delete a photo from a vehicle
  Future<bool> deleteVehiclePhoto({
    required String vrn,
    required String photoId,
  }) async {
    try {
      await _repository.deleteVehiclePhoto(vrn: vrn, photoId: photoId);

      // Update local state
      final currentState = state;
      if (currentState is VehicleLoaded) {
        final updatedVehicles = currentState.vehicles.map((v) {
          if (v.vrn == vrn) {
            return v.copyWith(
              photos: v.photos.where((p) => p.photoId != photoId).toList(),
            );
          }
          return v;
        }).toList();
        state = VehicleLoaded(updatedVehicles);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get photos for a vehicle
  Future<List<VehiclePhoto>> getVehiclePhotos(String vrn) async {
    try {
      return await _repository.getVehiclePhotos(vrn);
    } catch (e) {
      return [];
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Vehicle state provider
final vehicleStateProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleNotifier(repository: repository);
});

/// Convenience provider for vehicle list
final vehicleListProvider = Provider<List<Vehicle>>((ref) {
  final state = ref.watch(vehicleStateProvider);
  if (state is VehicleLoaded) return state.vehicles;
  if (state is VehicleAdding) return state.vehicles;
  if (state is VehicleDeleting) return state.vehicles;
  return [];
});

/// Provider for vehicle count
final vehicleCountProvider = Provider<int>((ref) {
  return ref.watch(vehicleListProvider).length;
});
