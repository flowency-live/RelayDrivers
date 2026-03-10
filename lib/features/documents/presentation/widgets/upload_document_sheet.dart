import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../vehicles/application/vehicle_providers.dart';
import '../../application/document_providers.dart';
import '../../domain/models/document.dart';

/// Bottom sheet for uploading a new document
class UploadDocumentSheet extends ConsumerStatefulWidget {
  final DocumentType? preselectedType;

  const UploadDocumentSheet({
    super.key,
    this.preselectedType,
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

  DocumentType? _selectedType;
  String? _selectedVehicleVrn;
  DateTime? _expiryDate;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  String? _error;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
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

    if (_selectedType == null) {
      setState(() => _error = 'Please select a document type');
      return;
    }

    if (_selectedImageBytes == null) {
      setState(() => _error = 'Please select or take a photo of the document');
      return;
    }

    if (_expiryDate == null) {
      setState(() => _error = 'Please select the expiry date');
      return;
    }

    if (_selectedType!.isVehicleDocument && _selectedVehicleVrn == null) {
      setState(() => _error = 'Please select a vehicle');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    final request = DocumentUploadRequest(
      documentType: _selectedType!,
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
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: Color(0xFF2ECC71),
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
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
                        color:
                            Theme.of(context).colorScheme.onSurface.withAlpha(50),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Upload Document',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Document type selector
                  Text(
                    'Document Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DocumentType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                            if (!type.isVehicleDocument) {
                              _selectedVehicleVrn = null;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Vehicle selector (for vehicle documents)
                  if (_selectedType?.isVehicleDocument == true) ...[
                    Text(
                      'Vehicle',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (vehicles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please add a vehicle first before uploading vehicle documents.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVehicleVrn,
                        decoration: InputDecoration(
                          hintText: 'Select vehicle',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v.vrn,
                            child: Text('${v.vrn} - ${v.displayName}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedVehicleVrn = value);
                        },
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Image picker
                  Text(
                    'Document Photo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImageBytes != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withAlpha(50),
                          width: _selectedImageBytes != null ? 2 : 1,
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
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 16,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        setState(() {
                                          _selectedImageBytes = null;
                                          _selectedFileName = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(179),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to take photo or select from gallery',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(179),
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Expiry date picker
                  Text(
                    'Expiry Date',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _selectExpiryDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _expiryDate != null
                          ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                          : 'Select expiry date',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Optional fields
                  Text(
                    'Additional Details (Optional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _licenseNumberController,
                    decoration: InputDecoration(
                      labelText: 'License/Reference Number',
                      hintText: 'e.g. ABC123456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Upload progress
                  if (uploadProgress != null) ...[
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(uploadProgress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  ElevatedButton(
                    onPressed: _isUploading ? null : _upload,
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Upload Document'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
