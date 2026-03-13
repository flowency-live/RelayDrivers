import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../widgets/wizard_scaffold.dart';

/// Phase 2, Step 2: PHV Vehicle Licence
/// Photo upload for vehicle plate/licence
class PhvVehicleLicenceStep extends ConsumerStatefulWidget {
  const PhvVehicleLicenceStep({super.key});

  @override
  ConsumerState<PhvVehicleLicenceStep> createState() =>
      _PhvVehicleLicenceStepState();
}

class _PhvVehicleLicenceStepState extends ConsumerState<PhvVehicleLicenceStep> {
  final _licenceNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  String? _photoPath;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = ref.read(onboardingWizardProvider).data;
    _licenceNumberController.text = data.phvVehicleLicenceNumber ?? '';
    _expiryController.text = data.phvVehicleLicenceExpiry ?? '';
    _photoPath = data.phvVehicleLicencePhotoPath;
  }

  @override
  void dispose() {
    _licenceNumberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _photoPath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _photoPath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access gallery: $e')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Select expiry date',
    );
    if (picked != null) {
      setState(() {
        _expiryController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  bool get _isValid => _photoPath != null && _expiryController.text.isNotEmpty;
  bool _isUploading = false;

  Future<void> _saveAndContinue() async {
    setState(() => _isUploading = true);

    try {
      final success = await ref.read(onboardingWizardProvider.notifier).uploadPhvVehicleLicence(
            licenceNumber: _licenceNumberController.text.trim(),
            expiryDate: _expiryController.text.trim(),
            photoPath: _photoPath!,
          );

      if (success) {
        ref.read(onboardingWizardProvider.notifier).nextStep();
      } else {
        final error = ref.read(onboardingWizardProvider).error;
        if (mounted && error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _goBack() {
    ref.read(onboardingWizardProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      step: WizardStep.phvVehicleLicence,
      canGoNext: _isValid,
      isLoading: _isUploading,
      onBack: _goBack,
      onNext: _saveAndContinue,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const WizardInfoBanner(
            message: 'Take a clear photo of your PHV vehicle plate/licence',
            icon: Icons.assignment,
          ),
          const SizedBox(height: 24),

          // Photo upload area
          _PhotoUploadArea(
            photoPath: _photoPath,
            onTap: _showPhotoOptions,
            label: 'Vehicle Licence Photo',
          ),
          const SizedBox(height: 24),

          // Optional fields
          WizardTextField(
            controller: _licenceNumberController,
            label: 'Plate/Licence Number (Optional)',
            hint: 'PHV-V12345',
            prefixIcon: Icons.numbers,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),

          WizardTextField(
            controller: _expiryController,
            label: 'Expiry Date (Optional)',
            hint: 'DD/MM/YYYY',
            prefixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _selectExpiryDate,
          ),
        ],
      ),
    );
  }
}

class _PhotoUploadArea extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onTap;
  final String label;

  const _PhotoUploadArea({
    this.photoPath,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (photoPath != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photoPath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Photo added',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo,
                  size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Take a photo or choose from gallery',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
