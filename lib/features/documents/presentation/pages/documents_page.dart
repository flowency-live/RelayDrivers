import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/relay_colors.dart';
import '../../../vehicles/application/vehicle_providers.dart';
import '../../../vehicles/domain/models/vehicle.dart';
import '../../application/document_providers.dart';
import '../../domain/models/document.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_document_sheet.dart';

/// Documents page - redesigned for clear 3-document journey
/// 1. PHV Driver Licence (driver)
/// 2. PHV Vehicle Licence (per vehicle)
/// 3. Hire & Reward Insurance
class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  @override
  void initState() {
    super.initState();
    // Load documents on page load
    Future.microtask(() {
      ref.read(documentStateProvider.notifier).loadDocuments();
    });
  }

  void _showUploadSheet(DocumentType type, {String? vehicleVrn}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadDocumentSheet(
        documentType: type,
        preselectedVehicleVrn: vehicleVrn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentState = ref.watch(documentStateProvider);
    final documents = ref.watch(documentListProvider);
    final vehicles = ref.watch(vehicleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
      ),
      body: switch (documentState) {
        DocumentInitial() || DocumentLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        DocumentError(:final message) => _ErrorView(
            message: message,
            onRetry: () {
              ref.read(documentStateProvider.notifier).loadDocuments();
            },
          ),
        DocumentLoaded() || DocumentUploading() => RefreshIndicator(
            onRefresh: () async {
              await ref.read(documentStateProvider.notifier).loadDocuments();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Progress summary
                _DocumentProgressCard(documents: documents),
                const SizedBox(height: 24),

                // 1. Driver Licence section
                _DocumentSection(
                  title: 'PHV Driver Licence',
                  description: 'Your private hire driver licence',
                  icon: Icons.badge,
                  accentColor: RelayColors.primary,
                  documents: documents
                      .where((d) => d.documentType == DocumentType.phvDriverLicence)
                      .toList(),
                  onAdd: () => _showUploadSheet(DocumentType.phvDriverLicence),
                  maxDocuments: 1,
                ),
                const SizedBox(height: 20),

                // 2. Vehicle Licences section (per vehicle)
                _VehicleLicenceSection(
                  vehicles: vehicles,
                  documents: documents
                      .where((d) => d.documentType == DocumentType.phvVehicleLicence)
                      .toList(),
                  onAdd: (vrn) => _showUploadSheet(
                    DocumentType.phvVehicleLicence,
                    vehicleVrn: vrn,
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Insurance section
                _DocumentSection(
                  title: 'Hire & Reward Insurance',
                  description: 'Insurance covering your private hire work',
                  icon: Icons.security,
                  accentColor: RelayColors.success,
                  documents: documents
                      .where((d) => d.documentType == DocumentType.hireRewardInsurance)
                      .toList(),
                  onAdd: () => _showUploadSheet(DocumentType.hireRewardInsurance),
                  // Insurance can have multiple (renewals, different policies)
                  maxDocuments: null,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
      },
    );
  }
}

/// Progress summary card showing overall document status
class _DocumentProgressCard extends StatelessWidget {
  final List<DriverDocument> documents;

  const _DocumentProgressCard({required this.documents});

  @override
  Widget build(BuildContext context) {
    // Count completed documents
    final hasDriverLicence = documents.any(
      (d) => d.documentType == DocumentType.phvDriverLicence,
    );
    final hasInsurance = documents.any(
      (d) => d.documentType == DocumentType.hireRewardInsurance,
    );

    // Count issues
    final expiringSoon = documents.where((d) => d.isExpiringSoon).length;
    final expired = documents.where((d) => d.isExpired).length;
    final rejected = documents.where((d) => d.status == DocumentStatus.rejected).length;
    final issues = expiringSoon + expired + rejected;

    final completedCount = (hasDriverLicence ? 1 : 0) + (hasInsurance ? 1 : 0);
    final requiredCount = 2; // Driver licence + insurance (vehicle licences are per-vehicle)

    final allComplete = completedCount == requiredCount && issues == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allComplete
              ? [RelayColors.success, RelayColors.success.withAlpha(200)]
              : issues > 0
                  ? [RelayColors.warning, RelayColors.warning.withAlpha(200)]
                  : [RelayColors.primary, RelayColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              allComplete
                  ? Icons.check_circle
                  : issues > 0
                      ? Icons.warning_rounded
                      : Icons.description_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allComplete
                      ? 'All documents complete'
                      : issues > 0
                          ? '$issues document${issues > 1 ? 's' : ''} need attention'
                          : '$completedCount of $requiredCount required documents',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allComplete
                      ? 'Your documents are up to date'
                      : issues > 0
                          ? _getIssuesSummary(expiringSoon, expired, rejected)
                          : 'Upload your documents to get started',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIssuesSummary(int expiring, int expired, int rejected) {
    final parts = <String>[];
    if (expired > 0) parts.add('$expired expired');
    if (expiring > 0) parts.add('$expiring expiring soon');
    if (rejected > 0) parts.add('$rejected rejected');
    return parts.join(', ');
  }
}

/// Generic document section for driver licence and insurance
class _DocumentSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<DriverDocument> documents;
  final VoidCallback onAdd;
  final int? maxDocuments;

  const _DocumentSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.documents,
    required this.onAdd,
    this.maxDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = documents.isEmpty;
    final canAddMore = maxDocuments == null || documents.length < maxDocuments!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(179),
                        ),
                  ),
                ],
              ),
            ),
            if (canAddMore && !isEmpty)
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                color: accentColor,
                tooltip: 'Add $title',
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Document list or empty state
        if (isEmpty)
          _EmptyDocumentCard(
            title: title,
            onAdd: onAdd,
            accentColor: accentColor,
          )
        else
          ...documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DocumentCard(document: doc),
            ),
          ),
      ],
    );
  }
}

