import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/providers.dart';
// REMOVED: driver_user.dart - no longer needed without onboarding logic
// REMOVED: onboarding_providers.dart - async data doesn't belong in router
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
///
/// IMPORTANT: Router redirect logic ONLY uses synchronous state.
/// Async data loading (profile, vehicles, documents) belongs in pages, not router.
/// This prevents race conditions where router blocks waiting for API calls.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  // REMOVED: isOnboardingCompleteProvider - it depends on 4 async API calls
  // that haven't been made yet when user logs in, causing router to hang.
  // Onboarding UI is handled by home page, not router redirects.

  return GoRouter(
    // DO NOT set initialLocation - let GoRouter use the browser URL on web
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Extract auth state synchronously (no async providers!)
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLoading = authState.maybeWhen(
        loading: () => true,
        initial: () => true,
        orElse: () => false,
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

      // AUTHENTICATED - simple logic:
      // - If on auth/splash page, go to home
      // - Otherwise, allow navigation (home page handles onboarding UI)
      if (isAuthRoute || isSplashRoute) {
        return AppRoutes.home;
      }

      // Allow all navigation for authenticated users
      // Home page will show onboarding tiles if onboarding is incomplete
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
