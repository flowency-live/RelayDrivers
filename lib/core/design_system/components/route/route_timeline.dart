import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';

/// Route timeline - vertical route line with pickup/dropoff points
///
/// Matches mockup: Cyan filled circle for pickup, outlined circle for dropoff
/// Features:
/// - Animated glow on active point
/// - Connecting line between points
/// - Time/distance labels
class RouteTimeline extends StatelessWidget {
  final String pickupAddress;
  final String pickupTime;
  final String dropoffAddress;
  final String dropoffTime;
  final bool isPickupActive;

  const RouteTimeline({
    super.key,
    required this.pickupAddress,
    required this.pickupTime,
    required this.dropoffAddress,
    required this.dropoffTime,
    this.isPickupActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Column(
      children: [
        // Pickup point
        _RoutePoint(
          isFilled: true,
          isActive: isPickupActive,
          title: pickupTime,
          subtitle: pickupAddress,
          isDark: isDark,
        ),

        // Connecting line
        Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DesignColors.accent,
                      DesignColors.accent.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Dropoff point
        _RoutePoint(
          isFilled: false,
          isActive: !isPickupActive,
          title: dropoffAddress,
          subtitle: dropoffTime,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Individual route point (pickup or dropoff)
class _RoutePoint extends StatelessWidget {
  final bool isFilled;
  final bool isActive;
  final String title;
  final String subtitle;
  final bool isDark;

  const _RoutePoint({
    required this.isFilled,
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circle indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: DesignSpacing.routeDotSize,
          height: DesignSpacing.routeDotSize,
          decoration: BoxDecoration(
            color: isFilled ? DesignColors.accent : Colors.transparent,
            shape: BoxShape.circle,
            border: isFilled
                ? null
                : Border.all(color: DesignColors.accent, width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: DesignColors.accent.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        ),

        const SizedBox(width: DesignSpacing.md),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DesignTypography.bodyMedium.copyWith(
                  color: isDark
                      ? DesignColors.textPrimary
                      : DesignColors.lightTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: DesignTypography.bodySmall.copyWith(
                  color: isDark
                      ? DesignColors.textSecondary
                      : DesignColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal compact route line (for cards)
class CompactRouteLine extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String? duration;

  const CompactRouteLine({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Row(
      children: [
        // Pickup indicator
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: DesignColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            pickup,
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: isDark
                ? DesignColors.textMuted
                : DesignColors.lightTextMuted,
          ),
        ),

        // Dropoff indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DesignColors.accent, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            dropoff,
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Duration (if provided)
        if (duration != null) ...[
          const SizedBox(width: 8),
          Text(
            duration!,
            style: DesignTypography.badge.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
        ],
      ],
    );
  }
}
