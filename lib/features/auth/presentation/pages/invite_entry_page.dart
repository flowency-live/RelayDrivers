import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/pwa_install_banner.dart';
import '../../application/providers.dart';
import '../../domain/models/invite_models.dart';

/// Invite code entry page - first screen for new drivers
class InviteEntryPage extends ConsumerStatefulWidget {
  final String? initialCode;

  const InviteEntryPage({super.key, this.initialCode});

  @override
  ConsumerState<InviteEntryPage> createState() => _InviteEntryPageState();
}

class _InviteEntryPageState extends ConsumerState<InviteEntryPage> {
  final _codeController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      // Auto-verify if code is pre-filled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVerifyCode();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    _codeFocusNode.dispose();
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

  void _handleVerifyCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      ref.read(inviteAuthStateProvider.notifier).verifyInvite(code);
    }
  }

  void _handleRequestOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      ref.read(inviteAuthStateProvider.notifier).requestOtp(phone);
      _startResendTimer();
    }
  }

  void _handleResendOtp() {
    if (_resendSeconds == 0) {
      ref.read(inviteAuthStateProvider.notifier).resendOtp();
      _startResendTimer();
    }
  }

  void _handleClaimInvite() {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      ref.read(inviteAuthStateProvider.notifier).claimInvite(otp);
    }
  }

  void _handleReset() {
    _codeController.clear();
    _otpController.clear();
    _phoneController.clear();
    ref.read(inviteAuthStateProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inviteAuthStateProvider);
    final theme = Theme.of(context);

    ref.listen<InviteAuthState>(inviteAuthStateProvider, (previous, next) {
      if (next is InviteAuthSuccess) {
        // Update main auth state with the authenticated user
        ref.read(authStateProvider.notifier).setAuthenticated(next.driver);
        // Reset invite state to prevent re-triggering on rebuild
        ref.read(inviteAuthStateProvider.notifier).reset();
        // Navigate to home (router will handle onboarding redirect if needed)
        context.go(AppRoutes.home);
      } else if (next is InviteAuthOtpSent) {
        // Focus OTP field when OTP is sent
        _otpFocusNode.requestFocus();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Relay'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PWA Install Banner
              const PwaInstallBanner(),
              const SizedBox(height: 16),

              // Logo/Branding
              Container(
                height: 100,
                width: 100,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/Relay_Logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // Build content based on state
              _buildContent(state, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(InviteAuthState state, ThemeData theme) {
    return switch (state) {
      InviteAuthInitial() => _buildCodeEntry(theme),
      InviteAuthVerifying() => _buildLoading('Verifying invite code...'),
      InviteAuthVerified(:final firstName, :final lastName, :final maskedPhone, :final companyName) =>
        _buildVerified(theme, firstName, lastName, maskedPhone, companyName),
      InviteAuthOtpSent(:final firstName, :final companyName) => _buildOtpEntry(theme, firstName, companyName),
      InviteAuthClaiming() => _buildLoading('Verifying...'),
      InviteAuthSuccess() => _buildLoading('Welcome! Setting up...'),
      InviteAuthError(:final message, :final isExpired, :final isUsed) =>
        _buildError(theme, message, isExpired, isUsed),
    };
  }

  Widget _buildCodeEntry(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Your Invite Code',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your operator sent you an invite code via SMS. Enter it below to get started.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Code input field
        TextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          decoration: InputDecoration(
            labelText: 'Invite Code',
            hintText: 'DRV-XXXXXXXX',
            prefixIcon: const Icon(Icons.confirmation_number),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
            UpperCaseTextFormatter(),
          ],
          onSubmitted: (_) => _handleVerifyCode(),
        ),
        const SizedBox(height: 24),

        // Verify button
        FilledButton(
          onPressed: _handleVerifyCode,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Continue'),
          ),
        ),
        const SizedBox(height: 16),

        // Already have an account link
        TextButton(
          onPressed: () => context.go(AppRoutes.phoneLogin),
          child: const Text('Already have an account? Sign in'),
        ),
        const SizedBox(height: 16),
        // Version number
        Text(
          'v$appVersion',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Widget _buildVerified(
    ThemeData theme,
    String firstName,
    String lastName,
    String maskedPhone,
    String? companyName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, $firstName!',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                companyName != null
                    ? 'You\'ve been invited to drive with $companyName.'
                    : 'We found your account. Enter your phone number to continue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Phone on file: $maskedPhone',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone input
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '07XXX XXXXXX',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          onSubmitted: (_) => _handleRequestOtp(),
        ),
        const SizedBox(height: 24),

        // Request OTP button
        FilledButton(
          onPressed: _handleRequestOtp,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Send Verification Code'),
          ),
        ),
        const SizedBox(height: 16),

        // Back button
        TextButton(
          onPressed: _handleReset,
          child: const Text('Use Different Invite Code'),
        ),
        const SizedBox(height: 16),
        // Version number
        Text(
          'v$appVersion',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Widget _buildOtpEntry(ThemeData theme, String firstName, String? companyName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Verification Code',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to your phone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (companyName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Joining $companyName',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),

        // OTP input with autofill hint for SMS autofill (iOS/Android)
        TextField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            hintText: '000000',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            letterSpacing: 8,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (value) {
            if (value.length == 6) {
              _handleClaimInvite();
            }
          },
        ),
        const SizedBox(height: 24),

        // Verify button
        FilledButton(
          onPressed: _otpController.text.length == 6 ? _handleClaimInvite : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Verify'),
          ),
        ),
        const SizedBox(height: 16),

        // Resend button
        TextButton(
          onPressed: _resendSeconds == 0 ? _handleResendOtp : null,
          child: Text(
            _resendSeconds > 0
                ? 'Resend code in ${_resendSeconds}s'
                : 'Resend Code',
          ),
        ),
        const SizedBox(height: 8),

        // Back button
        TextButton(
          onPressed: _handleReset,
          child: const Text('Use Different Phone Number'),
        ),
      ],
    );
  }

  Widget _buildLoading(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(message),
      ],
    );
  }

  Widget _buildError(
    ThemeData theme,
    String message,
    bool isExpired,
    bool isUsed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                isExpired || isUsed ? Icons.timer_off : Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                isExpired
                    ? 'Invite Expired'
                    : isUsed
                        ? 'Invite Already Used'
                        : 'Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (isExpired) ...[
                const SizedBox(height: 8),
                Text(
                  'Contact your operator to get a new invite code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (isUsed) ...[
                const SizedBox(height: 8),
                Text(
                  'If you already started setting up your account, try logging in with your phone number.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Login with phone button (for already used invites)
        if (isUsed) ...[
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.phoneLogin),
            icon: const Icon(Icons.phone),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Log in with Phone Number'),
            ),
          ),
          const SizedBox(height: 12),
          // Try again with different code
          OutlinedButton(
            onPressed: _handleReset,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Try a Different Code'),
            ),
          ),
        ] else ...[
          // Try again button
          FilledButton(
            onPressed: _handleReset,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Try Again'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Text input formatter to convert to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
