import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/vehicle_providers.dart';
import '../../domain/models/vehicle.dart';
import '../widgets/add_vehicle_sheet.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/vehicle_photo_upload.dart';

/// Vehicles page - list and manage driver vehicles
class VehiclesPage extends ConsumerStatefulWidget {
  const VehiclesPage({super.key});

  @override
  ConsumerState<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends ConsumerState<VehiclesPage> {
  @override
  void initState() {
    super.initState();
    // Load vehicles on page load
    Future.microtask(() {
      ref.read(vehicleStateProvider.notifier).loadVehicles();
    });
  }

  void _showAddVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddVehicleSheet(),
    );
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to remove ${vehicle.displayName} (${vehicle.vrn}) from your profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(vehicleStateProvider.notifier).deleteVehicle(vehicle.vrn);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${vehicle.displayName} removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: switch (vehicleState) {
        VehicleInitial() || VehicleLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        VehicleError(:final message) => _ErrorView(
            message: message,
            onRetry: () {
              ref.read(vehicleStateProvider.notifier).loadVehicles();
            },
          ),
        VehicleLoaded(:final vehicles) ||
        VehicleAdding(:final vehicles) ||
        VehicleDeleting(:final vehicles) =>
          vehicles.isEmpty
              ? _EmptyView(onAddVehicle: _showAddVehicleSheet)
              : _VehicleList(
                  vehicles: vehicles,
                  onDelete: _confirmDelete,
                  isDeleting: vehicleState is VehicleDeleting
                      ? (vehicleState).deletingVrn
                      : null,
                ),
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAddVehicle;

  const _EmptyView({required this.onAddVehicle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Vehicles Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to get started.\nWe\'ll fetch details from DVLA automatically.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withAlpha(179),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load vehicles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleList extends ConsumerWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle) onDelete;
  final String? isDeleting;

  const _VehicleList({
    required this.vehicles,
    required this.onDelete,
    this.isDeleting,
  });

  void _showPhotoUploadSheet(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    VehiclePhotoUploadSheet.show(
      context,
      vrn: vehicle.vrn,
      existingPhotoCount: vehicle.photos.length,
      onUpload: ({
        required photoType,
        required photoBytes,
        required contentType,
        onProgress,
      }) async {
        return await ref.read(vehicleStateProvider.notifier).uploadVehiclePhoto(
          vrn: vehicle.vrn,
          photoType: photoType,
          photoBytes: photoBytes,
          contentType: contentType,
          onProgress: onProgress,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VehicleCard(
            vehicle: vehicle,
            onTap: () => context.push('/vehicles/${Uri.encodeComponent(vehicle.vrn)}'),
            onAddPhoto: () => _showPhotoUploadSheet(context, ref, vehicle),
            onDelete: () => onDelete(vehicle),
            isDeleting: isDeleting == vehicle.vrn,
          ),
        );
      },
    );
  }
}