/// Vehicle licence section - shows licences per vehicle
class _VehicleLicenceSection extends StatelessWidget {
  final List<Vehicle> vehicles;
  final List<DriverDocument> documents;
  final void Function(String vrn) onAdd;

  const _VehicleLicenceSection({
    required this.vehicles,
    required this.documents,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RelayColors.info.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: RelayColors.info, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PHV Vehicle Licences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'One licence required per vehicle',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(179),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // No vehicles message
        if (vehicles.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(50),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add a vehicle first to upload its licence',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          // List vehicles with their licence status
          ...vehicles.map((vehicle) {
            final vehicleDocs = documents
                .where((d) => d.vehicleVrn == vehicle.vrn)
                .toList();
            final hasLicence = vehicleDocs.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VehicleLicenceCard(
                vehicle: vehicle,
                documents: vehicleDocs,
                onAdd: () => onAdd(vehicle.vrn),
              ),
            );
          }),
      ],
    );
  }
}

/// Card showing a vehicle and its licence status
class _VehicleLicenceCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DriverDocument> documents;
  final VoidCallback onAdd;

  const _VehicleLicenceCard({
    required this.vehicle,
    required this.documents,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasLicence = documents.isNotEmpty;

    if (!hasLicence) {
      // Show add licence prompt for this vehicle
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RelayColors.dangerBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RelayColors.danger.withAlpha(50)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RelayColors.danger.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: RelayColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.vrn} - ${vehicle.displayName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Missing vehicle licence',
                      style: TextStyle(
                        color: RelayColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
                style: FilledButton.styleFrom(
                  backgroundColor: RelayColors.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show uploaded documents for this vehicle
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle header
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
              const SizedBox(width: 8),
              Text(
                '${vehicle.vrn} - ${vehicle.displayName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                    ),
              ),
            ],
          ),
        ),
        ...documents.map(
          (doc) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DocumentCard(document: doc),
          ),
        ),
      ],
    );
  }
}

/// Empty state card prompting document upload
class _EmptyDocumentCard extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final Color accentColor;

  const _EmptyDocumentCard({
    required this.title,
    required this.onAdd,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RelayColors.dangerBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RelayColors.danger.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RelayColors.danger.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: RelayColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: RelayColors.danger,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Please upload your $title',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload'),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
