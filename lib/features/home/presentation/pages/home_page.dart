import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/pwa_install_banner.dart';
import '../widgets/status_info_card.dart';

/// Home page - main dashboard for drivers
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load profile to get tenant contact info
    Future.microtask(() {
      ref.read(profileStateProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);
    final profile = ref.watch(currentProfileProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PWA Install Banner
            const PwaInstallBanner(),

            // Greeting
            Text(
              authService.getGreeting(user),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome to Relay Drivers',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Quick actions grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _QuickActionCard(
                  icon: Icons.person,
                  title: 'My Profile',
                  subtitle: 'View and edit details',
                  color: const Color(0xFF4361EE),
                  onTap: () => context.push(AppRoutes.profile),
                ),
                _QuickActionCard(
                  icon: Icons.directions_car,
                  title: 'Vehicles',
                  subtitle: 'Manage your vehicles',
                  color: const Color(0xFF2ECC71),
                  onTap: () => context.push(AppRoutes.vehicles),
                ),
                _QuickActionCard(
                  icon: Icons.description,
                  title: 'Documents',
                  subtitle: 'Upload documents',
                  color: const Color(0xFFF39C12),
                  onTap: () => context.push(AppRoutes.documents),
                ),
                _QuickActionCard(
                  icon: Icons.work,
                  title: 'Jobs',
                  subtitle: 'View available jobs',
                  color: const Color(0xFF9B59B6),
                  onTap: () => context.push(AppRoutes.jobs),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Status card with tenant contact info
            StatusInfoCard(
              status: user.status.value,
              companyName: profile?.tenant?.companyName,
              supportEmail: profile?.tenant?.supportEmail,
              supportPhone: profile?.tenant?.supportPhone,
              onMessageTap: () {
                // TODO: Navigate to support chat when implemented
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support chat coming soon'),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Driver info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Name', value: user.fullName),
                  _InfoRow(label: 'Email', value: user.email),
                  if (user.phone != null)
                    _InfoRow(label: 'Phone', value: user.phone!),
                  _InfoRow(label: 'Driver ID', value: user.driverId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withAlpha(179),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
