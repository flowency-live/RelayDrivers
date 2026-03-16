import 'package:flutter/material.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../domain/models/document.dart';

/// Card widget displaying document information with status
class DocumentCard extends StatelessWidget {
  final DriverDocument document;

  const DocumentCard({
    super.key,
    required this.document,
  });

  Color _getStatusColor() {
    if (document.isExpired) return RelayColors.danger;
    if (document.isExpiringSoon) return RelayColors.warning;

    switch (document.status) {
      case DocumentStatus.verified:
        return RelayColors.success;
      case DocumentStatus.pendingReview:
        return RelayColors.info;
      case DocumentStatus.rejected:
        return RelayColors.danger;
      case DocumentStatus.expired:
        return RelayColors.danger;
    }
  }

  IconData _getStatusIcon() {
    if (document.isExpired) return Icons.error;
    if (document.isExpiringSoon) return Icons.schedule;

    switch (document.status) {
      case DocumentStatus.verified:
        return Icons.check_circle;
      case DocumentStatus.pendingReview:
        return Icons.hourglass_empty;
      case DocumentStatus.rejected:
        return Icons.cancel;
      case DocumentStatus.expired:
        return Icons.error;
    }
  }

  String _getStatusText() {
    if (document.isExpired) return 'Expired';
    if (document.isExpiringSoon) {
      final days = document.daysUntilExpiry;
      return days == 1 ? 'Expires tomorrow' : 'Expires in $days days';
    }

    switch (document.status) {
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.pendingReview:
        return 'Under Review';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }

  IconData _getDocumentIcon() {
    switch (document.documentType) {
      case DocumentType.phvDriverLicence:
        return Icons.badge;
      case DocumentType.phvVehicleLicence:
        return Icons.directions_car;
      case DocumentType.hireRewardInsurance:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main content with left accent bar
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  color: statusColor,
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: RelayColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getDocumentIcon(),
                                color: RelayColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                document.documentType.displayName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(),
                                    color: statusColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getStatusText(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Details row
                        Row(
                          children: [
                            _DetailChip(
                              icon: Icons.calendar_today,
                              label: 'Expires',
                              value: _formatDate(document.expiryDate),
                              isWarning: document.isExpiringSoon || document.isExpired,
                            ),
                            const SizedBox(width: 16),
                            if (document.licenseNumber != null)
                              Expanded(
                                child: _DetailChip(
                                  icon: Icons.tag,
                                  label: 'Ref',
                                  value: document.licenseNumber!,
                                ),
                              ),
                          ],
                        ),

                        // Verified timestamp
                        if (document.status == DocumentStatus.verified &&
                            document.verifiedAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: RelayColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified ${_formatDate(document.verifiedAt!)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: RelayColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rejection reason (if applicable)
          if (document.status == DocumentStatus.rejected &&
              document.rejectionReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RelayColors.dangerBackground,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: RelayColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rejection reason:',
                          style: TextStyle(
                            color: RelayColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          document.rejectionReason!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: RelayColors.danger,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Expiring soon warning
          if (document.isExpiringSoon && document.status != DocumentStatus.rejected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: RelayColors.warningBackground,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: RelayColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This document expires in ${document.daysUntilExpiry} days. Consider uploading a renewal.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: RelayColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
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
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isWarning
              ? RelayColors.danger
              : Theme.of(context).colorScheme.onSurface.withAlpha(128),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isWarning ? RelayColors.danger : null,
              ),
        ),
      ],
    );
  }
}
