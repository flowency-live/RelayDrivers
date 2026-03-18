import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/foundations/backgrounds.dart';
import '../../application/providers.dart';
import '../../domain/models/invite_models.dart';

/// Premium invite code entry page - first screen for new drivers.
///
/// Design specs:
/// - City blur background (always premium, never plain white)
/// - Glass morphism card for inputs
/// - Purple brand gradient button
/// - Premium typography and spacing
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

    ref.listen<InviteAuthState>(inviteAuthStateProvider, (previous, next) {
      if (next is InviteAuthSuccess) {
        ref.read(authStateProvider.notifier).setAuthenticated(next.driver);
        ref.read(inviteAuthStateProvider.notifier).reset();
        context.go(AppRoutes.home);
      } else if (next is InviteAuthOtpSent) {
        _otpFocusNode.requestFocus();
      }
    });

    return PremiumAuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Join Relay',
            style: DesignTypography.titleLarge.copyWith(
              color: DesignColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: DesignSpacing.xl),

                // Logo with purple glow
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(DesignSpacing.lg),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DesignColors.accent.withOpacity(0.35),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/Relay_Logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: DesignSpacing.xxl),

                // Main content in glass card
                _buildGlassCard(
                  child: _buildContent(state),
                ),

                const SizedBox(height: DesignSpacing.xxl),

                // Version
                Text(
                  'v$appVersion',
                  textAlign: TextAlign.center,
                  style: DesignTypography.labelSmall.copyWith(
                    color: DesignColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(DesignSpacing.xl),
          decoration: BoxDecoration(
            color: DesignColors.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DesignColors.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildContent(InviteAuthState state) {
    return switch (state) {
      InviteAuthInitial() => _buildCodeEntry(),
      InviteAuthVerifying() => _buildLoading('Verifying invite code...'),
      InviteAuthVerified(:final firstName, :final lastName, :final maskedPhone, :final companyName) =>
        _buildVerified(firstName, lastName, maskedPhone, companyName),
      InviteAuthOtpSent(:final firstName, :final companyName) =>
        _buildOtpEntry(firstName, companyName),
      InviteAuthClaiming() => _buildLoading('Verifying...'),
      InviteAuthSuccess() => _buildLoading('Welcome! Setting up...'),
      InviteAuthError(:final message, :final isExpired, :final isUsed) =>
        _buildError(message, isExpired, isUsed),
    };
  }

  Widget _buildCodeEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Your Invite Code',
          style: DesignTypography.headlineMedium.copyWith(
            color: DesignColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignSpacing.sm),
        Text(
          'Your operator sent you an invite code via SMS. Enter it below to get started.',
          style: DesignTypography.bodyMedium.copyWith(
            color: DesignColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignSpacing.xxl),

        // Premium text field
        _PremiumTextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          label: 'Invite Code',
          hint: 'DRV-XXXXXXXX',
          icon: Icons.confirmation_number_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
            _UpperCaseFormatter(),
          ],
          onSubmitted: (_) => _handleVerifyCode(),
        ),

        const SizedBox(height: DesignSpacing.xl),

        // Premium button
        _PremiumButton(
          label: 'Continue',
          onPressed: _handleVerifyCode,
        ),

        const SizedBox(height: DesignSpacing.lg),

        // Already have account link
        Center(
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.phoneLogin),
            child: Text(
              'Already have an account? Sign in',
              style: DesignTypography.labelMedium.copyWith(
                color: DesignColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerified(
    String firstName,
    String lastName,
    String maskedPhone,
    String? companyName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Simple welcome text - no tacky colored panels
        Text(
          'Welcome, $firstName!',
          style: DesignTypography.headlineMedium.copyWith(
            color: DesignColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        if (companyName != null) ...[
          const SizedBox(height: DesignSpacing.sm),
          Text(
            'Invited to drive with $companyName',
            style: DesignTypography.bodyMedium.copyWith(
              color: DesignColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: DesignSpacing.xs),
        Text(
          'Phone on file: $maskedPhone',
          style: DesignTypography.labelSmall.copyWith(
            color: DesignColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: DesignSpacing.xl),

        // Phone input - positioned for mobile keyboard
        _PremiumTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '07XXX XXXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          onSubmitted: (_) => _handleRequestOtp(),
        ),

        const SizedBox(height: DesignSpacing.lg),

        _PremiumButton(
          label: 'Send Verification Code',
          onPressed: _handleRequestOtp,
        ),

        const SizedBox(height: DesignSpacing.md),

        Center(
          child: GestureDetector(
            onTap: _handleReset,
            child: Text(
              'Use different invite code',
              style: DesignTypography.labelMedium.copyWith(
                color: DesignColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpEntry(String firstName, String? companyName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Verification Code',
          style: DesignTypography.headlineMedium.copyWith(
            color: DesignColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignSpacing.sm),
        Text(
          'We sent a 6-digit code to your phone.',
          style: DesignTypography.bodyMedium.copyWith(
            color: DesignColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (companyName != null) ...[
          const SizedBox(height: DesignSpacing.xs),
          Text(
            'Joining $companyName',
            style: DesignTypography.labelMedium.copyWith(
              color: DesignColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: DesignSpacing.xxl),

        // OTP input
        _OtpInputField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          onChanged: (value) {
            if (value.length == 6) _handleClaimInvite();
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
                    : DesignColors.textMuted,
              ),
            ),
          ),
        ),

        const SizedBox(height: DesignSpacing.xl),

        _PremiumButton(
          label: 'Verify',
          onPressed: _otpController.text.length == 6 ? _handleClaimInvite : null,
        ),

        const SizedBox(height: DesignSpacing.md),

        Center(
          child: GestureDetector(
            onTap: _handleReset,
            child: Text(
              'Use different phone number',
              style: DesignTypography.labelMedium.copyWith(
                color: DesignColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: DesignSpacing.xxl),
        CircularProgressIndicator(color: DesignColors.accent),
        const SizedBox(height: DesignSpacing.lg),
        Text(
          message,
          style: DesignTypography.bodyMedium.copyWith(
            color: DesignColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignSpacing.xxl),
      ],
    );
  }

  Widget _buildError(String message, bool isExpired, bool isUsed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error container
        Container(
          padding: const EdgeInsets.all(DesignSpacing.lg),
          decoration: BoxDecoration(
            color: DesignColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignColors.danger.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isExpired || isUsed ? Icons.timer_off : Icons.error_outline,
                size: 48,
                color: DesignColors.danger,
              ),
              const SizedBox(height: DesignSpacing.md),
              Text(
                isExpired
                    ? 'Invite Expired'
                    : isUsed
                        ? 'Invite Already Used'
                        : 'Error',
                style: DesignTypography.headlineSmall.copyWith(
                  color: DesignColors.danger,
                ),
              ),
              const SizedBox(height: DesignSpacing.sm),
              Text(
                message,
                style: DesignTypography.bodyMedium.copyWith(
                  color: DesignColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (isExpired) ...[
                const SizedBox(height: DesignSpacing.sm),
                Text(
                  'Contact your operator to get a new invite code.',
                  style: DesignTypography.bodySmall.copyWith(
                    color: DesignColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (isUsed) ...[
                const SizedBox(height: DesignSpacing.sm),
                Text(
                  'If you already started setting up your account, try logging in with your phone number.',
                  style: DesignTypography.bodySmall.copyWith(
                    color: DesignColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: DesignSpacing.xl),

        if (isUsed) ...[
          _PremiumButton(
            label: 'Log in with Phone Number',
            onPressed: () => context.go(AppRoutes.phoneLogin),
          ),
          const SizedBox(height: DesignSpacing.md),
          _SecondaryButton(
            label: 'Try a Different Code',
            onPressed: _handleReset,
          ),
        ] else ...[
          _PremiumButton(
            label: 'Try Again',
            onPressed: _handleReset,
          ),
        ],
      ],
    );
  }
}

/// Premium text field with glass styling
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onSubmitted;

  const _PremiumTextField({
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: DesignTypography.titleMedium.copyWith(
        color: DesignColors.textPrimary,
      ),
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: DesignColors.accent),
        filled: true,
        fillColor: DesignColors.surface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DesignColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DesignColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DesignColors.accent, width: 2),
        ),
        labelStyle: DesignTypography.labelMedium.copyWith(
          color: DesignColors.textSecondary,
        ),
        hintStyle: DesignTypography.meta.copyWith(
          color: DesignColors.textMuted,
        ),
      ),
      onFieldSubmitted: onSubmitted,
    );
  }
}

/// OTP input with large letters
class _OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;

  const _OtpInputField({
    required this.controller,
    this.focusNode,
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
      style: const TextStyle(
        fontSize: 32,
        letterSpacing: 16,
        fontWeight: FontWeight.w600,
        color: DesignColors.textPrimary,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: '------',
        counterText: '',
        filled: true,
        fillColor: DesignColors.surface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DesignColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DesignColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DesignColors.accent, width: 2),
        ),
        hintStyle: TextStyle(
          fontSize: 32,
          letterSpacing: 16,
          color: DesignColors.textMuted,
        ),
      ),
      maxLength: 6,
      onChanged: onChanged,
    );
  }
}

/// Premium gradient button
class _PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PremiumButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: enabled
            ? const LinearGradient(
                colors: [DesignColors.accent, Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : DesignColors.textMuted.withOpacity(0.3),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: DesignColors.accent.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
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

  const _SecondaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: DesignTypography.button.copyWith(
                  color: DesignColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uppercase text formatter
class _UpperCaseFormatter extends TextInputFormatter {
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
