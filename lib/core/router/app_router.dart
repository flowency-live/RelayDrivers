import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/providers.dart';
import '../../features/auth/domain/models/driver_user.dart';
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
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

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
  static const String jobs = '/jobs';
}

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
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

      // If still loading, stay on splash
      if (isLoading) {
        return state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }

      // If not authenticated, redirect to invite entry (unless on public auth pages)
      final isInviteRoute = state.matchedLocation == AppRoutes.inviteEntry;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isPhoneLoginRoute = state.matchedLocation == AppRoutes.phoneLogin;
      final isBiometricRoute = state.matchedLocation == AppRoutes.biometricUnlock;
      final isRegisterRoute = state.matchedLocation == AppRoutes.register;
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;
      final isMagicLinkRoute = state.matchedLocation.startsWith('/auth/verify');
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;
      final isAuthRoute = isInviteRoute || isLoginRoute || isPhoneLoginRoute || isBiometricRoute || isRegisterRoute || isMagicLinkRoute;

      if (!isAuthenticated) {
        // Allow access to auth pages without auth
        if (isAuthRoute) return null;
        // Default to invite entry (invite-only onboarding)
        return AppRoutes.inviteEntry;
      }

      // If authenticated with onboarding status, redirect to onboarding
      // (unless already on onboarding or sub-pages for completing onboarding)
      final isOnboardingStatus = userStatus == DriverStatus.onboarding;
      final isOnboardingSubPage = state.matchedLocation == AppRoutes.profile ||
          state.matchedLocation == AppRoutes.vehicles ||
          state.matchedLocation == AppRoutes.documents;

      if (isOnboardingStatus && !isOnboardingRoute && !isOnboardingSubPage) {
        return AppRoutes.onboarding;
      }

      // If authenticated and on auth pages, redirect appropriately
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
        builder: (context, state) => const InviteEntryPage(),
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
        builder: (context, state) => const OnboardingPage(),
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
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsPage(),
      ),
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => const _PlaceholderPage(
          title: 'Jobs',
          icon: Icons.work,
          description: 'Job management coming soon',
        ),
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
