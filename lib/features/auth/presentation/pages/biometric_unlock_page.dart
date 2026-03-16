import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../application/providers.dart';

/// Biometric unlock page - shown when session needs biometric verification
class BiometricUnlockPage extends ConsumerStatefulWidget {
  const BiometricUnlockPage({super.key});

  @override
  ConsumerState<BiometricUnlockPage> createState() => _BiometricUnlockPageState();
}

class _BiometricUnlockPageState extends ConsumerState<BiometricUnlockPage> {
  @override
  void initState() {
    super.initState();
    // Automatically prompt for biometric on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptBiometric();
    });
  }

  Future<void> _promptBiometric() async {
    await ref.read(biometricAuthStateProvider.notifier).authenticate();
  }

  void _skipToLogin() {
    ref.read(biometricAuthStateProvider.notifier).skipBiometric();
    context.go(AppRoutes.phoneLogin);
  }

  @override
  Widget build(BuildContext context) {
    final biometricState = ref.watch(biometricAuthStateProvider);
    final biometricAvailability = ref.watch(biometricAvailabilityProvider);

    // Navigate on success
    ref.listen<BiometricAuthState>(biometricAuthStateProvider, (previous, next) {
      if (next is BiometricAuthSuccess) {
        // Trigger session check and navigate
        ref.read(authStateProvider.notifier).checkSession();
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/Relay_Logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              biometricAvailability.when(
                data: (availability) => Text(
                  'Use ${availability.biometricTypeName} to unlock',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 48),
              // Biometric icon and status
              _buildBiometricContent(biometricState),
              const SizedBox(height: 48),
              // Skip to login button
              TextButton(
                onPressed: _skipToLogin,
                child: const Text('Use phone number instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricContent(BiometricAuthState state) {
    return switch (state) {
      BiometricAuthInitial() ||
      BiometricAuthChecking() ||
      BiometricAuthAuthenticating() =>
        _buildLoading(),
      BiometricAuthRequired() => _buildPrompt(),
      BiometricAuthFailed(:final message, :final canRetry) =>
        _buildFailed(message, canRetry),
      BiometricAuthError(:final message) => _buildError(message),
      _ => _buildPrompt(),
    };
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Text(
          'Verifying...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPrompt() {
    return Column(
      children: [
        GestureDetector(
          onTap: _promptBiometric,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _promptBiometric,
          icon: const Icon(Icons.fingerprint),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Unlock with biometric'),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed(String message, bool canRetry) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        if (canRetry) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _promptBiometric,
            icon: const Icon(Icons.refresh),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Try again'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(String message) {
    // Check if this is a session expiry error
    final isSessionExpired = message.toLowerCase().contains('session') ||
        message.toLowerCase().contains('expired');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isSessionExpired
                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                : Theme.of(context).colorScheme.error.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSessionExpired ? Icons.lock_clock : Icons.warning_amber,
            size: 64,
            color: isSessionExpired
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isSessionExpired ? 'Your session has expired' : message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (isSessionExpired) ...[
          const SizedBox(height: 8),
          Text(
            'Please sign in again to continue',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _skipToLogin,
          icon: const Icon(Icons.phone),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Sign in with phone'),
          ),
        ),
      ],
    );
  }
}
