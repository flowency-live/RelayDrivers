import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../application/providers.dart';
import '../../domain/models/otp_models.dart';

/// Phone login page with OTP verification
class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Reset state when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phoneAuthStateProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      ref.read(phoneAuthStateProvider.notifier).requestOtp(phone);
    }
  }

  void _handleResendOtp() {
    if (_resendSeconds == 0) {
      ref.read(phoneAuthStateProvider.notifier).resendOtp();
      _startResendTimer();
    }
  }

  void _handleVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      ref.read(phoneAuthStateProvider.notifier).verifyOtp(otp);
    }
  }

  void _handleChangePhone() {
    _otpController.clear();
    ref.read(phoneAuthStateProvider.notifier).reset();
  }

  Future<void> _offerBiometricSetup() async {
    try {
      // Check if biometrics are available
      final biometricService = ref.read(biometricServiceProvider);
      final isSupported = await biometricService.isDeviceSupported();
      final canCheck = await biometricService.canCheckBiometrics();
      final isAlreadyEnabled = await biometricService.isBiometricEnabled();

      // If biometrics not available or already enabled, just navigate
      if (!isSupported || !canCheck || isAlreadyEnabled) {
        if (mounted) context.go(AppRoutes.home);
        return;
      }

      // Get biometric type name
      final types = await biometricService.getAvailableBiometrics();
      final typeName = biometricService.getBiometricTypeName(types);

      if (!mounted) return;

      // Show dialog to offer biometric setup
      final enableBiometric = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Enable $typeName?'),
          content: Text(
            'Would you like to use $typeName to quickly unlock the app in the future?\n\n'
            'You can change this later in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Enable $typeName'),
            ),
          ],
        ),
      );

      if (enableBiometric == true) {
        // Get the token and enable biometric
        final token = await ref.read(dioClientProvider).getAccessToken();
        if (token != null) {
          await ref.read(biometricAuthStateProvider.notifier).enableBiometric(token);
        }
      }

      // Navigate to home
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      // Biometrics not supported on this platform (web/desktop) - just navigate
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuthState = ref.watch(phoneAuthStateProvider);

    // Listen for success state and navigate
    ref.listen<PhoneAuthState>(phoneAuthStateProvider, (previous, next) {
      if (next is PhoneAuthOtpSent && previous is! PhoneAuthOtpSent) {
        // OTP was sent, start timer and focus OTP field
        _startResendTimer();
        _otpFocusNode.requestFocus();
      }
      if (next is PhoneAuthSuccess) {
        // Auth successful - set authenticated state directly (not checkSession!)
        // Using checkSession() causes AuthLoading which triggers router redirect to splash
        if (next.driver != null) {
          ref.read(authStateProvider.notifier).setAuthenticated(next.driver!);
        }
        // Offer biometric setup, then navigate
        _offerBiometricSetup();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Relay Logo
              Center(
                child: Image.asset(
                  'assets/images/Relay_Logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Relay Drivers',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              _buildSubtitle(phoneAuthState),
              const SizedBox(height: 48),
              _buildContent(phoneAuthState),
              const SizedBox(height: 24),
              // Alternative login methods
              if (phoneAuthState is PhoneAuthInitial ||
                  phoneAuthState is PhoneAuthError) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Prefer email? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign in with email'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Footer
              Text(
                'By signing in, you agree to the Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Version number
              Text(
                'v$appVersion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(PhoneAuthState state) {
    String text;
    if (state is PhoneAuthOtpSent) {
      if (state.isExistingUser && state.displayName != null) {
        text = 'Welcome back, ${state.displayName}!';
      } else {
        text = 'Enter the code sent to your phone';
      }
    } else {
      text = 'Enter your phone number to sign in';
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildContent(PhoneAuthState state) {
    return switch (state) {
      PhoneAuthInitial() => _buildPhoneInput(isLoading: false),
      PhoneAuthChecking() => _buildPhoneInput(isLoading: true),
      PhoneAuthOtpSent() => _buildOtpInput(state),
      PhoneAuthVerifying() => _buildOtpVerifying(),
      PhoneAuthSuccess() => _buildSuccess(state),
      PhoneAuthError() => _buildError(state),
    };
  }

  Widget _buildPhoneInput({required bool isLoading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          enabled: !isLoading,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\+\(\)]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '07XXX XXXXXX',
            prefixIcon: Icon(Icons.phone_outlined),
            prefixText: '+44 ',
          ),
          onFieldSubmitted: (_) => _handleSendOtp(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isLoading ? null : _handleSendOtp,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Send verification code'),
                ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(PhoneAuthOtpSent state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone number display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatPhone(state.phone),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              TextButton(
                onPressed: _handleChangePhone,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // OTP input
        TextFormField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            hintText: '------',
            counterText: '',
            labelText: 'Verification code',
          ),
          maxLength: 6,
          onChanged: (value) {
            if (value.length == 6) {
              _handleVerifyOtp();
            }
          },
          onFieldSubmitted: (_) => _handleVerifyOtp(),
        ),
        const SizedBox(height: 16),
        // Resend button
        TextButton(
          onPressed: _resendSeconds == 0 ? _handleResendOtp : null,
          child: Text(
            _resendSeconds > 0
                ? 'Resend code in $_resendSeconds seconds'
                : 'Resend code',
          ),
        ),
        const SizedBox(height: 24),
        // Verify button
        FilledButton(
          onPressed: _otpController.text.length == 6 ? _handleVerifyOtp : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Verify code'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerifying() {
    return Column(
      children: [
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Verifying...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSuccess(PhoneAuthSuccess state) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.check_circle,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          state.isNewDriver ? 'Welcome!' : 'Welcome back!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildError(PhoneAuthError state) {
    // Determine which input to show based on whether we had OTP sent
    final showOtpInput = _otpController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Show appropriate input
        if (showOtpInput) ...[
          TextFormField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              hintText: '------',
              counterText: '',
            ),
            maxLength: 6,
            onChanged: (value) {
              if (value.length == 6) {
                _handleVerifyOtp();
              }
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _resendSeconds == 0 ? _handleResendOtp : null,
            child: Text(
              _resendSeconds > 0
                  ? 'Resend code in $_resendSeconds seconds'
                  : 'Resend code',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _handleVerifyOtp,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Try again'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _handleChangePhone,
            child: const Text('Use different number'),
          ),
        ] else ...[
          _buildPhoneInput(isLoading: false),
        ],
      ],
    );
  }

  String _formatPhone(String phone) {
    // Format +447XXXXXXXXX as +44 7XXX XXXXXX
    if (phone.startsWith('+44') && phone.length == 13) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 7)} ${phone.substring(7)}';
    }
    return phone;
  }
}
