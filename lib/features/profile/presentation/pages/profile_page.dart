import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ProfileContentState extends ConsumerState<_ProfileContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAddressAutocomplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

    return Column(
      children: [
        // Profile header (always visible above tabs)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _ProfileHeader(profile: profile),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: RelayColors.primary,
            unselectedLabelColor: isDark ? RelayColors.darkTextMuted : RelayColors.lightTextMuted,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: RelayColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Personal Details'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 18),
                    SizedBox(width: 8),
                    Text('Driving Licence'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalDetailsTab(profile, isDark),
              _buildDrivingLicenceTab(profile, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsTab(DriverProfile profile, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDrivingLicenceTab(DriverProfile profile, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UK Driving Licence Card
          _UkDrivingLicenceCard(
            profile: profile,
            onLicenceNumberSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaLicenceNumber: value,
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
            onCheckCodeSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaCheckCode: value,
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
          ),
          const SizedBox(height: 24),

          // Info card about check code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RelayColors.infoBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: RelayColors.info.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: RelayColors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where to find your check code?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: RelayColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visit gov.uk/view-driving-licence to generate a check code. '
                        'This allows your operator to verify your licence details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? RelayColors.darkTextSecondary : RelayColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

/// UK Driving Licence Card - visual mock styled like the real pink licence
class _UkDrivingLicenceCard extends StatefulWidget {
  final DriverProfile profile;
  final Future<bool> Function(String?) onLicenceNumberSave;
  final Future<bool> Function(String?) onCheckCodeSave;

  const _UkDrivingLicenceCard({
    required this.profile,
    required this.onLicenceNumberSave,
    required this.onCheckCodeSave,
  });

  @override
  State<_UkDrivingLicenceCard> createState() => _UkDrivingLicenceCardState();
}

class _UkDrivingLicenceCardState extends State<_UkDrivingLicenceCard> {
  bool _isEditingLicence = false;
  bool _isEditingCheckCode = false;
  bool _isSavingLicence = false;
  bool _isSavingCheckCode = false;
  late TextEditingController _licenceController;
  late TextEditingController _checkCodeController;
  String? _licenceError;
  String? _checkCodeError;

  // UK Driving Licence pink color
  static const Color _licencePink = Color(0xFFE8A4B8);
  static const Color _licencePinkLight = Color(0xFFF5D0DC);
  static const Color _licencePinkDark = Color(0xFFD4738B);

  @override
  void initState() {
    super.initState();
    _licenceController = TextEditingController(
      text: widget.profile.dvlaLicenceNumber ?? '',
    );
    _checkCodeController = TextEditingController(
      text: _formatCheckCode(widget.profile.dvlaCheckCode),
    );
  }

  @override
  void didUpdateWidget(_UkDrivingLicenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingLicence &&
        oldWidget.profile.dvlaLicenceNumber != widget.profile.dvlaLicenceNumber) {
      _licenceController.text = widget.profile.dvlaLicenceNumber ?? '';
    }
    if (!_isEditingCheckCode &&
        oldWidget.profile.dvlaCheckCode != widget.profile.dvlaCheckCode) {
      _checkCodeController.text = _formatCheckCode(widget.profile.dvlaCheckCode);
    }
  }

  @override
  void dispose() {
    _licenceController.dispose();
    _checkCodeController.dispose();
    super.dispose();
  }

  String _formatCheckCode(String? value) {
    if (value == null || value.isEmpty) return '';
    final cleaned = value.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length && i < 8; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  String _formatLicenceNumber(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.length != 16) return value;
    // Format: XXXXX X XX XX X XXXX
    return '${value.substring(0, 5)} ${value.substring(5, 6)} '
        '${value.substring(6, 8)} ${value.substring(8, 10)} '
        '${value.substring(10, 11)} ${value.substring(11)}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final hasLicence = profile.dvlaLicenceNumber != null &&
        profile.dvlaLicenceNumber!.isNotEmpty;
    final hasCheckCode = profile.dvlaCheckCode != null &&
        profile.dvlaCheckCode!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Licence status
        _SectionHeader(
          title: 'UK Driving Licence',
          isComplete: hasLicence && hasCheckCode,
        ),
        const SizedBox(height: 16),

        // The card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_licencePinkLight, _licencePink, _licencePinkDark],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern (subtle lines like real licence)
              Positioned.fill(
                child: CustomPaint(
                  painter: _LicencePatternPainter(),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // UK flag
                        Container(
                          width: 32,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.black.withAlpha(50),
                              width: 0.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Stack(
                              children: [
                                Container(color: const Color(0xFF00247D)),
                                // Simplified Union Jack
                                Center(
                                  child: Container(
                                    width: 32,
                                    height: 4,
                                    color: Colors.white,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 4,
                                    height: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 32,
                                    height: 2,
                                    color: const Color(0xFFCF142B),
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 2,
                                    height: 22,
                                    color: const Color(0xFFCF142B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'DRIVING LICENCE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D1F3D),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        // DVLA text
                        const Text(
                          'DVLA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D1F3D),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main content row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo placeholder
                        Container(
                          width: 70,
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(180),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF2D1F3D).withAlpha(50),
                              width: 1,
                            ),
                          ),
                          child: profile.profilePhotoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.network(
                                    profile.profilePhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
                                  ),
                                )
                              : _buildPhotoPlaceholder(),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              _buildLicenceField(
                                label: '1. Surname',
                                value: profile.lastName.toUpperCase(),
                              ),
                              const SizedBox(height: 8),
                              _buildLicenceField(
                                label: '2. First names',
                                value: profile.firstName.toUpperCase(),
                              ),
                              const SizedBox(height: 8),
                              _buildLicenceField(
                                label: '3. Date of birth',
                                value: profile.dateOfBirth ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: const Color(0xFF2D1F3D).withAlpha(30),
                    ),
                    const SizedBox(height: 16),

                    // Licence number section
                    _buildLicenceField(
                      label: '5. Driver number',
                      value: null, // Will use custom widget below
                    ),
                    const SizedBox(height: 4),
                    _buildLicenceNumberInput(),

                    const SizedBox(height: 16),

                    // Check code section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLicenceField(
                                label: 'Check code',
                                value: null,
                              ),
                              const SizedBox(height: 4),
                              _buildCheckCodeInput(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (hasLicence && hasCheckCode)
                                ? RelayColors.success.withAlpha(40)
                                : RelayColors.warning.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (hasLicence && hasCheckCode)
                                  ? RelayColors.success
                                  : RelayColors.warning,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (hasLicence && hasCheckCode)
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: (hasLicence && hasCheckCode)
                                    ? RelayColors.success
                                    : RelayColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (hasLicence && hasCheckCode) ? 'Complete' : 'Required',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (hasLicence && hasCheckCode)
                                      ? RelayColors.success
                                      : RelayColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Center(
      child: Icon(
        Icons.person,
        size: 40,
        color: const Color(0xFF2D1F3D).withAlpha(100),
      ),
    );
  }

  Widget _buildLicenceField({required String label, String? value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2D1F3D).withAlpha(150),
            letterSpacing: 0.5,
          ),
        ),
        if (value != null) ...[
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D1F3D),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLicenceNumberInput() {
    final hasValue = widget.profile.dvlaLicenceNumber != null &&
        widget.profile.dvlaLicenceNumber!.isNotEmpty;

    if (_isEditingLicence) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _licenceController,
              enabled: !_isSavingLicence,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D1F3D),
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(200),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: const Color(0xFF2D1F3D).withAlpha(50),
                  ),
                ),
                hintText: '16 characters',
                errorText: _licenceError,
                counterText: '${_licenceController.text.length}/16',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(16),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          if (_isSavingLicence)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            _buildCardButton(
              icon: Icons.check,
              color: RelayColors.success,
              onTap: _saveLicenceNumber,
            ),
            const SizedBox(width: 4),
            _buildCardButton(
              icon: Icons.close,
              color: RelayColors.danger,
              onTap: () {
                setState(() {
                  _isEditingLicence = false;
                  _licenceController.text =
                      widget.profile.dvlaLicenceNumber ?? '';
                  _licenceError = null;
                });
              },
            ),
          ],
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isEditingLicence = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(hasValue ? 150 : 100),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF2D1F3D).withAlpha(50)
                : RelayColors.warning.withAlpha(100),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue
                    ? _formatLicenceNumber(widget.profile.dvlaLicenceNumber)
                    : 'Tap to enter licence number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                  color: hasValue
                      ? const Color(0xFF2D1F3D)
                      : const Color(0xFF2D1F3D).withAlpha(120),
                  letterSpacing: hasValue ? 1.5 : 0,
                  fontFamily: hasValue ? 'monospace' : null,
                ),
              ),
            ),
            Icon(
              Icons.edit,
              size: 16,
              color: const Color(0xFF2D1F3D).withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckCodeInput() {
    final hasValue = widget.profile.dvlaCheckCode != null &&
        widget.profile.dvlaCheckCode!.isNotEmpty;

    if (_isEditingCheckCode) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _checkCodeController,
              enabled: !_isSavingCheckCode,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D1F3D),
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(200),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: const Color(0xFF2D1F3D).withAlpha(50),
                  ),
                ),
                hintText: 'XX XX XX XX',
                errorText: _checkCodeError,
              ),
              onChanged: _onCheckCodeChanged,
            ),
          ),
          const SizedBox(width: 8),
          if (_isSavingCheckCode)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            _buildCardButton(
              icon: Icons.check,
              color: RelayColors.success,
              onTap: _saveCheckCode,
            ),
            const SizedBox(width: 4),
            _buildCardButton(
              icon: Icons.close,
              color: RelayColors.danger,
              onTap: () {
                setState(() {
                  _isEditingCheckCode = false;
                  _checkCodeController.text =
                      _formatCheckCode(widget.profile.dvlaCheckCode);
                  _checkCodeError = null;
                });
              },
            ),
          ],
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isEditingCheckCode = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(hasValue ? 150 : 100),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF2D1F3D).withAlpha(50)
                : RelayColors.warning.withAlpha(100),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue
                    ? _formatCheckCode(widget.profile.dvlaCheckCode)
                    : 'Tap to enter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                  color: hasValue
                      ? const Color(0xFF2D1F3D)
                      : const Color(0xFF2D1F3D).withAlpha(120),
                  letterSpacing: hasValue ? 1.5 : 0,
                  fontFamily: hasValue ? 'monospace' : null,
                ),
              ),
            ),
            Icon(
              Icons.edit,
              size: 16,
              color: const Color(0xFF2D1F3D).withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _onCheckCodeChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final limited = cleaned.length > 8 ? cleaned.substring(0, 8) : cleaned;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    if (formatted != _checkCodeController.text) {
      _checkCodeController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  Future<void> _saveLicenceNumber() async {
    final value = _licenceController.text.trim().toUpperCase().replaceAll(' ', '');

    if (value.isNotEmpty && value.length != 16) {
      setState(() {
        _licenceError = 'Must be exactly 16 characters';
      });
      return;
    }

    setState(() {
      _isSavingLicence = true;
      _licenceError = null;
    });

    try {
      final success = await widget.onLicenceNumberSave(
        value.isEmpty ? null : value,
      );
      if (mounted && success) {
        setState(() {
          _isEditingLicence = false;
          _isSavingLicence = false;
        });
      } else if (mounted) {
        setState(() => _isSavingLicence = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingLicence = false;
          _licenceError = 'Failed to save';
        });
      }
    }
  }

  Future<void> _saveCheckCode() async {
    final value = _checkCodeController.text.replaceAll(' ', '').toUpperCase();

    if (value.isNotEmpty && value.length != 8) {
      setState(() {
        _checkCodeError = 'Must be 8 characters';
      });
      return;
    }

    setState(() {
      _isSavingCheckCode = true;
      _checkCodeError = null;
    });

    try {
      final success = await widget.onCheckCodeSave(
        value.isEmpty ? null : value,
      );
      if (mounted && success) {
        setState(() {
          _isEditingCheckCode = false;
          _isSavingCheckCode = false;
        });
      } else if (mounted) {
        setState(() => _isSavingCheckCode = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingCheckCode = false;
          _checkCodeError = 'Failed to save';
        });
      }
    }
  }
}

/// Custom painter for subtle licence pattern
class _LicencePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
