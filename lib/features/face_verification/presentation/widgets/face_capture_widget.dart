import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget for capturing face images with oval guide overlay
class FaceCaptureWidget extends StatelessWidget {
  final Function(Uint8List imageBytes, String contentType) onImageCaptured;
  final bool isLoading;
  final double? progress;
  final String? errorMessage;

  const FaceCaptureWidget({
    super.key,
    required this.onImageCaptured,
    this.isLoading = false,
    this.progress,
    this.errorMessage,
  });

  Future<void> _captureImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';
      onImageCaptured(bytes, mimeType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Oval face guide area
        Container(
          width: 280,
          height: 350,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(140),
            border: Border.all(
              color: colorScheme.outline.withAlpha(100),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Face placeholder icon
              Icon(
                Icons.face_outlined,
                size: 120,
                color: colorScheme.outline.withAlpha(100),
              ),
              // Loading overlay
              if (isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(140),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (progress != null)
                        CircularProgressIndicator(
                          value: progress,
                          color: Colors.white,
                        )
                      else
                        const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        progress != null
                            ? 'Uploading... ${(progress! * 100).toInt()}%'
                            : 'Processing...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Instructions
        Text(
          'Position your face within the oval',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        // Capture buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera button
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _captureImage(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            // Gallery button
            OutlinedButton.icon(
              onPressed: isLoading ? null : () => _captureImage(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
