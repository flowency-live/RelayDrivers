import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/vehicle.dart';

/// Widget for uploading vehicle photos with type selection
class VehiclePhotoUpload extends StatefulWidget {
  final String vrn;
  final VehiclePhotoType? initialPhotoType;
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
    this.onComplete,
  });

  @override
  State<VehiclePhotoUpload> createState() => _VehiclePhotoUploadState();
}

class _VehiclePhotoUploadState extends State<VehiclePhotoUpload> {
  final _imagePicker = ImagePicker();
  VehiclePhotoType? _selectedType;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialPhotoType;
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_selectedType == null) {
      setState(() {
        _error = 'Please select a photo type first';
      });
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
        _error = null;
      });

      final bytes = await pickedFile.readAsBytes();
      final contentType = _getContentType(pickedFile.path);

      final photo = await widget.onUpload(
        photoType: _selectedType!,
        photoBytes: bytes,
        contentType: contentType,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (photo != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete?.call();
        }
      } else {
        setState(() {
          _error = 'Failed to upload photo. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
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
        // Photo type selector
        Text(
          'Photo Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VehiclePhotoType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: _isUploading
                  ? null
                  : (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                        _error = null;
                      });
                    },
              selectedColor: theme.colorScheme.primary.withAlpha(50),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

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

        // Upload progress
        if (_isUploading) ...[
          Column(
            children: [
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Upload buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : () => _pickAndUpload(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isUploading ? null : () => _pickAndUpload(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom sheet for selecting photo type and uploading
class VehiclePhotoUploadSheet extends StatelessWidget {
  final String vrn;
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
  });

  static Future<void> show(
    BuildContext context, {
    required String vrn,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
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
          const SizedBox(height: 20),

          // Title
          Text(
            'Add Vehicle Photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a photo type and capture or upload an image',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Upload widget
          VehiclePhotoUpload(
            vrn: vrn,
            onUpload: onUpload,
            onComplete: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
