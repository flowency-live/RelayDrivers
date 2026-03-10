import 'package:flutter/material.dart';
import '../../domain/models/document.dart';

/// Card widget displaying document information with status
class DocumentCard extends StatelessWidget {
  final DriverDocument document;

  const DocumentCard({
    super.key,
    required this.document,
  });

  Color _getStatusColor() {
    if (document.isExpired) return const Color(0xFFE63946);
    if (document.isExpiringSoon) return const Color(0xFFF39C12);

    switch (document.status) {
      case DocumentStatus.verified:
        return const Color(0xFF2ECC71);
      case DocumentStatus.pendingReview:
        return const Color(0xFF3498DB);
      case DocumentStatus.rejected:
        return const Color(0xFFE63946);
      case DocumentStatus.expired:
        return const Color(0xFFE63946);
    }
  }

  IconData _getStatusIcon() {
    if (document.isExpired) return Icons.error;
    if (document.isExpiringSoon) return Icons.warning;

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
      return 'Expires in ${document.daysUntilExpiry} days';
    }

    switch (document.status) {
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.pendingReview:
        return 'Pending Review';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    _getDocumentIcon(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.documentType.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (document.vehicleVrn != null)
                          Text(
                            'Vehicle: ${document.vehicleVrn}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'Expires',
                      value: _formatDate(document.expiryDate),
                      isWarning: document.isExpiringSoon || document.isExpired,
                    ),
                  ),
                  if (document.licenseNumber != null)
                    Expanded(
                      child: _DetailItem(
                        label: 'License No.',
                        value: document.licenseNumber!,
                      ),
                    ),
                ],
              ),

              // Rejection reason
              if (document.status == DocumentStatus.rejected &&
                  document.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              document.rejectionReason!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Verified info
              if (document.status == DocumentStatus.verified &&
                  document.verifiedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Verified on ${_formatDate(document.verifiedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2ECC71),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    switch (document.documentType) {
      case DocumentType.phvDriverLicense:
        return Icons.badge;
      case DocumentType.driverInsurance:
        return Icons.security;
      case DocumentType.phvVehicleLicense:
        return Icons.directions_car;
      case DocumentType.vehicleInsurance:
        return Icons.verified_user;
    }
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

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _DetailItem({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isWarning ? const Color(0xFFE63946) : null,
              ),
        ),
      ],
    );
  }
}
