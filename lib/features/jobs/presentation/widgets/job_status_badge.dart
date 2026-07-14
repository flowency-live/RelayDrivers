import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../domain/models/job.dart';

/// Colour for a driver job status. Semantic colours are shown as text on a
/// low-opacity tint of the same hue (per the design system's badge pattern),
/// which keeps a high contrast ratio in both themes.
Color jobStatusColor(DriverJobStatus status) {
  return switch (status) {
    DriverJobStatus.offered => DesignColors.info,
    DriverJobStatus.accepted => DesignColors.accent,
    DriverJobStatus.enRoute => DesignColors.info,
    DriverJobStatus.arrived => DesignColors.warning,
    DriverJobStatus.pickedUp => DesignColors.accent,
    DriverJobStatus.completed => DesignColors.success,
    DriverJobStatus.declined => DesignColors.textMuted,
    DriverJobStatus.cancelled => DesignColors.danger,
  };
}

/// Small pill showing a job's driver status.
class JobStatusBadge extends StatelessWidget {
  final DriverJobStatus status;

  const JobStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = jobStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSpacing.sm,
        vertical: DesignSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignRadii.badge),
      ),
      child: Text(
        status.displayName,
        style: DesignTypography.badge.copyWith(color: color),
      ),
    );
  }
}
