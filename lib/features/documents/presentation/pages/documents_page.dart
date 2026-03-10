import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/document_providers.dart';
import '../../domain/models/document.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_document_sheet.dart';

/// Documents page - list and manage driver documents
class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load documents on page load
    Future.microtask(() {
      ref.read(documentStateProvider.notifier).loadDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUploadSheet({DocumentType? preselectedType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadDocumentSheet(
        preselectedType: preselectedType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentState = ref.watch(documentStateProvider);
    final driverDocs = ref.watch(driverDocumentsProvider);
    final vehicleDocs = ref.watch(vehicleDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.person_outline),
              text: 'Driver (${driverDocs.length})',
            ),
            Tab(
              icon: const Icon(Icons.directions_car_outlined),
              text: 'Vehicle (${vehicleDocs.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
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
        DocumentLoaded() || DocumentUploading() => TabBarView(
            controller: _tabController,
            children: [
              // Driver documents tab
              _DocumentList(
                documents: driverDocs,
                emptyMessage: 'No driver documents yet',
                emptyDescription:
                    'Upload your PHV driver license and insurance documents.',
                documentTypes: [
                  DocumentType.phvDriverLicense,
                  DocumentType.driverInsurance,
                ],
                onUpload: _showUploadSheet,
              ),
              // Vehicle documents tab
              _DocumentList(
                documents: vehicleDocs,
                emptyMessage: 'No vehicle documents yet',
                emptyDescription:
                    'Upload your PHV vehicle license and insurance documents.',
                documentTypes: [
                  DocumentType.phvVehicleLicense,
                  DocumentType.vehicleInsurance,
                ],
                onUpload: _showUploadSheet,
              ),
            ],
          ),
      },
    );
  }
}

class _DocumentList extends StatelessWidget {
  final List<DriverDocument> documents;
  final String emptyMessage;
  final String emptyDescription;
  final List<DocumentType> documentTypes;
  final void Function({DocumentType? preselectedType}) onUpload;

  const _DocumentList({
    required this.documents,
    required this.emptyMessage,
    required this.emptyDescription,
    required this.documentTypes,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return _EmptyDocumentView(
        message: emptyMessage,
        description: emptyDescription,
        documentTypes: documentTypes,
        onUpload: onUpload,
      );
    }

    // Group documents by type
    final groupedDocs = <DocumentType, List<DriverDocument>>{};
    for (final type in documentTypes) {
      groupedDocs[type] = documents.where((d) => d.documentType == type).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final type in documentTypes) ...[
          _DocumentTypeSection(
            documentType: type,
            documents: groupedDocs[type] ?? [],
            onUpload: () => onUpload(preselectedType: type),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _DocumentTypeSection extends StatelessWidget {
  final DocumentType documentType;
  final List<DriverDocument> documents;
  final VoidCallback onUpload;

  const _DocumentTypeSection({
    required this.documentType,
    required this.documents,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              documentType.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (documents.isEmpty)
              TextButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(50),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Required - please upload your ${documentType.displayName.toLowerCase()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
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

class _EmptyDocumentView extends StatelessWidget {
  final String message;
  final String description;
  final List<DocumentType> documentTypes;
  final void Function({DocumentType? preselectedType}) onUpload;

  const _EmptyDocumentView({
    required this.message,
    required this.description,
    required this.documentTypes,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withAlpha(179),
                  ),
            ),
            const SizedBox(height: 32),
            // Quick upload buttons for each type
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: documentTypes.map((type) {
                return OutlinedButton.icon(
                  onPressed: () => onUpload(preselectedType: type),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(type.displayName),
                );
              }).toList(),
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
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
