import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../domain/models/vehicle.dart';

/// Card widget displaying vehicle information with compliance status
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAddPhoto;
  final bool isDeleting;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onDelete,
    this.onTap,
    this.onAddPhoto,
    this.isDeleting = false,
  });

  (Color, Color) _getComplianceColors() {
    return switch (vehicle.complianceStatus.toLowerCase()) {
      'compliant' => (RelayColors.success, RelayColors.successBackground),
      'expiring' => (RelayColors.warning, RelayColors.warningBackground),
      'non_compliant' || 'expired' => (RelayColors.danger, RelayColors.dangerBackground),
      _ => (RelayColors.darkTextMuted, RelayColors.darkBorderSubtle),
    };
  }

  IconData _getComplianceIcon() {
    return switch (vehicle.complianceStatus.toLowerCase()) {
      'compliant' => Icons.check_circle,
      'expiring' => Icons.warning,
      'non_compliant' || 'expired' => Icons.error,
      _ => Icons.help_outline,
    };
  }

  String _getComplianceText() {
    return switch (vehicle.complianceStatus.toLowerCase()) {
      'compliant' => 'Ready to operate',
      'expiring' => 'Documents expiring soon',
      'non_compliant' || 'expired' => 'Cannot operate - check alerts',
      _ => 'Status unknown',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (complianceColor, complianceBg) = _getComplianceColors();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? RelayColors.darkSurface1 : RelayColors.lightSurface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: isDark ? RelayColors.darkBorderSubtle : RelayColors.lightBorderSubtle,
              width: 1,
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with VRN and compliance indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: complianceBg,
              border: Border(
                left: BorderSide(
                  color: complianceColor,
                  width: AppTheme.accentBarWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UK Number plate badge
                      _UkNumberPlate(vrn: vehicle.vrn),
                      const SizedBox(height: 12),
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDark
                                  ? RelayColors.darkTextPrimary
                                  : RelayColors.lightTextPrimary,
                            ),
                      ),
                      if (vehicle.colour != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          vehicle.colour!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? RelayColors.darkTextSecondary
                                    : RelayColors.lightTextSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Compliance badge
                Column(
                  children: [
                    Icon(
                      _getComplianceIcon(),
                      color: complianceColor,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: complianceColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        border: Border.all(
                          color: complianceColor.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        vehicle.canOperate ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: complianceColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MOT status
                _StatusRow(
                  icon: Icons.assignment_outlined,
                  label: 'MOT',
                  value: vehicle.motStatus ?? 'Unknown',
                  subtext: vehicle.motExpiryDate != null
                      ? 'Expires: ${_formatDate(vehicle.motExpiryDate!)}'
                      : null,
                  isWarning: vehicle.isMotExpiringSoon,
                  isError: vehicle.isMotExpired,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Tax status
                _StatusRow(
                  icon: Icons.receipt_outlined,
                  label: 'Tax',
                  value: vehicle.taxStatus ?? 'Unknown',
                  subtext: vehicle.taxDueDate != null
                      ? 'Due: ${_formatDate(vehicle.taxDueDate!)}'
                      : null,
                  isWarning: vehicle.isTaxExpiringSoon,
                  isError: vehicle.isTaxExpired,
                  isDark: isDark,
                ),

                // Compliance alerts
                if (vehicle.complianceAlerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RelayColors.dangerBackground,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(
                        color: RelayColors.danger.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: RelayColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Compliance Alerts',
                              style: TextStyle(
                                color: RelayColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...vehicle.complianceAlerts.map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\u2022 ',
                                  style: TextStyle(color: RelayColors.danger),
                                ),
                                Expanded(
                                  child: Text(
                                    alert,
                                    style: TextStyle(
                                      color: RelayColors.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Compliance status message
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _getComplianceIcon(),
                      color: complianceColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getComplianceText(),
                      style: TextStyle(
                        color: complianceColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? RelayColors.darkBorderSubtle : RelayColors.lightBorderSubtle,
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Photo count indicator
                if (vehicle.photos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RelayColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 14,
                          color: RelayColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.photos.length}',
                          style: TextStyle(
                            color: RelayColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Add Photo button
                if (onAddPhoto != null)
                  TextButton.icon(
                    onPressed: onAddPhoto,
                    icon: Icon(Icons.add_a_photo, size: 18, color: RelayColors.primary),
                    label: Text(
                      'Add Photos',
                      style: TextStyle(color: RelayColors.primary),
                    ),
                  ),
                // Delete button
                TextButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: RelayColors.danger,
                          ),
                        )
                      : Icon(Icons.delete_outline, color: RelayColors.danger),
                  label: Text(
                    isDeleting ? 'Removing...' : 'Remove',
                    style: TextStyle(color: RelayColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}

/// UK-style number plate display
class _UkNumberPlate extends StatelessWidget {
  final String vrn;

  const _UkNumberPlate({required this.vrn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F), // UK plate yellow
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF222222),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        vrn.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'UKNumberPlate',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF222222),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtext;
  final bool isWarning;
  final bool isError;
  final bool isDark;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtext,
    this.isWarning = false,
    this.isError = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;

    if (isError) {
      statusColor = RelayColors.danger;
      statusBg = RelayColors.dangerBackground;
    } else if (isWarning) {
      statusColor = RelayColors.warning;
      statusBg = RelayColors.warningBackground;
    } else {
      statusColor = RelayColors.success;
      statusBg = RelayColors.successBackground;
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: RelayColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? RelayColors.darkTextSecondary
                              : RelayColors.lightTextSecondary,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(
                        color: statusColor.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      value.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtext != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtext!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isError || isWarning
                            ? statusColor
                            : (isDark
                                ? RelayColors.darkTextMuted
                                : RelayColors.lightTextMuted),
                        fontSize: 12,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
