import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

/// Premium duty toggle - On Duty indicator + Go Off Duty button
///
/// Matches mockup: Green dot with "On Duty" text | "Go Off Duty" outlined button
/// Features:
/// - Animated status dot with glow
/// - Haptic feedback
/// - Loading state support
class DutyToggle extends StatelessWidget {
  final bool isOnDuty;
  final bool isLoading;
  final VoidCallback onToggle;

  const DutyToggle({
    super.key,
    required this.isOnDuty,
    this.isLoading = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // On Duty indicator (left side)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpacing.md,
              vertical: DesignSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isOnDuty
                  ? DesignColors.success.withOpacity(isDark ? 0.15 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DesignRadii.badge),
              border: Border.all(
                color: isOnDuty
                    ? DesignColors.success.withOpacity(0.3)
                    : (isDark
                        ? DesignColors.borderSubtle
                        : DesignColors.lightBorderSubtle),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated dot
                _StatusDot(isActive: isOnDuty),
                const SizedBox(width: DesignSpacing.sm),
                Text(
                  isOnDuty ? 'On Duty' : 'Off Duty',
                  style: DesignTypography.labelMedium.copyWith(
                    color: isOnDuty
                        ? DesignColors.success
                        : (isDark
                            ? DesignColors.textMuted
                            : DesignColors.lightTextMuted),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: DesignSpacing.md),

          // Toggle button (outlined)
          _DutyButton(
            label: isOnDuty ? 'Go Off Duty' : 'Go On Duty',
            isLoading: isLoading,
            onTap: () {
              HapticFeedback.mediumImpact();
              onToggle();
            },
          ),
        ],
      ),
    );
  }
}

/// Animated status dot with glow effect
class _StatusDot extends StatelessWidget {
  final bool isActive;

  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? DesignColors.success : DesignColors.textMuted,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: DesignColors.success.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Outlined button for duty toggle
class _DutyButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _DutyButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSpacing.lg,
          vertical: DesignSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignRadii.badge),
          border: Border.all(
            color: isDark
                ? DesignColors.borderSubtle
                : DesignColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark
                        ? DesignColors.textSecondary
                        : DesignColors.lightTextSecondary,
                  ),
                ),
              )
            : Text(
                label,
                style: DesignTypography.labelMedium.copyWith(
                  color: isDark
                      ? DesignColors.textSecondary
                      : DesignColors.lightTextSecondary,
                ),
              ),
      ),
    );
  }
}

/// Compact duty indicator for app bars
class DutyIndicator extends StatelessWidget {
  final bool isOnDuty;

  const DutyIndicator({
    super.key,
    required this.isOnDuty,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusDot(isActive: isOnDuty),
        const SizedBox(width: 6),
        Text(
          isOnDuty ? 'On Duty' : 'Off Duty',
          style: DesignTypography.badge.copyWith(
            color: isOnDuty ? DesignColors.success : DesignColors.textMuted,
          ),
        ),
      ],
    );
  }
}
