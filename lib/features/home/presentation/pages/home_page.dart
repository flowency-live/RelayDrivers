import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/domain/models/driver_user.dart' as driver_user;
import '../../../profile/application/profile_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../notifications/application/notification_providers.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../../../vehicles/application/vehicle_providers.dart';
import '../../../documents/application/document_providers.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/components/headers/greeting_header.dart';
import '../../../../core/design_system/components/controls/duty_toggle.dart';
import '../../../../core/design_system/components/cards/job_card.dart';
import '../../../../core/design_system/components/cards/schedule_card.dart';
import '../../../../core/design_system/components/cards/stat_card.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/pwa_install_banner.dart';
import '../widgets/home_action_tile.dart';
import '../widgets/operator_selector.dart';
import '../widgets/status_info_card.dart';

/// Home page - main dashboard for drivers
///
/// Two modes:
/// 1. Onboarding mode: Shows section tiles with progress
/// 2. Active driver mode: Shows duty toggle, current job, schedule, earnings
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isOnDuty = false;
  bool _isDutyLoading = false;

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

  /// Check if user is in active driver mode (completed onboarding)
  bool _isActiveDriver(driver_user.DriverUser user) {
    return user.hasActiveOperators && !user.isOnboarding;
  }

  void _toggleDuty() {
    setState(() => _isDutyLoading = true);
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isOnDuty = !_isOnDuty;
          _isDutyLoading = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Load all data needed for onboarding progress calculation
    Future.microtask(() {
      ref.read(profileStateProvider.notifier).loadProfile();
      ref.read(vehicleStateProvider.notifier).loadVehicles();
      ref.read(documentStateProvider.notifier).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentProfileProvider);
    final onboardingProgress = ref.watch(onboardingProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: DesignColors.accent,
          ),
        ),
      );
    }

    final isActiveDriver = _isActiveDriver(user);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // App bar with minimal actions
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
              elevation: 0,
              title: isActiveDriver
                  ? null
                  : Text(
                      'Relay Drivers',
                      style: TextStyle(
                        color: isDark ? DesignColors.textPrimary : Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: isDark
                            ? null
                            : [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                      ),
                    ),
              actions: [
                _ThemeToggleButton(isDark: isDark),
                _StyledNotificationBell(isDark: isDark),
                if (!isActiveDriver)
                  IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: isDark ? DesignColors.textSecondary : Colors.white,
                      shadows: isDark
                          ? null
                          : [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                    ),
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.phoneLogin);
                      }
                    },
                  ),
              ],
            ),

            // Main content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PWA Install Banner
                  const PwaInstallBanner(),

                  // Operator Selector (only shows if driver has multiple operators)
                  const OperatorSelector(),

                  // Hero greeting header with operational status
                  GreetingHeader(
                    firstName: user.firstName,
                    operatorName: profile?.tenant?.companyName,
                    onNotificationsTap: () =>
                        context.push(AppRoutes.notifications),
                    isOnDuty: _isOnDuty,
                    showDutyStatus: isActiveDriver,
                  ),

                  const SizedBox(height: DesignSpacing.xl),

                  // Show different content based on status
                  if (isActiveDriver)
                    _buildActiveDriverView(context, isDark)
                  else
                    _buildOnboardingView(context, user, profile, onboardingProgress, isDark),

                  const SizedBox(height: DesignSpacing.xl),

                  // Version number
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: DesignSpacing.lg),
                      child: Text(
                        'v$appVersion',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? DesignColors.textMuted
                              : DesignColors.lightTextMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active driver view - duty toggle, current job, schedule, earnings
  Widget _buildActiveDriverView(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
      child: Column(
        children: [
          // Duty toggle
          DutyToggle(
            isOnDuty: _isOnDuty,
            isLoading: _isDutyLoading,
            onToggle: _toggleDuty,
          ),

          const SizedBox(height: DesignSpacing.xxl),

        // Current job or empty state
        // TODO: Wire to actual job data
        if (_isOnDuty)
          CurrentJobCard(
            customerName: 'Edward Blake',
            customerCompany: 'BoardWalk Ltd',
            pickupAddress: '74 Duke Street, Soho',
            pickupTime: 'Pickup in 7 min',
            dropoffAddress: 'Hilton London Metropole',
            dropoffTime: '12 min',
            onCallTap: () {},
            onMessageTap: () {},
            onCardTap: () => context.push(AppRoutes.bookings),
          )
        else
          const NoCurrentJobCard(),

        const SizedBox(height: DesignSpacing.lg),

        // Schedule preview
        // TODO: Wire to actual schedule data
        SchedulePreviewCard(
          items: [
            ScheduleItemData(
              time: '04:45 pm',
              location: 'Heathrow Airport',
              price: '£85',
            ),
            ScheduleItemData(
              time: '07:00 pm',
              location: 'Paddington Station',
              price: '£42',
            ),
            ScheduleItemData(
              time: '09:30 am',
              location: 'Hackney Central',
              price: '£35',
            ),
          ],
          onViewAll: () => context.push(AppRoutes.bookings),
        ),

        const SizedBox(height: DesignSpacing.xl),

        // Earnings today
        // TODO: Wire to actual earnings data
        EarningsTodayCard(
          amount: '£154.20',
          completedJobs: 3,
          trend: '+12%',
          isTrendPositive: true,
          onTap: () => context.push(AppRoutes.earnings),
        ),
        ],
      ),
    );
  }

  /// Onboarding view - section tiles with progress
  Widget _buildOnboardingView(
    BuildContext context,
    driver_user.DriverUser user,
    dynamic profile,
    dynamic onboardingProgress,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
      child: Column(
        children: [
          // Section tiles with progress rings
          HomeActionTile(
            progress: onboardingProgress.profileProgress,
            accentColor: DesignColors.profileAccent,
            icon: Icons.person_outline,
            onTap: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(height: DesignSpacing.lg),
          HomeActionTile(
            progress: onboardingProgress.vehicleProgress,
            accentColor: DesignColors.vehicleAccent,
            icon: Icons.directions_car_outlined,
            onTap: () => context.push(AppRoutes.vehicles),
          ),
          const SizedBox(height: DesignSpacing.lg),
          HomeActionTile(
            progress: onboardingProgress.documentProgress,
            accentColor: DesignColors.documentAccent,
            icon: Icons.description_outlined,
            onTap: () => context.push(AppRoutes.documents),
          ),

          const SizedBox(height: DesignSpacing.xxl),

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
        ],
      ),
    );
  }
}

/// Theme toggle button for app bar with proper contrast
class _ThemeToggleButton extends ConsumerWidget {
  final bool isDark;

  const _ThemeToggleButton({required this.isDark});

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
      icon: Icon(
        icon,
        color: isDark ? DesignColors.textSecondary : Colors.white,
        shadows: isDark
            ? null
            : [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
      ),
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

/// Styled notification bell with proper contrast
class _StyledNotificationBell extends ConsumerWidget {
  final bool isDark;

  const _StyledNotificationBell({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: Icon(
          Icons.notifications_outlined,
          color: isDark ? DesignColors.textSecondary : Colors.white,
          shadows: isDark
              ? null
              : [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
        ),
      ),
      onPressed: () {
        context.push('/notifications');
      },
      tooltip: 'Notifications',
    );
  }
}
