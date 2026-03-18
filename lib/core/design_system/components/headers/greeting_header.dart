import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';

/// Premium greeting header - "Good Evening, Daniel"
///
/// Features:
/// - Time-based greeting (morning/afternoon/evening)
/// - Light weight for greeting, semibold for name
/// - Optional operator subtitle
/// - Optional notification dots
class GreetingHeader extends StatelessWidget {
  final String firstName;
  final String? operatorName;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;

  const GreetingHeader({
    super.key,
    required this.firstName,
    this.operatorName,
    this.unreadCount = 0,
    this.onNotificationsTap,
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpacing.lg,
        vertical: DesignSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Good Evening, Daniel"
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_greeting, ',
                        style: DesignTypography.greetingLight.copyWith(
                          color: isDark
                              ? DesignColors.textPrimary
                              : DesignColors.lightTextPrimary,
                        ),
                      ),
                      TextSpan(
                        text: firstName,
                        style: DesignTypography.greetingName.copyWith(
                          color: isDark
                              ? DesignColors.textPrimary
                              : DesignColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Operator subtitle (if provided)
                if (operatorName != null) ...[
                  const SizedBox(height: DesignSpacing.xs),
                  Text(
                    'Driving with $operatorName',
                    style: DesignTypography.bodySmall.copyWith(
                      color: isDark
                          ? DesignColors.textSecondary
                          : DesignColors.lightTextSecondary,
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
                          : DesignColors.lightTextSecondary,
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
