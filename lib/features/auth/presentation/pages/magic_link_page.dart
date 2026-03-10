import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../domain/models/auth_state.dart';

/// Page shown when verifying a magic link token
class MagicLinkPage extends ConsumerStatefulWidget {
  final String token;

  const MagicLinkPage({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<MagicLinkPage> createState() => _MagicLinkPageState();
}

class _MagicLinkPageState extends ConsumerState<MagicLinkPage> {
  @override
  void initState() {
    super.initState();
    // Verify token on page load
    Future.microtask(() {
      ref.read(authStateProvider.notifier).verifyMagicLink(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Relay Logo
              Image.asset(
                'assets/images/Relay_Logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),

              if (authState is AuthLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Verifying your login...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ] else if (authState is AuthError) ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Login Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  authState.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to login
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text('Return to Login'),
                ),
              ] else if (authState is AuthAuthenticated) ...[
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome back, ${authState.user.firstName}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Redirecting to home...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
