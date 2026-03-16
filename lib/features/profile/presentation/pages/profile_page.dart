import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

          // Personal Details (Locked)
          _SectionHeader(
            title: 'Personal Details',
            isComplete: profile.dateOfBirth != null && profile.nationalInsurance != null,
          ),
          const SizedBox(height: 12),
          LockedProfileField(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: profile.dateOfBirth,
            lockReason: 'Set during onboarding',
          ),
          const SizedBox(height: 8),
          LockedProfileField(
            icon: Icons.badge_outlined,
            label: 'National Insurance',
            value: profile.nationalInsurance,
            masked: true,
            lockReason: 'Set during onboarding',
          ),
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
          EditableProfileField(
            icon: Icons.credit_card_outlined,
            label: 'Licence Number',
            value: profile.dvlaLicenceNumber,
            textCapitalization: TextCapitalization.characters,
            onSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaLicenceNumber: value?.toUpperCase(),
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
          ),
          EditableProfileField(
            icon: Icons.pin_outlined,
            label: 'Check Code',
            value: profile.dvlaCheckCode,
            textCapitalization: TextCapitalization.characters,
            onSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaCheckCode: value?.toUpperCase(),
              );
              return await ref.read(profileStateProvider.notifier).updateProfile(request);
            },
          ),
          EditableProfileField(
            icon: Icons.calendar_today_outlined,
            label: 'Licence Expiry',
            value: profile.dvlaLicenceExpiry,
            onSave: (value) async {
              final request = ProfileUpdateRequest(
                firstName: profile.firstName,
                lastName: profile.lastName,
                dvlaLicenceExpiry: value,
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
}

class _ProfileHeader extends StatelessWidget {
  final DriverProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
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
            child: Center(
              child: Text(
                '${profile.firstName.isNotEmpty ? profile.firstName[0] : '?'}${profile.lastName.isNotEmpty ? profile.lastName[0] : '?'}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: RelayColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
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
