import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../domain/models/vehicle.dart';

/// Photo upload configuration constants
class PhotoUploadConfig {
  /// Maximum file size before compression (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Maximum dimension for compressed images
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;

  /// JPEG compression quality (0-100)
  static const int compressionQuality = 85;

  /// Recommended photo count per vehicle
  static const int recommendedPhotoCount = 5;

  /// Maximum photos per vehicle
  static const int maxPhotosPerVehicle = 10;

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Represents a photo queued for upload
class QueuedPhoto {
  final String id;
  final Uint8List bytes;
  final String contentType;
  final VehiclePhotoType? type;
  final String filename;
  final int originalSize;

  QueuedPhoto({
    required this.id,
    required this.bytes,
    required this.contentType,
    required this.filename,
    required this.originalSize,
    this.type,
  });

  QueuedPhoto copyWith({VehiclePhotoType? type}) {
    return QueuedPhoto(
      id: id,
      bytes: bytes,
      contentType: contentType,
      filename: filename,
      originalSize: originalSize,
      type: type ?? this.type,
    );
  }
}

/// Upload state for batch uploads
enum UploadItemState { pending, uploading, success, failed }

class UploadItem {
  final QueuedPhoto photo;
  final UploadItemState state;
  final double progress;
  final String? error;

  UploadItem({
    required this.photo,
    this.state = UploadItemState.pending,
    this.progress = 0,
    this.error,
  });

