import 'package:flutter/material.dart';
import '../../domain/models/vehicle.dart';

/// Card widget displaying vehicle information with compliance status
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onDelete;
  final bool isDeleting;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onDelete,
    this.isDeleting = false,
  });

  Color _getComplianceColor(BuildContext context) {
    switch (vehicle.complianceStatus.toLowerCase()) {
      case 'compliant':
        return const Color(0xFF2ECC71);
      case 'expiring':
        return const Color(0xFFF39C12);
      case 'non_compliant':
      case 'expired':
        return const Color(0xFFE63946);
      default:
        return const Color(0xFFB0B0B0);
    }
  }

  IconData _getComplianceIcon() {
    switch (vehicle.complianceStatus.toLowerCase()) {
      case 'compliant':
        return Icons.check_circle;
      case 'expiring':
        return Icons.warning;
      case 'non_compliant':
      case 'expired':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getComplianceText() {
    switch (vehicle.complianceStatus.toLowerCase()) {
      case 'compliant':
        return 'Ready to operate';
      case 'expiring':
        return 'Documents expiring soon';
      case 'non_compliant':
      case 'expired':
        return 'Cannot operate - check alerts';
      default:
        return 'Status unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final complianceColor = _getComplianceColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with VRN and compliance indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: complianceColor.withAlpha(25),
              border: Border(
                left: BorderSide(
                  color: complianceColor,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // VRN badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          vehicle.vrn,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (vehicle.colour != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          vehicle.colour!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withAlpha(179),
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
                    Text(
                      vehicle.canOperate ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        color: complianceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                ),

                // Compliance alerts
                if (vehicle.complianceAlerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withAlpha(76),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Compliance Alerts',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
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
                                  '• ',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    alert,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(isDeleting ? 'Removing...' : 'Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtext;
  final bool isWarning;
  final bool isError;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtext,
    this.isWarning = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    if (isError) {
      statusColor = const Color(0xFFE63946);
    } else if (isWarning) {
      statusColor = const Color(0xFFF39C12);
    } else {
      statusColor = const Color(0xFF2ECC71);
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtext!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isError || isWarning ? statusColor : null,
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
