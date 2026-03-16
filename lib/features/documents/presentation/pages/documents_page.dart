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
                const SizedBox(height: 28),

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
                const SizedBox(height: 24),

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
                const SizedBox(height: 24),

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
class _DocumentProgressCard extends ConsumerWidget {
  final List<DriverDocument> documents;

  const _DocumentProgressCard({required this.documents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleListProvider);

    // Count completed documents
    final hasDriverLicence = documents.any(
      (d) => d.documentType == DocumentType.phvDriverLicence,
    );
    final hasInsurance = documents.any(
      (d) => d.documentType == DocumentType.hireRewardInsurance,
    );

    // Count vehicle licences
    final vehicleLicences = documents
        .where((d) => d.documentType == DocumentType.phvVehicleLicence)
        .toList();
    final vehiclesWithLicence = vehicles.where((v) =>
        vehicleLicences.any((d) => d.vehicleVrn == v.vrn)).length;

    final expiringSoon = documents.where((d) => d.isExpiringSoon).length;
    final expired = documents.where((d) => d.isExpired).length;
    final rejected = documents.where((d) => d.status == DocumentStatus.rejected).length;
    final issues = expiringSoon + expired + rejected;

    // Required: Driver licence + Insurance + one licence per vehicle
    final completedCount = (hasDriverLicence ? 1 : 0) +
                           (hasInsurance ? 1 : 0) +
                           vehiclesWithLicence;
    final requiredCount = 2 + vehicles.length; // 2 base + vehicle count

    final allComplete = completedCount == requiredCount && issues == 0 && requiredCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allComplete
              ? [RelayColors.success, RelayColors.successLight]
              : issues > 0
                  ? [RelayColors.warning, RelayColors.warningLight]
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
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              allComplete
                  ? Icons.check_circle
                  : issues > 0
                      ? Icons.warning_rounded
                      : Icons.description_outlined,
              color: Colors.white,
              size: 28,
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  allComplete
                      ? 'Your documents are up to date'
                      : issues > 0
                          ? _getIssuesSummary(expiringSoon, expired, rejected)
                          : 'Upload your documents to get started',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(160),
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
          _MissingDocumentCard(
            documentName: title,
            onUpload: onAdd,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RelayColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car, color: RelayColors.info, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    'One licence required per vehicle',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(160),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(40),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add a vehicle first to upload its licence',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          ...vehicles.map((vehicle) {
            final vehicleDocs = documents
                .where((d) => d.vehicleVrn == vehicle.vrn)
                .toList();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!hasLicence) {
      // Missing licence card with left accent bar
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? RelayColors.darkSurface2
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? RelayColors.darkBorderDefault
                : Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar (warning color)
              Container(
                width: 4,
                color: RelayColors.warning,
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Warning icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: RelayColors.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: RelayColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Vehicle info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${vehicle.vrn} - ${vehicle.displayName}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Missing vehicle licence',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: RelayColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Upload button
                      FilledButton(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          backgroundColor: RelayColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Upload'),
                      ),
                    ],
                  ),
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
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              ),
              const SizedBox(width: 8),
              Text(
                '${vehicle.vrn} - ${vehicle.displayName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
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

/// Card showing a missing required document with left accent bar
class _MissingDocumentCard extends StatelessWidget {
  final String documentName;
  final VoidCallback onUpload;

  const _MissingDocumentCard({
    required this.documentName,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? RelayColors.darkSurface2
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? RelayColors.darkBorderDefault
              : Theme.of(context).colorScheme.outline.withAlpha(60),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar (warning/required color)
            Container(
              width: 4,
              color: RelayColors.warning,
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Warning icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RelayColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: RelayColors.warning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Required',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: RelayColors.warning,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Please upload your $documentName',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Upload button
                    FilledButton(
                      onPressed: onUpload,
                      style: FilledButton.styleFrom(
                        backgroundColor: RelayColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Upload'),
                    ),
                  ],
                ),
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
