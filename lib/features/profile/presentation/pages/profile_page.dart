import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../../auth/application/providers.dart';
import '../../../onboarding/domain/models/uk_address.dart';
import '../../../onboarding/presentation/widgets/address_autocomplete_field.dart';
import '../../application/profile_providers.dart';
import '../../domain/models/driver_profile.dart';
import '../widgets/dvla_licence_input.dart';
import '../widgets/editable_profile_field.dart';
import '../widgets/locked_profile_field.dart';

/// Profile page - view and edit driver profile with section-based layout
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileStateProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: switch (profileState) {
        ProfileInitial() || ProfileLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        ProfileError(:final message) => _ErrorView(
            message: message,
            onRetry: () => ref.read(profileStateProvider.notifier).loadProfile(),
          ),
        ProfileLoaded(:final profile) ||
        ProfileSaving(:final profile) =>
          _ProfileContent(profile: profile),
      },
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: RelayColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
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

class _ProfileContent extends ConsumerStatefulWidget {
  final DriverProfile profile;

  const _ProfileContent({required this.profile});

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  bool _showAddressAutocomplete = false;

  void _handleAddressSelected(UkAddress address) {
    // Update all address fields
    final request = ProfileUpdateRequest(
      firstName: widget.profile.firstName,
      lastName: widget.profile.lastName,
      address: address.line1,
      city: address.city,
      postcode: address.postcode,
    );
    ref.read(profileStateProvider.notifier).updateProfile(request);
    setState(() {
      _showAddressAutocomplete = false;
    });
  }

