import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/providers.dart';
import '../../features/auth/presentation/pages/biometric_unlock_page.dart';
import '../../features/auth/presentation/pages/invite_entry_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/magic_link_page.dart';
import '../../features/auth/presentation/pages/phone_login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_wizard_page.dart';
import '../../features/face_verification/presentation/pages/face_registration_page.dart';
import '../../features/profile/presentation/pages/my_operators_page.dart';
import '../../features/documents/presentation/pages/share_document_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../navigation/app_shell.dart';
import '../design_system/tokens/colors.dart';

// Navigator keys for shell branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _bookingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'bookings');
final _earningsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'earnings');
final _calendarNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'calendar');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// App routes
class AppRoutes {
  // Auth routes (outside shell)
  static const String splash = '/';
  static const String inviteEntry = '/invite';
  static const String login = '/login';
  static const String phoneLogin = '/login/phone';
  static const String biometricUnlock = '/unlock';
  static const String register = '/register';
  static const String magicLink = '/auth/verify/:token';

  // Main app routes (inside shell with bottom nav)
  static const String app = '/app';
  static const String home = '/app/home';
  static const String bookings = '/app/bookings';
  static const String bookingDetail = '/app/bookings/:bookingId';
  static const String earnings = '/app/earnings';
  static const String calendar = '/app/calendar';
  static const String profile = '/app/profile';
  static const String profileEdit = '/app/profile/edit';
  static const String vehicles = '/app/profile/vehicles';
  static const String vehicleDetail = '/app/profile/vehicles/:vrn';
  static const String documents = '/app/profile/documents';
  static const String shareDocument = '/app/profile/documents/:documentId/share';
  static const String myOperators = '/app/profile/operators';
  static const String notifications = '/app/profile/notifications';
  static const String faceRegistration = '/app/profile/face-registration';

  // Legacy routes (redirect to new structure)
  static const String legacyHome = '/home';
  static const String legacyProfile = '/profile';
  static const String legacyVehicles = '/vehicles';
  static const String legacyDocuments = '/documents';
  static const String legacyJobs = '/jobs';
  static const String onboarding = '/onboarding';

  /// Helper to generate booking detail route
  static String bookingDetailRoute(String bookingId) => '/app/bookings/$bookingId';

  /// Helper to generate vehicle detail route
  static String vehicleDetailRoute(String vrn) => '/app/profile/vehicles/$vrn';

