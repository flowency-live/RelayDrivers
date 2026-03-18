import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';
import '../../foundations/glass.dart';

/// Premium hero greeting header - "Good Evening, Daniel"
///
/// Design specs:
/// - Time-based greeting (morning/afternoon/evening)
/// - Light weight for greeting, semibold for name
/// - Optional operator subtitle
/// - Gradient fog fade into content below
/// - Optional operational status badge
class GreetingHeader extends StatelessWidget {
  final String firstName;
  final String? operatorName;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;
  final bool isOnDuty;
  final bool showDutyStatus;

  const GreetingHeader({
    super.key,
    required this.firstName,
    this.operatorName,
    this.unreadCount = 0,
    this.onNotificationsTap,
    this.isOnDuty = false,
    this.showDutyStatus = false,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignSpacing.lg,
        DesignSpacing.lg,
        DesignSpacing.lg,
        DesignSpacing.xl,
      ),
      decoration: isDark
          ? BoxDecoration(
              // Subtle gradient fog fading into content
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DesignColors.background.withOpacity(0.1),
                  DesignColors.background.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Good Evening, Daniel" - larger for hero impact
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$_greeting, ',
                            style: DesignTypography.greetingLight.copyWith(
                              color: isDark
                                  ? DesignColors.textPrimary
                                  : Colors.white,
                              shadows: isDark
                                  ? null
                                  : [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                          ),
                          TextSpan(
                            text: firstName,
                            style: DesignTypography.greetingName.copyWith(
                              color: isDark
                                  ? DesignColors.textPrimary
                                  : Colors.white,
                              shadows: isDark
                                  ? null
                                  : [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Operator subtitle (if provided)
                    if (operatorName != null) ...[
                      const SizedBox(height: DesignSpacing.sm),
                      Text(
                        'Driving with $operatorName',
                        style: DesignTypography.meta.copyWith(
                          color: isDark
                              ? DesignColors.textSecondary
                              : Colors.white.withOpacity(0.9),
                          shadows: isDark
                              ? null
                              : [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Notification indicator (optional)
              if (onNotificationsTap != null)
                GestureDetector(
                  onTap: onNotificationsTap,
                  child: Container(
                    padding: const EdgeInsets.all(DesignSpacing.sm),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 24,
                          color: isDark
                              ? DesignColors.textSecondary
                              : Colors.white,
                          shadows: isDark
                              ? null
                              : [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: DesignColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignColors.accent.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Operational status badge (for active drivers)
          if (showDutyStatus) ...[
            const SizedBox(height: DesignSpacing.lg),
            _OperationalStatusBadge(isOnDuty: isOnDuty),
          ],
        ],
      ),
    );
  }
}

/// Operational status badge - shows duty status with glow
class _OperationalStatusBadge extends StatelessWidget {
  final bool isOnDuty;

  const _OperationalStatusBadge({required this.isOnDuty});

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnDuty ? DesignColors.success : DesignColors.textMuted;
    final statusText = isOnDuty ? 'On Duty' : 'Off Duty';

    return Row(
      children: [
        StatusDot(
          color: statusColor,
          size: 10,
          animated: isOnDuty,
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: DesignTypography.labelMedium.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Compact greeting for use in app bars
class CompactGreeting extends StatelessWidget {
  final String firstName;

  const CompactGreeting({
    super.key,
    required this.firstName,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Text(
      '$_greeting, $firstName',
      style: DesignTypography.headlineSmall.copyWith(
        color: isDark
            ? DesignColors.textPrimary
            : DesignColors.lightTextPrimary,
      ),
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpacing.lg,
        vertical: DesignSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: DesignTypography.sectionHeader.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
          if (actionText != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: DesignTypography.labelMedium.copyWith(
                  color: DesignColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
