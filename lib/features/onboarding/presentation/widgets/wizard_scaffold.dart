import 'package:flutter/material.dart';
import '../../application/onboarding_wizard_provider.dart';

/// Scaffold wrapper for wizard steps
/// Provides consistent header, progress, and navigation
class WizardScaffold extends StatelessWidget {
  final WizardStep step;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool canGoNext;
  final bool isLoading;
  final bool showBackButton;

  const WizardScaffold({
    super.key,
    required this.step,
    required this.child,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.canGoNext = true,
    this.isLoading = false,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with phase info and progress
            _WizardHeader(step: step),

            // Main content - fills available space
            Expanded(
              child: child,
            ),

            // Bottom navigation
            _WizardNavigation(
              onBack: showBackButton ? onBack : null,
              onNext: onNext,
              nextLabel: nextLabel ?? 'Continue',
              canGoNext: canGoNext,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final WizardStep step;

  const _WizardHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallProgress = (WizardStep.values.indexOf(step)) / 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase badge and step info
          Row(
            children: [
              // Phase badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Phase ${step.phase}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                step.phaseTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Step counter
              Text(
                'Step ${step.stepInPhase} of ${step.totalStepsInPhase}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Step title
          Text(
            step.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primary.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardNavigation extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool canGoNext;
  final bool isLoading;

  const _WizardNavigation({
    this.onBack,
    this.onNext,
    required this.nextLabel,
    required this.canGoNext,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                child: const Text('Back'),
              ),
            )
          else
            const Spacer(),

          if (onBack != null) const SizedBox(width: 12),

          // Next button
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: (canGoNext && !isLoading) ? onNext : null,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable form field with consistent styling
class WizardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;

  const WizardTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffix: suffix,
        border: const OutlineInputBorder(),
        counterText: '', // Hide counter
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
    );
  }
}

/// Info banner for tips/help
class WizardInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const WizardInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
