import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/domain/models/driver_user.dart' as driver_user;
import '../../../profile/application/profile_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/pwa_install_banner.dart';
import '../widgets/home_action_tile.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Drivers'),
        actions: [
          // Theme toggle
          _ThemeToggleButton(),
          const NotificationBellWithPolling(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
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
            Text(
              authService.getGreeting(user),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Show tenant company name if available
            if (profile?.tenant?.companyName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Driving with ${profile!.tenant!.companyName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? RelayColors.darkTextSecondary
                          : RelayColors.lightTextSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 24),

            // Section tiles with progress rings
            HomeActionTile(
              progress: onboardingProgress.profileProgress,
              accentColor: RelayColors.sectionProfile,
              icon: Icons.person_outline,
              onTap: () => context.push(AppRoutes.profile),
            ),
            const SizedBox(height: 12),
            HomeActionTile(
              progress: onboardingProgress.vehicleProgress,
              accentColor: RelayColors.sectionVehicles,
              icon: Icons.directions_car_outlined,
              onTap: () => context.push(AppRoutes.vehicles),
            ),
            const SizedBox(height: 12),
            HomeActionTile(
              progress: onboardingProgress.documentProgress,
              accentColor: RelayColors.sectionDocuments,
              icon: Icons.description_outlined,
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
                'v$appVersion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? RelayColors.darkTextMuted
                          : RelayColors.lightTextMuted,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme toggle button for app bar
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    IconData icon;
    String tooltip;

    switch (themeMode) {
      case AppThemeMode.system:
        icon = Icons.brightness_auto;
        tooltip = 'Theme: System';
      case AppThemeMode.light:
        icon = Icons.light_mode;
        tooltip = 'Theme: Light';
      case AppThemeMode.dark:
        icon = Icons.dark_mode;
        tooltip = 'Theme: Dark';
    }

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () {
        // Cycle through: system -> light -> dark -> system
        final next = switch (themeMode) {
          AppThemeMode.system => AppThemeMode.light,
          AppThemeMode.light => AppThemeMode.dark,
          AppThemeMode.dark => AppThemeMode.system,
        };
        ref.read(themeModeProvider.notifier).setThemeMode(next);
      },
    );
  }
}