  UploadItem copyWith({
    UploadItemState? state,
    double? progress,
    String? error,
  }) {
    return UploadItem(
      photo: photo,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// Widget for uploading vehicle photos with multi-select and validation
class VehiclePhotoUpload extends StatefulWidget {
  final String vrn;
  final VehiclePhotoType? initialPhotoType;
  final int existingPhotoCount;
  final Future<VehiclePhoto?> Function({
    required VehiclePhotoType photoType,
    required Uint8List photoBytes,
    required String contentType,
    Function(double)? onProgress,
  }) onUpload;
  final VoidCallback? onComplete;

  const VehiclePhotoUpload({
    super.key,
    required this.vrn,
    required this.onUpload,
    this.initialPhotoType,
    this.existingPhotoCount = 0,
    this.onComplete,
  });

  @override
  State<VehiclePhotoUpload> createState() => _VehiclePhotoUploadState();
}

class _VehiclePhotoUploadState extends State<VehiclePhotoUpload> {
  final _imagePicker = ImagePicker();
  List<QueuedPhoto> _queuedPhotos = [];
  List<UploadItem> _uploadItems = [];
  bool _isUploading = false;
  String? _error;
  int _successCount = 0;
  int _failCount = 0;

  int get _totalPhotoCount => widget.existingPhotoCount + _queuedPhotos.length;
  bool get _canAddMore => _totalPhotoCount < PhotoUploadConfig.maxPhotosPerVehicle;

  Future<void> _pickPhotos(ImageSource source) async {
    if (!_canAddMore) {
      setState(() {
        _error = 'Maximum ${PhotoUploadConfig.maxPhotosPerVehicle} photos per vehicle';
      });
      return;
    }

    try {
      List<XFile> pickedFiles = [];

      if (source == ImageSource.gallery) {
        // Multi-select from gallery
        pickedFiles = await _imagePicker.pickMultiImage(
          maxWidth: PhotoUploadConfig.maxImageWidth,
          maxHeight: PhotoUploadConfig.maxImageHeight,
          imageQuality: PhotoUploadConfig.compressionQuality,
        );
      } else {
        // Single photo from camera
        final file = await _imagePicker.pickImage(
          source: source,
          maxWidth: PhotoUploadConfig.maxImageWidth,
          maxHeight: PhotoUploadConfig.maxImageHeight,
          imageQuality: PhotoUploadConfig.compressionQuality,
        );
        if (file != null) {
          pickedFiles = [file];
        }
      }

      if (pickedFiles.isEmpty) return;

      // Calculate how many we can add
      final slotsAvailable = PhotoUploadConfig.maxPhotosPerVehicle - _totalPhotoCount;
      final filesToProcess = pickedFiles.take(slotsAvailable).toList();

      if (filesToProcess.length < pickedFiles.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only ${filesToProcess.length} of ${pickedFiles.length} photos added (limit: ${PhotoUploadConfig.maxPhotosPerVehicle})',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      setState(() => _error = null);

      // Process each file
      final newPhotos = <QueuedPhoto>[];
      for (final file in filesToProcess) {
        final bytes = await file.readAsBytes();
        final originalSize = bytes.length;

        // Validate file size (after compression)
        if (originalSize > PhotoUploadConfig.maxFileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${file.name}: File too large (${PhotoUploadConfig.formatFileSize(originalSize)}). Max: ${PhotoUploadConfig.formatFileSize(PhotoUploadConfig.maxFileSizeBytes)}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          continue;
        }

        newPhotos.add(QueuedPhoto(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          bytes: bytes,
          contentType: _getContentType(file.path),
          filename: file.name,
          originalSize: originalSize,
          type: widget.initialPhotoType,
        ));
      }

      setState(() {
        _queuedPhotos.addAll(newPhotos);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load images: $e';
      });
    }
  }

  void _removeQueuedPhoto(String id) {
    setState(() {
      _queuedPhotos.removeWhere((p) => p.id == id);
    });
  }

  void _updatePhotoType(String id, VehiclePhotoType type) {
    setState(() {
      _queuedPhotos = _queuedPhotos.map((p) {
        if (p.id == id) {
          return p.copyWith(type: type);
        }
        return p;
      }).toList();
    });
  }

  Future<void> _uploadAll() async {
    // Validate all photos have types
    final missingTypes = _queuedPhotos.where((p) => p.type == null).length;
    if (missingTypes > 0) {
      setState(() {
        _error = 'Please select a type for all photos ($missingTypes remaining)';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _successCount = 0;
      _failCount = 0;
      _uploadItems = _queuedPhotos
          .map((p) => UploadItem(photo: p))
          .toList();
    });

    // Upload each photo sequentially
    for (int i = 0; i < _uploadItems.length; i++) {
      final item = _uploadItems[i];

      setState(() {
        _uploadItems[i] = item.copyWith(state: UploadItemState.uploading);
      });

      try {
        final photo = await widget.onUpload(
          photoType: item.photo.type!,
          photoBytes: item.photo.bytes,
          contentType: item.photo.contentType,
          onProgress: (progress) {
            setState(() {
              _uploadItems[i] = _uploadItems[i].copyWith(progress: progress);
            });
          },
        );

        if (photo != null) {
          setState(() {
            _uploadItems[i] = _uploadItems[i].copyWith(
              state: UploadItemState.success,
              progress: 1.0,
            );
            _successCount++;
          });
        } else {
          setState(() {
            _uploadItems[i] = _uploadItems[i].copyWith(
              state: UploadItemState.failed,
              error: 'Upload failed',
            );
            _failCount++;
          });
        }
      } catch (e) {
        setState(() {
          _uploadItems[i] = _uploadItems[i].copyWith(
            state: UploadItemState.failed,
            error: e.toString(),
          );
          _failCount++;
        });
      }
    }

    setState(() {
      _isUploading = false;
    });

    // Show completion message
    if (mounted) {
      if (_failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_successCount photo${_successCount == 1 ? '' : 's'} uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onComplete?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded $_successCount, failed $_failCount'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _getContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Photo guidelines
        _PhotoGuidelines(
          existingCount: widget.existingPhotoCount,
          queuedCount: _queuedPhotos.length,
        ),
        const SizedBox(height: 16),

        // Error message
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withAlpha(76),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Queued photos preview
        if (_queuedPhotos.isNotEmpty && !_isUploading) ...[
          Text(
            'Selected Photos (${_queuedPhotos.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _queuedPhotos.length,
              itemBuilder: (context, index) {
                final photo = _queuedPhotos[index];
                return _QueuedPhotoCard(
                  photo: photo,
                  onRemove: () => _removeQueuedPhoto(photo.id),
                  onTypeChanged: (type) => _updatePhotoType(photo.id, type),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Upload progress
        if (_isUploading) ...[
          Text(
            'Uploading...',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_uploadItems.length, (index) {
            final item = _uploadItems[index];
            return _UploadProgressItem(item: item);
          }),
          const SizedBox(height: 16),
        ],

        // Action buttons
        if (!_isUploading) ...[
          // Add photos buttons
          if (_canAddMore)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhotos(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhotos(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

          // Upload button
          if (_queuedPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _uploadAll,
              icon: const Icon(Icons.cloud_upload),
              label: Text('Upload ${_queuedPhotos.length} Photo${_queuedPhotos.length == 1 ? '' : 's'}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Photo guidelines showing requirements
class _PhotoGuidelines extends StatelessWidget {
  final int existingCount;
  final int queuedCount;

  const _PhotoGuidelines({
    required this.existingCount,
    required this.queuedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalCount = existingCount + queuedCount;
    final isComplete = totalCount >= PhotoUploadConfig.recommendedPhotoCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete
            ? RelayColors.successBackground
            : (isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete
              ? RelayColors.success.withAlpha(80)
              : (isDark ? RelayColors.darkBorderSubtle : RelayColors.lightBorderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: isComplete ? RelayColors.success : RelayColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                'Photo Requirements',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isComplete ? RelayColors.success : null,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isComplete
                      ? RelayColors.success.withAlpha(25)
                      : RelayColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount/${PhotoUploadConfig.recommendedPhotoCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? RelayColors.success : RelayColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add ${PhotoUploadConfig.recommendedPhotoCount} photos: Front, Rear, Side, Interior, Dashboard',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? RelayColors.darkTextSecondary : RelayColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Max ${PhotoUploadConfig.formatFileSize(PhotoUploadConfig.maxFileSizeBytes)} per photo. JPEG, PNG, or WebP.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? RelayColors.darkTextMuted : RelayColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing a queued photo with type selector
class _QueuedPhotoCard extends StatelessWidget {
  final QueuedPhoto photo;
  final VoidCallback onRemove;
  final Function(VehiclePhotoType) onTypeChanged;

  const _QueuedPhotoCard({
    required this.photo,
    required this.onRemove,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: photo.type == null
              ? theme.colorScheme.error.withAlpha(150)
              : theme.colorScheme.outline.withAlpha(76),
          width: photo.type == null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  child: Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                  ),
                ),
                // Remove button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // File size
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      PhotoUploadConfig.formatFileSize(photo.bytes.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Type selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VehiclePhotoType>(
                value: photo.type,
                hint: Text(
                  'Select type',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.error,
                  ),
                ),
                isExpanded: true,
                isDense: true,
                style: theme.textTheme.bodySmall,
                items: VehiclePhotoType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (type) {
                  if (type != null) {
                    onTypeChanged(type);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress indicator for uploading item
class _UploadProgressItem extends StatelessWidget {
  final UploadItem item;

  const _UploadProgressItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color) = switch (item.state) {
      UploadItemState.pending => (Icons.hourglass_empty, Colors.grey),
      UploadItemState.uploading => (Icons.cloud_upload, RelayColors.primary),
      UploadItemState.success => (Icons.check_circle, RelayColors.success),
      UploadItemState.failed => (Icons.error, RelayColors.danger),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              item.photo.bytes,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.photo.type?.label ?? 'Unknown',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.state == UploadItemState.uploading)
                  LinearProgressIndicator(value: item.progress)
                else if (item.error != null)
                  Text(
                    item.error!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status icon
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting and uploading photos
class VehiclePhotoUploadSheet extends StatelessWidget {
  final String vrn;
  final int existingPhotoCount;
  final Future<VehiclePhoto?> Function({
    required VehiclePhotoType photoType,
    required Uint8List photoBytes,
    required String contentType,
    Function(double)? onProgress,
  }) onUpload;

  const VehiclePhotoUploadSheet({
    super.key,
    required this.vrn,
    required this.onUpload,
    this.existingPhotoCount = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required String vrn,
    int existingPhotoCount = 0,
    required Future<VehiclePhoto?> Function({
      required VehiclePhotoType photoType,
      required Uint8List photoBytes,
      required String contentType,
      Function(double)? onProgress,
    }) onUpload,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => VehiclePhotoUploadSheet(
        vrn: vrn,
        onUpload: onUpload,
        existingPhotoCount: existingPhotoCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withAlpha(76),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Add Vehicle Photos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select multiple photos from gallery or take photos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),

              // Upload widget
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: VehiclePhotoUpload(
                    vrn: vrn,
                    onUpload: onUpload,
                    existingPhotoCount: existingPhotoCount,
                    onComplete: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
