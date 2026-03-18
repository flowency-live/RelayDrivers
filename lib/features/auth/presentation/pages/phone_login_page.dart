import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/foundations/glass.dart';
import '../../application/providers.dart';
import '../../domain/models/otp_models.dart';

/// Phone login page with OTP verification - Premium Design
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
      final biometricService = ref.read(biometricServiceProvider);
      final isSupported = await biometricService.isDeviceSupported();
      final canCheck = await biometricService.canCheckBiometrics();
      final isAlreadyEnabled = await biometricService.isBiometricEnabled();

      if (!isSupported || !canCheck || isAlreadyEnabled) {
        if (mounted) context.go(AppRoutes.home);
        return;
      }

      final types = await biometricService.getAvailableBiometrics();
      final typeName = biometricService.getBiometricTypeName(types);

      if (!mounted) return;

      final enableBiometric = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _BiometricDialog(typeName: typeName),
      );

      if (enableBiometric == true) {
        final token = await ref.read(dioClientProvider).getAccessToken();
        if (token != null) {
          await ref.read(biometricAuthStateProvider.notifier).enableBiometric(token);
        }
      }

      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneAuthState = ref.watch(phoneAuthStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<PhoneAuthState>(phoneAuthStateProvider, (previous, next) {
      if (next is PhoneAuthOtpSent && previous is! PhoneAuthOtpSent) {
        _startResendTimer();
        _otpFocusNode.requestFocus();
      }
      if (next is PhoneAuthSuccess) {
        if (next.driver != null) {
          ref.read(authStateProvider.notifier).setAuthenticated(next.driver!);
        }
        _offerBiometricSetup();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? DesignColors.background : DesignColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DesignSpacing.huge),

              // Logo with purple glow
              Center(
                child: Container(
                  padding: const EdgeInsets.all(DesignSpacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: DesignColors.accent.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Image.asset(
                    'assets/images/Relay_Logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: DesignSpacing.xl),

              // Title
              Text(
                'Relay Drivers',
                textAlign: TextAlign.center,
                style: DesignTypography.displaySmall.copyWith(
                  color: isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
                ),
              ),

              const SizedBox(height: DesignSpacing.sm),

              // Subtitle
              _buildSubtitle(phoneAuthState, isDark),

              const SizedBox(height: DesignSpacing.xxxl),

              // Main content in glass card
              if (isDark)
                GlassCard(
                  elevated: true,
                  padding: const EdgeInsets.all(DesignSpacing.xl),
                  child: _buildContent(phoneAuthState, isDark),
                )
              else
                Container(
                  padding: const EdgeInsets.all(DesignSpacing.xl),
                  decoration: BoxDecoration(
                    color: DesignColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildContent(phoneAuthState, isDark),
                ),

              const SizedBox(height: DesignSpacing.xl),

              // Alternative login
              if (phoneAuthState is PhoneAuthInitial ||
                  phoneAuthState is PhoneAuthError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Prefer email? ',
                      style: DesignTypography.meta.copyWith(
                        color: isDark
                            ? DesignColors.textSecondary
                            : DesignColors.lightTextSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Sign in with email',
                        style: DesignTypography.labelMedium.copyWith(
                          color: DesignColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: DesignSpacing.xxl),

              // Footer
              Text(
                'By signing in, you agree to the Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: DesignTypography.labelSmall.copyWith(
                  color: isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
                ),
              ),

              const SizedBox(height: DesignSpacing.md),

              // Version
              Text(
                'v$appVersion',
                textAlign: TextAlign.center,
                style: DesignTypography.labelSmall.copyWith(
                  color: isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(PhoneAuthState state, bool isDark) {
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
      style: DesignTypography.meta.copyWith(
        color: isDark ? DesignColors.textSecondary : DesignColors.lightTextSecondary,
      ),
    );
  }

  Widget _buildContent(PhoneAuthState state, bool isDark) {
    return switch (state) {
      PhoneAuthInitial() => _buildPhoneInput(isLoading: false, isDark: isDark),
      PhoneAuthChecking() => _buildPhoneInput(isLoading: true, isDark: isDark),
      PhoneAuthOtpSent() => _buildOtpInput(state, isDark),
      PhoneAuthVerifying() => _buildOtpVerifying(isDark),
      PhoneAuthSuccess() => _buildSuccess(state, isDark),
      PhoneAuthError() => _buildError(state, isDark),
    };
  }

  Widget _buildPhoneInput({required bool isLoading, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumTextField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          keyboardType: TextInputType.phone,
          enabled: !isLoading,
          label: 'Phone number',
          hint: '7XXX XXXXXX',
          prefix: '+44 ',
          icon: Icons.phone_outlined,
          isDark: isDark,
          onSubmitted: (_) => _handleSendOtp(),
        ),
        const SizedBox(height: DesignSpacing.xl),
        _PremiumButton(
          label: 'Send verification code',
          isLoading: isLoading,
          onPressed: _handleSendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpInput(PhoneAuthOtpSent state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone display
        Container(
          padding: const EdgeInsets.all(DesignSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? DesignColors.accent.withOpacity(0.1)
                : DesignColors.accent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignColors.accent.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.phone, color: DesignColors.accent, size: 20),
              const SizedBox(width: DesignSpacing.sm),
              Expanded(
                child: Text(
                  _formatPhone(state.phone),
                  style: DesignTypography.titleMedium.copyWith(
                    color: isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _handleChangePhone,
                child: Text(
                  'Change',
                  style: DesignTypography.labelMedium.copyWith(
                    color: DesignColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignSpacing.xl),

        // OTP input
        _OtpInputField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          isDark: isDark,
          onChanged: (value) {
            if (value.length == 6) _handleVerifyOtp();
          },
        ),

        const SizedBox(height: DesignSpacing.lg),

        // Resend
        Center(
          child: GestureDetector(
            onTap: _resendSeconds == 0 ? _handleResendOtp : null,
            child: Text(
              _resendSeconds > 0
                  ? 'Resend code in $_resendSeconds seconds'
                  : 'Resend code',
              style: DesignTypography.labelMedium.copyWith(
                color: _resendSeconds == 0
                    ? DesignColors.accent
                    : (isDark ? DesignColors.textMuted : DesignColors.lightTextMuted),
              ),
            ),
          ),
        ),

        const SizedBox(height: DesignSpacing.xl),

        _PremiumButton(
          label: 'Verify code',
          isLoading: false,
          onPressed: _otpController.text.length == 6 ? _handleVerifyOtp : null,
        ),
      ],
    );
  }

  Widget _buildOtpVerifying(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: DesignSpacing.xxl),
        CircularProgressIndicator(color: DesignColors.accent),
        const SizedBox(height: DesignSpacing.lg),
        Text(
          'Verifying...',
          style: DesignTypography.titleMedium.copyWith(
            color: isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: DesignSpacing.xxl),
      ],
    );
  }

  Widget _buildSuccess(PhoneAuthSuccess state, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: DesignSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(DesignSpacing.lg),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignColors.success.withOpacity(0.15),
            boxShadow: [
              BoxShadow(
                color: DesignColors.success.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 48,
            color: DesignColors.success,
          ),
        ),
        const SizedBox(height: DesignSpacing.lg),
        Text(
          state.isNewDriver ? 'Welcome!' : 'Welcome back!',
          style: DesignTypography.headlineMedium.copyWith(
            color: isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: DesignSpacing.xxl),
      ],
    );
  }

  Widget _buildError(PhoneAuthError state, bool isDark) {
    final showOtpInput = _otpController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error message
        Container(
          padding: const EdgeInsets.all(DesignSpacing.md),
          decoration: BoxDecoration(
            color: DesignColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DesignColors.danger.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: DesignColors.danger, size: 20),
              const SizedBox(width: DesignSpacing.sm),
              Expanded(
                child: Text(
                  state.message,
                  style: DesignTypography.bodySmall.copyWith(
                    color: DesignColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignSpacing.xl),

        if (showOtpInput) ...[
          _OtpInputField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            isDark: isDark,
            onChanged: (value) {
              if (value.length == 6) _handleVerifyOtp();
            },
          ),
          const SizedBox(height: DesignSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: _resendSeconds == 0 ? _handleResendOtp : null,
              child: Text(
                _resendSeconds > 0 ? 'Resend code in $_resendSeconds seconds' : 'Resend code',
                style: DesignTypography.labelMedium.copyWith(
                  color: _resendSeconds == 0 ? DesignColors.accent : DesignColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignSpacing.lg),
          _PremiumButton(label: 'Try again', onPressed: _handleVerifyOtp),
          const SizedBox(height: DesignSpacing.sm),
          _SecondaryButton(label: 'Use different number', onPressed: _handleChangePhone, isDark: isDark),
        ] else
          _buildPhoneInput(isLoading: false, isDark: isDark),
      ],
    );
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+44') && phone.length == 13) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 7)} ${phone.substring(7)}';
    }
    return phone;
  }
}

/// Premium styled text field
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool enabled;
  final String label;
  final String hint;
  final String? prefix;
  final IconData icon;
  final bool isDark;
  final void Function(String)? onSubmitted;

  const _PremiumTextField({
    required this.controller,
    this.focusNode,
    required this.keyboardType,
    this.enabled = true,
    required this.label,
    required this.hint,
    this.prefix,
    required this.icon,
    required this.isDark,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      enabled: enabled,
      style: DesignTypography.titleMedium.copyWith(
        color: isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\+\(\)]')),
        LengthLimitingTextInputFormatter(15),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon, color: DesignColors.accent),
        filled: true,
        fillColor: isDark ? DesignColors.surface.withOpacity(0.5) : DesignColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? DesignColors.glassBorder : DesignColors.lightBorderSubtle,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? DesignColors.glassBorder : DesignColors.lightBorderSubtle,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DesignColors.accent, width: 2),
        ),
        labelStyle: DesignTypography.labelMedium.copyWith(
          color: isDark ? DesignColors.textSecondary : DesignColors.lightTextSecondary,
        ),
        hintStyle: DesignTypography.meta.copyWith(
          color: isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
        ),
      ),
      onFieldSubmitted: onSubmitted,
    );
  }
}

/// Premium styled OTP input
class _OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isDark;
  final void Function(String)? onChanged;

  const _OtpInputField({
    required this.controller,
    this.focusNode,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      autofillHints: const [AutofillHints.oneTimeCode],
      style: TextStyle(
        fontSize: 28,
        letterSpacing: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? DesignColors.textPrimary : DesignColors.lightTextPrimary,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: '------',
        counterText: '',
        filled: true,
        fillColor: isDark ? DesignColors.surface.withOpacity(0.5) : DesignColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? DesignColors.glassBorder : DesignColors.lightBorderSubtle,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? DesignColors.glassBorder : DesignColors.lightBorderSubtle,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DesignColors.accent, width: 2),
        ),
        hintStyle: TextStyle(
          fontSize: 28,
          letterSpacing: 12,
          color: isDark ? DesignColors.textMuted : DesignColors.lightTextMuted,
        ),
      ),
      maxLength: 6,
      onChanged: onChanged,
    );
  }
}

/// Premium primary button with purple brand
class _PremiumButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PremiumButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: onPressed != null
            ? const LinearGradient(
                colors: [DesignColors.accent, Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? DesignColors.textMuted.withOpacity(0.3) : null,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: DesignColors.accent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: DesignTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDark;

  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? DesignColors.glassBorder : DesignColors.lightBorderSubtle,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: DesignTypography.button.copyWith(
                  color: isDark ? DesignColors.textSecondary : DesignColors.lightTextSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Biometric dialog with premium styling
class _BiometricDialog extends StatelessWidget {
  final String typeName;

  const _BiometricDialog({required this.typeName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Enable $typeName?',
        style: DesignTypography.headlineSmall.copyWith(
          color: DesignColors.textPrimary,
        ),
      ),
      content: Text(
        'Would you like to use $typeName to quickly unlock the app in the future?\n\n'
        'You can change this later in Settings.',
        style: DesignTypography.bodyMedium.copyWith(
          color: DesignColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Not now',
            style: TextStyle(color: DesignColors.textMuted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [DesignColors.accent, Color(0xFF7C3AED)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Enable $typeName',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
