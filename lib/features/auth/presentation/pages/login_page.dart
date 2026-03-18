import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/foundations/backgrounds.dart';
import '../../application/providers.dart';
import '../../domain/models/auth_state.dart';

/// Premium login page with email/password and magic link authentication.
///
/// Design specs:
/// - City blur background (always premium)
/// - Glass morphism card for inputs
/// - Purple brand gradient button
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _magicLinkMode = true;
  bool _magicLinkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    if (_magicLinkMode) {
      ref.read(authStateProvider.notifier).requestMagicLink(
            _emailController.text.trim(),
          ).then((success) {
            if (success) {
              setState(() => _magicLinkSent = true);
            }
          });
    } else {
      ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;

    // Auth screens ALWAYS use premium dark styling
    return PremiumAuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignSpacing.xl),
            child: Form(
              key: _formKey,
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

                  const SizedBox(height: DesignSpacing.xl),

                  // Title
                  Text(
                    'Relay Drivers',
                    textAlign: TextAlign.center,
                    style: DesignTypography.displaySmall.copyWith(
                      color: DesignColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: DesignSpacing.sm),

                  // Subtitle
                  Text(
                    _magicLinkSent
                        ? 'Check your email for a login link'
                        : 'Sign in to manage your profile and jobs',
                    textAlign: TextAlign.center,
                    style: DesignTypography.meta.copyWith(
                      color: DesignColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: DesignSpacing.xxxl),

                  // Main content in glass card
                  _buildGlassCard(
                    child: _magicLinkSent
                        ? _buildMagicLinkSent()
                        : _buildLoginForm(authState, isLoading),
                  ),

                  const SizedBox(height: DesignSpacing.xl),

                  // Phone login link
                  if (!_magicLinkSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Prefer phone? ',
                          style: DesignTypography.meta.copyWith(
                            color: DesignColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.phoneLogin),
                          child: Text(
                            'Sign in with phone',
                            style: DesignTypography.labelMedium.copyWith(
                              color: DesignColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: DesignSpacing.md),

                  // Register link
                  if (!_magicLinkSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: DesignTypography.meta.copyWith(
                            color: DesignColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: Text(
                            'Sign up',
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
                      color: DesignColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: DesignSpacing.md),

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

  Widget _buildMagicLinkSent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignSpacing.lg),
          decoration: BoxDecoration(
            color: DesignColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DesignColors.accent.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignColors.accent.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: 40,
                  color: DesignColors.accent,
                ),
              ),
              const SizedBox(height: DesignSpacing.lg),
              Text(
                'Magic link sent!',
                style: DesignTypography.headlineSmall.copyWith(
                  color: DesignColors.textPrimary,
                ),
              ),
              const SizedBox(height: DesignSpacing.sm),
              Text(
                'We sent a login link to:\n${_emailController.text}',
                textAlign: TextAlign.center,
                style: DesignTypography.bodyMedium.copyWith(
                  color: DesignColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignSpacing.xl),
        _SecondaryButton(
          label: 'Use different email',
          onPressed: () {
            setState(() {
              _magicLinkSent = false;
              _emailController.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState authState, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field
        _PremiumTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction:
              _magicLinkMode ? TextInputAction.done : TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onSubmitted: _magicLinkMode ? (_) => _handleLogin() : null,
        ),

        if (!_magicLinkMode) ...[
          const SizedBox(height: DesignSpacing.lg),
          // Password field
          _PremiumTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outlined,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: DesignColors.textMuted,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            onSubmitted: (_) => _handleLogin(),
          ),
        ],

        // Error message
        if (authState is AuthError) ...[
          const SizedBox(height: DesignSpacing.lg),
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
                    authState.message,
                    style: DesignTypography.bodySmall.copyWith(
                      color: DesignColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: DesignSpacing.xl),

        // Submit button
        _PremiumButton(
          label: _magicLinkMode ? 'Send magic link' : 'Sign in',
          isLoading: isLoading,
          onPressed: _handleLogin,
        ),

        const SizedBox(height: DesignSpacing.lg),

        // Toggle login mode
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _magicLinkMode = !_magicLinkMode;
                _passwordController.clear();
              });
            },
            child: Text(
              _magicLinkMode
                  ? 'Sign in with password instead'
                  : 'Sign in with magic link instead',
              style: DesignTypography.labelMedium.copyWith(
                color: DesignColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium text field
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: DesignTypography.titleMedium.copyWith(
        color: DesignColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: DesignColors.accent),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DesignColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DesignColors.danger, width: 2),
        ),
        labelStyle: DesignTypography.labelMedium.copyWith(
          color: DesignColors.textSecondary,
        ),
        hintStyle: DesignTypography.meta.copyWith(
          color: DesignColors.textMuted,
        ),
        errorStyle: DesignTypography.labelSmall.copyWith(
          color: DesignColors.danger,
        ),
      ),
      validator: validator,
      onFieldSubmitted: onSubmitted,
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
