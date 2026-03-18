import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';
import '../route/route_timeline.dart';

/// Current job card - Hero card showing active booking
///
/// Features:
/// - Glass morphism background
/// - Route timeline (pickup → dropoff)
/// - Customer info with avatar
/// - Action buttons (Call, Message)
class CurrentJobCard extends StatelessWidget {
  final String customerName;
  final String? customerCompany;
  final String? customerAvatarUrl;
  final String pickupAddress;
  final String pickupTime;
  final String dropoffAddress;
  final String dropoffTime;
  final VoidCallback? onCallTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onCardTap;

  const CurrentJobCard({
    super.key,
    required this.customerName,
    this.customerCompany,
    this.customerAvatarUrl,
    required this.pickupAddress,
    required this.pickupTime,
    required this.dropoffAddress,
    required this.dropoffTime,
    this.onCallTap,
    this.onMessageTap,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignRadii.card),
          child: BackdropFilter(
            filter: isDark
                ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? DesignColors.glassBackground
                    : DesignColors.lightSurface,
                borderRadius: BorderRadius.circular(DesignRadii.card),
                border: Border.all(
                  color: isDark
                      ? DesignColors.glassBorder
                      : DesignColors.lightBorderSubtle,
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSpacing.lg,
                      DesignSpacing.lg,
                      DesignSpacing.lg,
                      DesignSpacing.md,
                    ),
                    child: Text(
                      'Current Job',
                      style: DesignTypography.sectionHeader.copyWith(
                        color: isDark
                            ? DesignColors.textMuted
                            : DesignColors.lightTextMuted,
                      ),
                    ),
                  ),

                  // Route timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSpacing.lg,
                    ),
                    child: RouteTimeline(
                      pickupAddress: pickupAddress,
                      pickupTime: pickupTime,
                      dropoffAddress: dropoffAddress,
                      dropoffTime: dropoffTime,
                    ),
                  ),

                  const SizedBox(height: DesignSpacing.lg),

                  // Divider
                  Container(
                    height: 1,
                    color: isDark
                        ? DesignColors.borderSubtle
                        : DesignColors.lightBorderSubtle,
                  ),

                  // Customer info + actions
                  Padding(
                    padding: const EdgeInsets.all(DesignSpacing.lg),
                    child: Row(
                      children: [
                        // Customer avatar
                        _CustomerAvatar(
                          name: customerName,
                          avatarUrl: customerAvatarUrl,
                        ),

                        const SizedBox(width: DesignSpacing.md),

                        // Customer name + company
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: DesignTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? DesignColors.textPrimary
                                      : DesignColors.lightTextPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (customerCompany != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  customerCompany!,
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

                        // Action buttons
                        if (onCallTap != null)
                          _ActionButton(
                            icon: Icons.phone_outlined,
                            onTap: onCallTap!,
                            isDark: isDark,
                          ),

                        if (onMessageTap != null) ...[
                          const SizedBox(width: DesignSpacing.sm),
                          _ActionButton(
                            icon: Icons.chat_bubble_outline,
                            onTap: onMessageTap!,
                            isDark: isDark,
                          ),
                        ],
                      ],
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
}

/// Customer avatar with initials fallback
class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _CustomerAvatar({
    required this.name,
    this.avatarUrl,
  });

  String get _initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DesignSpacing.avatarMd,
      height: DesignSpacing.avatarMd,
      decoration: BoxDecoration(
        color: DesignColors.accent.withOpacity(0.15),
        shape: BoxShape.circle,
        image: avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl == null
          ? Center(
              child: Text(
                _initials,
                style: DesignTypography.labelMedium.copyWith(
                  color: DesignColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

/// Small action button for call/message
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? DesignColors.surface.withOpacity(0.5)
              : DesignColors.lightBackground,
          borderRadius: BorderRadius.circular(DesignRadii.sm),
          border: Border.all(
            color: isDark
                ? DesignColors.borderSubtle
                : DesignColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? DesignColors.textSecondary
              : DesignColors.lightTextSecondary,
        ),
      ),
    );
  }
}

/// Empty state for no current job
class NoCurrentJobCard extends StatelessWidget {
  final VoidCallback? onViewSchedule;

  const NoCurrentJobCard({
    super.key,
    this.onViewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignSpacing.lg),
      padding: const EdgeInsets.all(DesignSpacing.xl),
      decoration: BoxDecoration(
        color: isDark
            ? DesignColors.surface.withOpacity(0.5)
            : DesignColors.lightSurface,
        borderRadius: BorderRadius.circular(DesignRadii.card),
        border: Border.all(
          color: isDark
              ? DesignColors.borderSubtle
              : DesignColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: isDark
                ? DesignColors.textMuted
                : DesignColors.lightTextMuted,
          ),
          const SizedBox(height: DesignSpacing.md),
          Text(
            'No active job',
            style: DesignTypography.bodyMedium.copyWith(
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: DesignSpacing.xs),
          Text(
            'Your next booking will appear here',
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
          if (onViewSchedule != null) ...[
            const SizedBox(height: DesignSpacing.lg),
            GestureDetector(
              onTap: onViewSchedule,
              child: Text(
                'View schedule',
                style: DesignTypography.labelMedium.copyWith(
                  color: DesignColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
