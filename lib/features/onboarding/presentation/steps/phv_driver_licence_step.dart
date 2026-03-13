import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../../domain/models/onboarding_data.dart';
import '../widgets/wizard_scaffold.dart';

/// Phase 1, Step 3: PHV Driver Licence
/// Photo upload and issuing authority selection
class PhvDriverLicenceStep extends ConsumerStatefulWidget {
  const PhvDriverLicenceStep({super.key});

  @override
  ConsumerState<PhvDriverLicenceStep> createState() =>
      _PhvDriverLicenceStepState();
}

class _PhvDriverLicenceStepState extends ConsumerState<PhvDriverLicenceStep> {
  final _licenceNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  String? _selectedAuthority;
  String? _photoPath;
  bool _isUploading = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = ref.read(onboardingWizardProvider).data;
    _licenceNumberController.text = data.phvDriverLicenceNumber ?? '';
    _expiryController.text = data.phvDriverLicenceExpiry ?? '';
    _selectedAuthority = data.phvDriverLicenceAuthority;
    _photoPath = data.phvDriverLicencePhotoPath;
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
        setState(() {
          _photoPath = image.path;
        });
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
        setState(() {
          _photoPath = image.path;
        });
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
                  setState(() {
                    _photoPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final fiveYearsFromNow = DateTime(now.year + 5, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: fiveYearsFromNow,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Select licence expiry date',
    );

    if (picked != null) {
      setState(() {
        _expiryController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  bool get _isValid {
    return _photoPath != null && _selectedAuthority != null;
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isUploading = true);

    try {
      // Upload to backend
      final success = await ref.read(onboardingWizardProvider.notifier).uploadPhvDriverLicence(
            authority: _selectedAuthority!,
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
    final theme = Theme.of(context);

    return WizardScaffold(
      step: WizardStep.phvDriverLicence,
      canGoNext: _isValid,
      onBack: _goBack,
      onNext: _saveAndContinue,
      isLoading: _isUploading,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info banner
          const WizardInfoBanner(
            message:
                'Upload a photo of your PHV driver badge and select your licensing authority',
            icon: Icons.badge,
          ),
          const SizedBox(height: 24),

          // Photo upload area
          _PhotoUploadArea(
            photoPath: _photoPath,
            onTap: _showPhotoOptions,
          ),
          const SizedBox(height: 24),

          // Issuing authority dropdown
          Text(
            'Issuing Authority',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedAuthority,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select licensing authority',
              prefixIcon: Icon(Icons.account_balance),
            ),
            items: PhvAuthorities.authorities.map((authority) {
              return DropdownMenuItem(
                value: authority,
                child: Text(
                  authority,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAuthority = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Optional fields
          WizardTextField(
            controller: _licenceNumberController,
            label: 'Licence/Badge Number (Optional)',
            hint: 'PHV12345',
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

/// Photo upload area widget
class _PhotoUploadArea extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onTap;

  const _PhotoUploadArea({
    this.photoPath,
    required this.onTap,
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
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Photo added',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 2,
            style: BorderStyle.solid,
          ),
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
              child: Icon(
                Icons.add_a_photo,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to add photo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a photo or choose from gallery',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
