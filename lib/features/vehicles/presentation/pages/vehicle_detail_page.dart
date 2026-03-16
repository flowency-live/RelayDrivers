import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/vehicle_providers.dart';
import '../../domain/models/vehicle.dart';
import '../widgets/vehicle_photo_upload.dart';

/// Page showing vehicle details with photo gallery
class VehicleDetailPage extends ConsumerStatefulWidget {
  final String vrn;

  const VehicleDetailPage({
    super.key,
    required this.vrn,
  });

  @override
  ConsumerState<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends ConsumerState<VehicleDetailPage> {
  bool _isLoadingPhotos = false;
  List<VehiclePhoto> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);
    try {
      final photos =
          await ref.read(vehicleStateProvider.notifier).getVehiclePhotos(widget.vrn);
      setState(() => _photos = photos);
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Vehicle? get _vehicle {
    final state = ref.watch(vehicleStateProvider);
    if (state is VehicleLoaded) {
      return state.vehicles.where((v) => v.vrn == widget.vrn).firstOrNull;
    }
    return null;
  }

  Future<void> _deletePhoto(VehiclePhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
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

    if (confirmed == true) {
      final success = await ref.read(vehicleStateProvider.notifier).deleteVehiclePhoto(
            vrn: widget.vrn,
            photoId: photo.photoId,
          );

      if (success) {
        setState(() {
          _photos.removeWhere((p) => p.photoId == photo.photoId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddPhotoSheet() {
    VehiclePhotoUploadSheet.show(
      context,
      vrn: widget.vrn,
      existingPhotoCount: _photos.length,
      onUpload: ({
        required photoType,
        required photoBytes,
        required contentType,
        onProgress,
      }) async {
        final photo = await ref.read(vehicleStateProvider.notifier).uploadVehiclePhoto(
              vrn: widget.vrn,
              photoType: photoType,
              photoBytes: photoBytes,
              contentType: contentType,
              onProgress: onProgress,
            );
        if (photo != null) {
          setState(() {
            _photos.add(photo);
          });
        }
        return photo;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;
    final theme = Theme.of(context);

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.vrn)),
        body: const Center(child: Text('Vehicle not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.displayName),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPhotos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle info card
            _VehicleInfoCard(vehicle: vehicle),
            const SizedBox(height: 24),

            // Photos section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddPhotoSheet,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Add Photo'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Photo grid
            if (_isLoadingPhotos)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_photos.isEmpty)
              _EmptyPhotosCard(onAddPhoto: _showAddPhotoSheet)
            else
              _PhotoGrid(
                photos: _photos,
                onDelete: _deletePhoto,
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPhotoSheet,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Photo'),
      ),
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleInfoCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VRN badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    vehicle.vrn,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: vehicle.canOperate
                        ? const Color(0xFF2ECC71).withAlpha(25)
                        : const Color(0xFFE63946).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vehicle.canOperate ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: vehicle.canOperate
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFE63946),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.canOperate ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: vehicle.canOperate
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE63946),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Make and colour
            Text(
              vehicle.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (vehicle.colour != null) ...[
              const SizedBox(height: 4),
              Text(
                vehicle.colour!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // MOT and Tax
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusChip(
                    label: 'MOT',
                    value: vehicle.motStatus ?? 'Unknown',
                    isValid: vehicle.motStatus?.toLowerCase() == 'valid',
                    expiryDate: vehicle.motExpiryDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusChip(
                    label: 'Tax',
                    value: vehicle.taxStatus ?? 'Unknown',
                    isValid: vehicle.taxStatus?.toLowerCase() == 'taxed',
                    expiryDate: vehicle.taxDueDate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isValid;
  final String? expiryDate;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.isValid,
    this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isValid ? const Color(0xFF2ECC71) : const Color(0xFFF39C12);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.warning,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (expiryDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expires: ${_formatDate(expiryDate!)}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}

class _EmptyPhotosCard extends StatelessWidget {
  final VoidCallback onAddPhoto;

  const _EmptyPhotosCard({required this.onAddPhoto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onAddPhoto,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: theme.colorScheme.primary.withAlpha(150),
              ),
              const SizedBox(height: 16),
              Text(
                'No photos yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add photos of your vehicle exterior and interior',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<VehiclePhoto> photos;
  final Function(VehiclePhoto) onDelete;

  const _PhotoGrid({
    required this.photos,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _PhotoCard(
          photo: photo,
          onDelete: () => onDelete(photo),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final VehiclePhoto photo;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          Image.network(
            photo.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image,
                color: theme.colorScheme.outline,
                size: 48,
              ),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),

          // Type label
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(180),
                  ],
                ),
              ),
              child: Text(
                photo.type.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(32, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
