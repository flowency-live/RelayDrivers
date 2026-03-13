import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/application/providers.dart';
import '../../application/profile_providers.dart';
import '../../domain/models/driver_profile.dart';
import '../widgets/editable_profile_field.dart';

/// Profile page - view and edit driver profile with tap-to-edit fields
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load profile on page load
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
        ProfileError(:final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
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
                  onPressed: () {
                    ref.read(profileStateProvider.notifier).loadProfile();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ProfileLoaded(:final profile) ||
        ProfileSaving(:final profile) =>
          _ProfileContent(profile: profile),
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final DriverProfile profile;

  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(50),
                  child: Text(
                    '${profile.firstName[0]}${profile.lastName[0]}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: profile.status),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Contact Information
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          EditableProfileField(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email,
            editable: false, // Email cannot be changed
            onSave: (_) async => false,
          ),
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
          Text(
            'Address',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 24),

          // Personal Details
          Text(
            'Personal Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          EditableProfileField(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: profile.dateOfBirth,
            editable: false, // DOB set during onboarding
            onSave: (_) async => false,
          ),
          EditableProfileField(
            icon: Icons.badge_outlined,
            label: 'National Insurance',
            value: profile.nationalInsurance,
            masked: true,
            editable: false, // NI set during onboarding
            onSave: (_) async => false,
          ),
          const SizedBox(height: 24),

          // DVLA Driving Licence
          Text(
            'UK Driving Licence',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any field to edit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
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
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green.withAlpha(50);
        textColor = Colors.green;
        break;
      case 'onboarding':
        backgroundColor = Colors.orange.withAlpha(50);
        textColor = Colors.orange;
        break;
      case 'pending':
        backgroundColor = Colors.blue.withAlpha(50);
        textColor = Colors.blue;
        break;
      case 'suspended':
        backgroundColor = Colors.red.withAlpha(50);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withAlpha(50);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