  void _showRequestChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => RequestChangeDialog(
        companyName: widget.profile.tenant?.companyName,
        supportEmail: widget.profile.tenant?.supportEmail,
        supportPhone: widget.profile.tenant?.supportPhone,
        onEmailTap: () {
          final email = widget.profile.tenant?.supportEmail;
          if (email != null) {
            launchUrl(Uri.parse('mailto:$email'));
          }
          Navigator.of(context).pop();
        },
        onPhoneTap: () {
          final phone = widget.profile.tenant?.supportPhone;
          if (phone != null) {
            launchUrl(Uri.parse('tel:$phone'));
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _ProfileHeader(profile: profile),
          const SizedBox(height: 32),

          // Personal Details (Locked after first entry)
          _SectionHeader(
            title: 'Personal Details',
            isComplete: profile.dateOfBirth != null && profile.nationalInsurance != null,
          ),
          const SizedBox(height: 12),
          // DOB: Editable if not set, locked if set
          if (profile.dateOfBirth == null || profile.dateOfBirth!.isEmpty)
            _DateOfBirthField(
              value: profile.dateOfBirth,
              onSave: (value) async {
                final request = ProfileUpdateRequest(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  dateOfBirth: value,
                );
                return await ref.read(profileStateProvider.notifier).updateProfile(request);
              },
            )
          else
            LockedProfileField(
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: profile.dateOfBirth,
              lockReason: 'Contact support to change',
            ),
          const SizedBox(height: 8),
          // NI: Editable if not set, locked if set
          if (profile.nationalInsurance == null || profile.nationalInsurance!.isEmpty)
            EditableProfileField(
              icon: Icons.badge_outlined,
              label: 'National Insurance',
              value: profile.nationalInsurance,
              textCapitalization: TextCapitalization.characters,
              validator: _validateNationalInsurance,
              onSave: (value) async {
                final request = ProfileUpdateRequest(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  nationalInsurance: value,
                );
                return await ref.read(profileStateProvider.notifier).updateProfile(request);
              },
            )
          else
            LockedProfileField(
              icon: Icons.badge_outlined,
              label: 'National Insurance',
              value: profile.nationalInsurance,
              masked: true,
              lockReason: 'Contact support to change',
            ),
          // Only show "Request Changes" if at least one field is locked
          if ((profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) ||
              (profile.nationalInsurance != null && profile.nationalInsurance!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showRequestChangeDialog,
                icon: const Icon(Icons.support_agent, size: 18),
                label: const Text('Request Changes'),
                style: TextButton.styleFrom(
                  foregroundColor: RelayColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Contact Information
          _SectionHeader(
            title: 'Contact Information',
            isComplete: profile.phone != null && profile.phone!.isNotEmpty,
          ),
          const SizedBox(height: 12),
          LockedProfileField(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email,
            lockReason: 'Cannot be changed',
          ),
          const SizedBox(height: 8),
          EditableProfileField(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile.phone,
            keyboardType: TextInputType.phone,
            onSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                phone: value,
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
          ),
          const SizedBox(height: 24),

          // Address
          _SectionHeader(
            title: 'Address',
            isComplete: _isAddressComplete(profile),
            trailing: _showAddressAutocomplete
                ? null
                : TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddressAutocomplete = true;
                      });
                    },
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search'),
                    style: TextButton.styleFrom(
                      foregroundColor: RelayColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Address autocomplete or manual fields
          if (_showAddressAutocomplete) ...[
            AddressAutocompleteField(
              onAddressSelected: _handleAddressSelected,
              initialValue: profile.address,
              hint: 'Search for your address...',
              label: 'Search Address',
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _showAddressAutocomplete = false;
                });
              },
              child: const Text('Enter address manually'),
            ),
          ] else ...[
            EditableProfileField(
              icon: Icons.home_outlined,
              label: 'Address',
              value: profile.address,
              textCapitalization: TextCapitalization.words,
              onSave: (value) async {
                final request = ProfileUpdateRequest(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  address: value,
                );
                return await ref.read(profileStateProvider.notifier).updateProfile(request);
              },
            ),
            EditableProfileField(
              icon: Icons.location_city_outlined,
              label: 'City',
              value: profile.city,
              textCapitalization: TextCapitalization.words,
              onSave: (value) async {
                final request = ProfileUpdateRequest(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  city: value,
                );
                return await ref.read(profileStateProvider.notifier).updateProfile(request);
              },
            ),
            EditableProfileField(
              icon: Icons.pin_outlined,
              label: 'Postcode',
              value: profile.postcode,
              textCapitalization: TextCapitalization.characters,
              onSave: (value) async {
                final request = ProfileUpdateRequest(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  postcode: value?.toUpperCase(),
                );
                return await ref.read(profileStateProvider.notifier).updateProfile(request);
              },
            ),
          ],
          const SizedBox(height: 24),

          // UK Driving Licence
          _SectionHeader(
            title: 'UK Driving Licence',
            isComplete: profile.hasDvlaDetails,
          ),
          const SizedBox(height: 12),
          DvlaLicenceInput(
            initialValue: profile.dvlaLicenceNumber,
            firstName: profile.firstName,
            lastName: profile.lastName,
            dateOfBirth: profile.dateOfBirth,
            onSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaLicenceNumber: value,
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
          ),
          const SizedBox(height: 8),
          _DvlaCheckCodeField(
            value: profile.dvlaCheckCode,
            onSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaCheckCode: value,
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  bool _isAddressComplete(DriverProfile profile) {
    return profile.address != null &&
        profile.address!.isNotEmpty &&
        profile.city != null &&
        profile.city!.isNotEmpty &&
        profile.postcode != null &&
        profile.postcode!.isNotEmpty;
  }

  /// Validate UK National Insurance number format
  /// Format: 2 letters, 6 numbers, 1 letter (e.g., AB123456C)
  String? _validateNationalInsurance(String? value) {
    if (value == null || value.isEmpty) {
      return 'National Insurance number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\s'), '').toUpperCase();
    // UK NI format: 2 prefix letters, 6 digits, 1 suffix letter
    final niRegex = RegExp(r'^[A-Z]{2}\d{6}[A-Z]$');
    if (!niRegex.hasMatch(cleaned)) {
      return 'Format: AB123456C';
    }
    return null;
  }
}

/// Date of Birth field with date picker
class _DateOfBirthField extends StatefulWidget {
  final String? value;
  final Future<bool> Function(String?) onSave;

  const _DateOfBirthField({
    required this.value,
    required this.onSave,
  });

  @override
  State<_DateOfBirthField> createState() => _DateOfBirthFieldState();
}

class _DateOfBirthFieldState extends State<_DateOfBirthField> {
  bool _isSaving = false;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    // Must be at least 17 years old to be a driver
    final maxDate = DateTime(now.year - 17, now.month, now.day);
    // Oldest possible date
    final minDate = DateTime(now.year - 100);

    final initialDate = widget.value != null
        ? _parseDate(widget.value!)
        : DateTime(now.year - 30, 1, 1);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(maxDate) ? initialDate : maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select your date of birth',
    );

    if (selectedDate != null && mounted) {
      setState(() => _isSaving = true);
      // Format as DD/MM/YYYY for UK format
      final formatted = '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
      await widget.onSave(formatted);
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  DateTime _parseDate(String value) {
    // Try DD/MM/YYYY format first
    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime(1990, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _isSaving ? null : _selectDate,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    widget.value ?? 'Tap to set',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.value == null
                          ? theme.textTheme.bodySmall?.color
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (_isSaving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.edit,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}

/// DVLA Check Code field with input mask (XX XX XX XX format)
class _DvlaCheckCodeField extends StatefulWidget {
  final String? value;
  final Future<bool> Function(String?) onSave;

  const _DvlaCheckCodeField({
    required this.value,
    required this.onSave,
  });

  @override
  State<_DvlaCheckCodeField> createState() => _DvlaCheckCodeFieldState();
}

class _DvlaCheckCodeFieldState extends State<_DvlaCheckCodeField> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatForDisplay(widget.value));
  }

  @override
  void didUpdateWidget(_DvlaCheckCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = _formatForDisplay(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Format stored value (no spaces) for display (with spaces)
  String _formatForDisplay(String? value) {
    if (value == null || value.isEmpty) return '';
    // Remove any existing spaces and format as XX XX XX XX
    final cleaned = value.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length && i < 8; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  /// Remove spaces for storage
  String _formatForStorage(String value) {
    return value.replaceAll(' ', '').toUpperCase();
  }

  /// Apply input mask as user types
  void _onChanged(String value) {
    // Remove all spaces and non-alphanumeric chars
    final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    // Limit to 8 characters
    final limited = cleaned.length > 8 ? cleaned.substring(0, 8) : cleaned;

    // Format with spaces
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    if (formatted != _controller.text) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = _formatForDisplay(widget.value);
      _errorText = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = _formatForDisplay(widget.value);
      _errorText = null;
    });
  }

  Future<void> _save() async {
    final cleaned = _formatForStorage(_controller.text);

    // Validate: must be exactly 8 alphanumeric characters
    if (cleaned.isNotEmpty && cleaned.length != 8) {
      setState(() {
        _errorText = 'Must be 8 characters (e.g., HV CY J9 TC)';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final success = await widget.onSave(cleaned.isEmpty ? null : cleaned);
      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
        } else {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = 'Failed to save';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.pin_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check Code',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    enabled: !_isSaving,
                    onChanged: _onChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'XX XX XX XX',
                      errorText: _errorText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isSaving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                ),
                onPressed: _save,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.error,
                ),
                onPressed: _cancelEditing,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _startEditing,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              Icons.pin_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check Code',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    widget.value != null && widget.value!.isNotEmpty
                        ? _formatForDisplay(widget.value)
                        : 'Not set',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.value == null || widget.value!.isEmpty
                          ? theme.textTheme.bodySmall?.color
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  final DriverProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  final _imagePicker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUploadPhoto() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final contentType = _getContentType(pickedFile.path);

      final photoUrl = await ref.read(profileStateProvider.notifier).uploadProfilePhoto(
        photoBytes: bytes,
        contentType: contentType,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (mounted) {
        if (photoUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.profile;

    return Center(
      child: Column(
        children: [
          // Profile photo with edit overlay
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadPhoto,
            child: Stack(
              children: [
                // Photo or initials
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RelayColors.primary.withAlpha(isDark ? 40 : 25),
                    border: Border.all(
                      color: RelayColors.primary.withAlpha(isDark ? 80 : 50),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: profile.profilePhotoUrl != null
                        ? Image.network(
                            profile.profilePhotoUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitials(context, profile),
                          )
                        : _buildInitials(context, profile),
                  ),
                ),
                // Upload progress overlay
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha(128),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                // Edit button
                if (!_isUploading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RelayColors.primary,
                        border: Border.all(
                          color: isDark ? RelayColors.darkSurface1 : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          _StatusBadge(status: profile.status),
        ],
      ),
    );
  }

  Widget _buildInitials(BuildContext context, DriverProfile profile) {
    return Center(
      child: Text(
        '${profile.firstName.isNotEmpty ? profile.firstName[0] : '?'}${profile.lastName.isNotEmpty ? profile.lastName[0] : '?'}',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: RelayColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isComplete;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.isComplete,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark
                    ? RelayColors.darkTextSecondary
                    : RelayColors.lightTextSecondary,
              ),
        ),
        const SizedBox(width: 8),
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isComplete ? RelayColors.success : RelayColors.warning,
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = switch (status.toLowerCase()) {
      'active' => (RelayColors.successBackground, RelayColors.success),
      'onboarding' => (RelayColors.warningBackground, RelayColors.warning),
      'pending' => (RelayColors.infoBackground, RelayColors.info),
      'suspended' => (RelayColors.dangerBackground, RelayColors.danger),
      _ => (RelayColors.darkBorderSubtle, RelayColors.darkTextMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: textColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
