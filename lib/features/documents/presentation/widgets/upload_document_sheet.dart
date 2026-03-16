import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../../vehicles/application/vehicle_providers.dart';
import '../../../vehicles/domain/models/vehicle.dart';
import '../../application/document_providers.dart';
import '../../domain/models/document.dart';

/// Bottom sheet for uploading a specific document type
/// Key improvement: No type selector - sheet is scoped to the document user clicked
class UploadDocumentSheet extends ConsumerStatefulWidget {
  final DocumentType documentType;
  final String? preselectedVehicleVrn;

  const UploadDocumentSheet({
    super.key,
    required this.documentType,
    this.preselectedVehicleVrn,
  });

  @override
  ConsumerState<UploadDocumentSheet> createState() =>
      _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedVehicleVrn;
  DateTime? _expiryDate;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  String? _error;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleVrn = widget.preselectedVehicleVrn;
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
  }

  IconData get _documentIcon {
    return switch (widget.documentType) {
      DocumentType.phvDriverLicence => Icons.badge,
      DocumentType.phvVehicleLicence => Icons.directions_car,
      DocumentType.hireRewardInsurance => Icons.security,
    };
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedFileName = picked.name;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image. Please try again.';
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RelayColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: RelayColors.primary),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RelayColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: RelayColors.primary),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: 'Select expiry date',
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageBytes == null) {
      setState(() => _error = 'Please take or select a photo of your document');
      return;
    }

    if (_expiryDate == null) {
      setState(() => _error = 'Please select the document expiry date');
      return;
    }

    // Vehicle documents require a vehicle selection
    if (widget.documentType.isVehicleDocument &&
        widget.documentType != DocumentType.hireRewardInsurance &&
        _selectedVehicleVrn == null) {
      setState(() => _error = 'Please select a vehicle');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    final request = DocumentUploadRequest(
      documentType: widget.documentType,
      expiryDate: _expiryDate!.toIso8601String().split('T')[0],
      vehicleVrn: _selectedVehicleVrn,
      licenseNumber: _licenseNumberController.text.isNotEmpty
          ? _licenseNumberController.text.trim()
          : null,
      issuingAuthority: _issuingAuthorityController.text.isNotEmpty
          ? _issuingAuthorityController.text.trim()
          : null,
    );

    final success = await ref.read(documentStateProvider.notifier).uploadDocument(
          request: request,
          fileBytes: _selectedImageBytes!,
          fileName: _selectedFileName ?? 'document.jpg',
          contentType: 'image/jpeg',
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.documentType.displayName} uploaded successfully',
                ),
              ),
            ],
          ),
          backgroundColor: RelayColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _error = 'Failed to upload document. Please try again.';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final vehicles = ref.watch(vehicleListProvider);
    final documentState = ref.watch(documentStateProvider);

    // Get upload progress
    double? uploadProgress;
    if (documentState is DocumentUploading) {
      uploadProgress = documentState.progress;
    }

    // Check if we need vehicle selection
    final needsVehicle = widget.documentType == DocumentType.phvVehicleLicence;
    final canSelectVehicle = widget.documentType.isVehicleDocument;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Document type header with icon
                  _buildDocumentHeader(),
                  const SizedBox(height: 24),

                  // Vehicle selector (for vehicle documents)
                  if (canSelectVehicle) ...[
                    _buildVehicleSelector(vehicles, needsVehicle),
                    const SizedBox(height: 24),
                  ],

                  // Image picker - prominent call to action
                  _buildImagePicker(),
                  const SizedBox(height: 24),

                  // Expiry date picker
                  _buildExpiryDatePicker(),
                  const SizedBox(height: 24),

                  // Optional fields (collapsed by default)
                  _buildOptionalFields(),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null) ...[
                    _buildErrorMessage(),
                    const SizedBox(height: 16),
                  ],

                  // Upload progress
                  if (uploadProgress != null) ...[
                    _buildUploadProgress(uploadProgress),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  FilledButton(
                    onPressed: _isUploading ? null : _upload,
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text('Upload ${widget.documentType.displayName}'),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RelayColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _documentIcon,
            size: 28,
            color: RelayColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.documentType.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.documentType.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(179),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelector(List<Vehicle> vehicles, bool isRequired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Vehicle',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              Text(
                '(optional for insurance)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(128),
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (vehicles.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RelayColors.warningBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RelayColors.warning.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: RelayColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRequired
                            ? 'Add a vehicle first'
                            : 'No vehicles added yet',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: RelayColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRequired
                            ? 'You need to add a vehicle before uploading a vehicle licence'
                            : 'You can still upload insurance without linking to a specific vehicle',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedVehicleVrn,
            decoration: InputDecoration(
              hintText: 'Select vehicle',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.directions_car_outlined),
            ),
            items: [
              if (!isRequired)
                const DropdownMenuItem(
                  value: null,
                  child: Text('All vehicles / Not specific'),
                ),
              ...vehicles.map((v) {
                return DropdownMenuItem(
                  value: v.vrn,
                  child: Text('${v.vrn} - ${v.displayName}'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _selectedVehicleVrn = value);
            },
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a vehicle';
                    }
                    return null;
                  }
                : null,
          ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Document Photo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: _selectedImageBytes != null
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImageBytes != null
                    ? RelayColors.success
                    : Theme.of(context).colorScheme.outline.withAlpha(50),
                width: _selectedImageBytes != null ? 2 : 1,
                style: _selectedImageBytes != null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: _selectedImageBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // Success overlay
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: RelayColors.success,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Photo selected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Replace button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _showImageSourceDialog,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Replace',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RelayColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_a_photo,
                          size: 32,
                          color: RelayColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to capture or select photo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: RelayColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a clear photo of your document',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withAlpha(128),
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryDatePicker() {
    final hasExpiry = _expiryDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Expiry Date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectExpiryDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasExpiry
                    ? RelayColors.primary.withAlpha(128)
                    : Theme.of(context).colorScheme.outline.withAlpha(50),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: hasExpiry
                      ? RelayColors.primary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasExpiry
                        ? '${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}'
                        : 'Select expiry date',
                    style: TextStyle(
                      color: hasExpiry
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                      fontWeight: hasExpiry ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFields() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          'Additional Details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          'Optional - licence number, issuing authority',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(128),
              ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          TextFormField(
            controller: _licenseNumberController,
            decoration: InputDecoration(
              labelText: 'Licence/Reference Number',
              hintText: 'e.g. PHD123456',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _issuingAuthorityController,
            decoration: InputDecoration(
              labelText: 'Issuing Authority',
              hintText: 'e.g. Bournemouth Council',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.business),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RelayColors.dangerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RelayColors.danger.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: RelayColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: RelayColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(double progress) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: RelayColors.primary.withAlpha(25),
            valueColor: const AlwaysStoppedAnimation<Color>(RelayColors.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uploading... ${(progress * 100).toInt()}%',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: RelayColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
