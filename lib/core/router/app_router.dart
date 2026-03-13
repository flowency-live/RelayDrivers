import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/providers.dart';
import '../../features/auth/domain/models/driver_user.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
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

/// App routes
class AppRoutes {
  static const String splash = '/';
  static const String inviteEntry = '/invite';
  static const String login = '/login';
  static const String phoneLogin = '/login/phone';
  static const String biometricUnlock = '/unlock';
  static const String register = '/register';
  static const String magicLink = '/auth/verify/:token';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String vehicles = '/vehicles';
  static const String documents = '/documents';
  static const String faceRegistration = '/face-registration';
  static const String jobs = '/jobs';
  static const String myOperators = '/my-operators';
  static const String shareDocument = '/documents/share';
  static const String notifications = '/notifications';

  /// Helper to generate share document route with documentId
  static String shareDocumentRoute(String documentId) => '/documents/$documentId/share';
}

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  // Watch onboarding completion to allow dashboard access when complete
  final isOnboardingComplete = ref.watch(isOnboardingCompleteProvider);

  return GoRouter(
    // DO NOT set initialLocation - let GoRouter use the browser URL on web
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

      // Get user status for onboarding check
      final userStatus = authState.maybeWhen(
        authenticated: (user) => user.status,
        orElse: () => null,
      );

      // Check current location and query params
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
      final isOnboardingRoute = currentPath == AppRoutes.onboarding;
      final isAuthRoute = isInviteRoute || isLoginRoute || isPhoneLoginRoute ||
                          isBiometricRoute || isRegisterRoute || isMagicLinkRoute;

      // CRITICAL: If we have an invite code in URL, NEVER redirect away
      // Let the invite page handle it regardless of auth state
      if (isInviteRoute && hasInviteCode) {
        return null; // Stay on invite page with the code
      }

      // If still loading auth state, show splash (but we already handled invite+code above)
      if (isLoading) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      // Not authenticated
      if (!isAuthenticated) {
        // Allow access to auth pages without authentication
        if (isAuthRoute) return null;

        // Redirect everything else to invite entry
        return AppRoutes.inviteEntry;
      }

      // Authenticated - check onboarding status
      // v4.0: Check user.isOnboarding (checks operators array first, legacy fallback)
      final user = authState.maybeWhen(
        authenticated: (u) => u,
        orElse: () => null,
      );

      // Determine if user needs onboarding
      // Priority: check if ANY operator is in 'onboarding' state, then legacy status
      final isOnboardingStatus = user?.isOnboarding ??
          userStatus == DriverStatus.onboarding;

      final isOnboardingSubPage = currentPath == AppRoutes.profile ||
          currentPath == AppRoutes.vehicles ||
          currentPath == AppRoutes.documents ||
          currentPath == AppRoutes.faceRegistration;
      final isHomeRoute = currentPath == AppRoutes.home;
      final isMyOperatorsRoute = currentPath == AppRoutes.myOperators;

      // If onboarding is COMPLETE locally, ALWAYS allow access to home
      // This handles:
      // 1. Backend hasn't updated status yet
      // 2. Existing driver joining new operator (data already exists)
      if (isOnboardingComplete && (isHomeRoute || isMyOperatorsRoute)) {
        return null; // Allow access to home/operators
      }

      // If onboarding status but onboarding is COMPLETE locally, skip to home
      if (isOnboardingStatus && isOnboardingComplete) {
        if (isAuthRoute || isSplashRoute || isOnboardingRoute) {
          return AppRoutes.home;
        }
        return null; // Allow navigation to wherever they want
      }

      // If onboarding status and not complete, keep user in onboarding flow
      if (isOnboardingStatus && !isOnboardingComplete && !isOnboardingRoute && !isOnboardingSubPage) {
        return AppRoutes.onboarding;
      }

      // If authenticated and on auth/splash pages, redirect to appropriate home
      if (isAuthRoute || isSplashRoute) {
        return isOnboardingStatus ? AppRoutes.onboarding : AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.inviteEntry,
        builder: (context, state) {
          // Extract invite code from query parameter for deep linking
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
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingWizardPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.vehicles,
        builder: (context, state) => const VehiclesPage(),
      ),
      GoRoute(
        path: '/vehicles/:vrn',
        builder: (context, state) {
          final vrn = state.pathParameters['vrn'] ?? '';
          return VehicleDetailPage(vrn: vrn);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsPage(),
      ),
      GoRoute(
        path: AppRoutes.faceRegistration,
        builder: (context, state) => const FaceRegistrationPage(),
      ),
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => const _PlaceholderPage(
          title: 'Jobs',
          icon: Icons.work,
          description: 'Job management coming soon',
        ),
      ),
      GoRoute(
        path: AppRoutes.myOperators,
        builder: (context, state) => const MyOperatorsPage(),
      ),
      GoRoute(
        path: '/documents/:documentId/share',
        builder: (context, state) {
          final documentId = state.pathParameters['documentId'] ?? '';
          return ShareDocumentPage(documentId: documentId);
        },
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