  /// Helper to generate share document route
  static String shareDocumentRoute(String documentId) =>
      '/app/profile/documents/$documentId/share';
}

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLoading = authState.maybeWhen(
        loading: () => true,
        initial: () => true,
        orElse: () => false,
      );

      final currentPath = state.matchedLocation;
      final hasInviteCode = state.uri.queryParameters.containsKey('code');

      // Define route types
      final isInviteRoute = currentPath == AppRoutes.inviteEntry;
      final isLoginRoute = currentPath == AppRoutes.login;
      final isPhoneLoginRoute = currentPath == AppRoutes.phoneLogin;
      final isBiometricRoute = currentPath == AppRoutes.biometricUnlock;
      final isRegisterRoute = currentPath == AppRoutes.register;
      final isSplashRoute = currentPath == AppRoutes.splash;
      final isMagicLinkRoute = currentPath.startsWith('/auth/verify');
      final isAuthRoute = isInviteRoute ||
          isLoginRoute ||
          isPhoneLoginRoute ||
          isBiometricRoute ||
          isRegisterRoute ||
          isMagicLinkRoute;

      // CRITICAL: If we have an invite code in URL, NEVER redirect away
      if (isInviteRoute && hasInviteCode) {
        return null;
      }

      // If still loading auth state, show splash
      if (isLoading) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      // Not authenticated
      if (!isAuthenticated) {
        if (isAuthRoute) return null;
        return AppRoutes.inviteEntry;
      }

      // AUTHENTICATED
      // Redirect legacy routes to new structure
      if (currentPath == AppRoutes.legacyHome) return AppRoutes.home;
      if (currentPath == AppRoutes.legacyProfile) return AppRoutes.profile;
      if (currentPath == AppRoutes.legacyVehicles) return AppRoutes.vehicles;
      if (currentPath == AppRoutes.legacyDocuments) return AppRoutes.documents;
      if (currentPath == AppRoutes.legacyJobs) return AppRoutes.bookings;

      // If on auth/splash page, go to app
      if (isAuthRoute || isSplashRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.inviteEntry,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return InviteEntryPage(initialCode: code);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.phoneLogin,
        builder: (context, state) => const PhoneLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.biometricUnlock,
        builder: (context, state) => const BiometricUnlockPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/auth/verify/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return MagicLinkPage(token: token);
        },
      ),

      // Onboarding wizard (outside shell, full screen)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingWizardPage(),
      ),

      // Main app with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // Tab 1: Bookings
          StatefulShellBranch(
            navigatorKey: _bookingsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.bookings,
                builder: (context, state) => const _PlaceholderPage(
                  title: 'Bookings',
                  icon: Icons.list_alt_rounded,
                  description: 'Your upcoming and past bookings',
                ),
                routes: [
                  GoRoute(
                    path: ':bookingId',
                    builder: (context, state) {
                      final bookingId = state.pathParameters['bookingId'] ?? '';
                      return _PlaceholderPage(
                        title: 'Booking Detail',
                        icon: Icons.assignment_rounded,
                        description: 'Booking: $bookingId',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Earnings
          StatefulShellBranch(
            navigatorKey: _earningsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.earnings,
                builder: (context, state) => const _PlaceholderPage(
                  title: 'Earnings',
                  icon: Icons.account_balance_wallet_rounded,
                  description: 'Track your earnings by period',
                ),
              ),
            ],
          ),

          // Tab 3: Calendar
          StatefulShellBranch(
            navigatorKey: _calendarNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),

          // Tab 4: Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const ProfilePage(),
                  ),
                  GoRoute(
                    path: 'vehicles',
                    builder: (context, state) => const VehiclesPage(),
                    routes: [
                      GoRoute(
                        path: ':vrn',
                        builder: (context, state) {
                          final vrn = state.pathParameters['vrn'] ?? '';
                          return VehicleDetailPage(vrn: vrn);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const DocumentsPage(),
                    routes: [
                      GoRoute(
                        path: ':documentId/share',
                        builder: (context, state) {
                          final documentId =
                              state.pathParameters['documentId'] ?? '';
                          return ShareDocumentPage(documentId: documentId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'operators',
                    builder: (context, state) => const MyOperatorsPage(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsPage(),
                  ),
                  GoRoute(
                    path: 'face-registration',
                    builder: (context, state) => const FaceRegistrationPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Legacy route redirects (handled by redirect logic above, but keep as fallback)
      GoRoute(
        path: AppRoutes.legacyHome,
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: AppRoutes.legacyProfile,
        redirect: (context, state) => AppRoutes.profile,
      ),
      GoRoute(
        path: AppRoutes.legacyVehicles,
        redirect: (context, state) => AppRoutes.vehicles,
      ),
      GoRoute(
        path: AppRoutes.legacyDocuments,
        redirect: (context, state) => AppRoutes.documents,
      ),
      GoRoute(
        path: AppRoutes.legacyJobs,
        redirect: (context, state) => AppRoutes.bookings,
      ),
      GoRoute(
        path: '/vehicles/:vrn',
        redirect: (context, state) {
          final vrn = state.pathParameters['vrn'] ?? '';
          return AppRoutes.vehicleDetailRoute(vrn);
        },
      ),
      GoRoute(
        path: '/documents/:documentId/share',
        redirect: (context, state) {
          final documentId = state.pathParameters['documentId'] ?? '';
          return AppRoutes.shareDocumentRoute(documentId);
        },
      ),
      GoRoute(
        path: '/my-operators',
        redirect: (context, state) => AppRoutes.myOperators,
      ),
      GoRoute(
        path: '/notifications',
        redirect: (context, state) => AppRoutes.notifications,
      ),
      GoRoute(
        path: '/face-registration',
        redirect: (context, state) => AppRoutes.faceRegistration,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

/// Placeholder page for features not yet implemented
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DesignColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: DesignColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDark
                        ? DesignColors.textPrimary
                        : DesignColors.lightTextPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? DesignColors.textSecondary
                        : DesignColors.lightTextSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
