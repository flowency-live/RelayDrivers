import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/domain/models/driver_user.dart' as driver_user;
import '../../../profile/application/profile_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../../../onboarding/domain/services/onboarding_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/pwa_install_banner.dart';
import '../widgets/operator_selector.dart';
import '../widgets/status_info_card.dart';

/// Home page - main dashboard for drivers
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// Get display status from user model (handles both legacy and new architecture)
  String _getDisplayStatus(driver_user.DriverUser user) {
    // New architecture: derive status from operators
    if (user.operators.isNotEmpty) {
      if (user.hasActiveOperators) return 'active';
      if (user.isOnboarding) return 'onboarding';
      if (user.isPending) return 'pending';
      return 'pending';
    }
    // Legacy fallback
    return user.status?.value ?? 'pending';
  }

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
    final onboardingProgress = ref.watch(onboardingProgressProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate completion status for each section
    final profileComplete = onboardingProgress.phase1Complete;
    final vehiclesComplete = onboardingProgress.steps
        .where((s) => s.id == 'vehicle')
        .any((s) => s.status == OnboardingStepStatus.complete);
    final documentsComplete = onboardingProgress.steps
        .where((s) => s.phase == 1 || s.phase == 2)
        .where((s) => s.id.contains('licence') || s.id.contains('insurance'))
        .every((s) => s.status == OnboardingStepStatus.complete);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Drivers'),
        actions: [
          const NotificationBellWithPolling(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              // Explicitly navigate to phone login after logout
              // Don't rely on router redirect which may cause race conditions
              if (context.mounted) {
                context.go(AppRoutes.phoneLogin);
              }
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

            // Operator Selector (only shows if driver has multiple operators)
            const OperatorSelector(),

            // Greeting
            // TODO(multi-tenant): When supporting multiple operators, this should
            // show the currently active operator's company name. Consider adding
            // an operator context switcher for drivers with multiple operators.
            Text(
              authService.getGreeting(user),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Show tenant company name if available, otherwise just skip (greeting is enough)
            if (profile?.tenant?.companyName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Driving with ${profile!.tenant!.companyName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24),

            // Quick actions - full-width stacked cards with completion status
            _FullWidthActionCard(
              icon: Icons.person,
              title: 'My Profile',
              subtitle: 'View and edit details',
              color: const Color(0xFF4361EE),
              isComplete: profileComplete,
              onTap: () => context.push(AppRoutes.profile),
            ),
            const SizedBox(height: 12),
            _FullWidthActionCard(
              icon: Icons.directions_car,
              title: 'Vehicles',
              subtitle: 'Manage your vehicles',
              color: const Color(0xFF2ECC71),
              isComplete: vehiclesComplete,
              onTap: () => context.push(AppRoutes.vehicles),
            ),
            const SizedBox(height: 12),
            _FullWidthActionCard(
              icon: Icons.description,
              title: 'Documents',
              subtitle: 'Upload documents',
              color: const Color(0xFFF39C12),
              isComplete: documentsComplete,
              onTap: () => context.push(AppRoutes.documents),
            ),

            const SizedBox(height: 32),

            // Status card with tenant contact info
            StatusInfoCard(
              status: _getDisplayStatus(user),
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

            const SizedBox(height: 24),

            // Version number (centered)
            Center(
              child: Text(
                'v1.0.5',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width action card with completion badge
class _FullWidthActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isComplete;
  final VoidCallback onTap;

  const _FullWidthActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isComplete,
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
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
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
              // Completion badge
              _CompletionBadge(isComplete: isComplete),
              const SizedBox(width: 8),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(128),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Completion status badge
class _CompletionBadge extends StatelessWidget {
  final bool isComplete;

  const _CompletionBadge({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? const Color(0xFF2ECC71) : const Color(0xFFF39C12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.pending,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isComplete ? 'Complete' : 'Required',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
