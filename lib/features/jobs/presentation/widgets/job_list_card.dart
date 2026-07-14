import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/models/job.dart';
import 'job_status_badge.dart';

/// A compact card summarising a job in the list view.
class JobListCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobListCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(DesignSpacing.md),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.bookingId ?? job.jobId,
                    style: DesignTypography.titleSmall.copyWith(
                      color: isDark
                          ? DesignColors.textPrimary
                          : DesignColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                JobStatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: DesignSpacing.sm),
            _AddressLine(
              icon: Icons.trip_origin,
              iconColor: DesignColors.accent,
              text: job.pickupAddress,
              isDark: isDark,
            ),
            const SizedBox(height: DesignSpacing.xs),
            _AddressLine(
              icon: Icons.place_outlined,
              iconColor: DesignColors.accentSecondary,
              text: job.dropoffAddress,
              isDark: isDark,
            ),
            const SizedBox(height: DesignSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatScheduledTime(job.scheduledDateTime),
                  style: DesignTypography.bodySmall.copyWith(
                    color: isDark
                        ? DesignColors.textSecondary
                        : DesignColors.lightTextSecondary,
                  ),
                ),
                Text(
                  Currency.formatPenceCompact(job.fare),
                  style: DesignTypography.bodyMedium.copyWith(
                    color: isDark
                        ? DesignColors.textPrimary
                        : DesignColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool isDark;

  const _AddressLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: DesignSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: DesignTypography.bodySmall.copyWith(
              color: isDark
                  ? DesignColors.textPrimary
                  : DesignColors.lightTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Format a scheduled time for display, e.g. "Tue 14 Jul, 09:00".
/// Returns "Time TBC" when null.
String formatScheduledTime(DateTime? dt) {
  if (dt == null) return 'Time TBC';
  final local = dt.toLocal();
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${days[local.weekday - 1]} ${local.day} ${months[local.month - 1]}, $hh:$mm';
}
