import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/domain/models/driver_user.dart';
import '../../application/document_providers.dart';
import '../../domain/models/document.dart';

/// Share Document Page - manage which operators a document is shared with
/// Part of the driver-owned architecture (v4.0)
class ShareDocumentPage extends ConsumerStatefulWidget {
  final String documentId;

  const ShareDocumentPage({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<ShareDocumentPage> createState() => _ShareDocumentPageState();
}

class _ShareDocumentPageState extends ConsumerState<ShareDocumentPage> {
  late Set<String> _selectedOperators;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedOperators = {};
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final documentState = ref.watch(documentStateProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share Document')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Find the document
    DriverDocument? document;
    if (documentState is DocumentLoaded) {
      document = documentState.documents
          .where((d) => d.documentId == widget.documentId)
          .firstOrNull;
    }

    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share Document')),
        body: const Center(child: Text('Document not found')),
      );
    }

    // Initialize selected operators from document's current sharing state
    if (_selectedOperators.isEmpty && document.sharedWith.isNotEmpty) {
      _selectedOperators = document.sharedWith.toSet();
    }

    final activeOperators = user.operators.where((op) => op.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Document'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () => _saveSharing(document!),
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document info card
            _DocumentInfoCard(document: document),

            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your document, your control',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You own this document. Choose which operators can view it. '
                          'You can change this at any time.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Operators section
            Text(
              'Share with operators',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select which operators can view this document',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withAlpha(179),
                  ),
            ),

            const SizedBox(height: 16),

            if (activeOperators.isEmpty)
              _EmptyOperatorsView()
            else
              ...activeOperators.map((operator) => _OperatorTile(
                    operator: operator,
                    isSelected: _selectedOperators.contains(operator.tenantId),
                    onToggle: () => _toggleOperator(operator.tenantId),
                  )),

            const SizedBox(height: 24),

            // Sharing status
            _SharingStatusCard(
              totalOperators: activeOperators.length,
              sharedWith: _selectedOperators.length,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleOperator(String operatorId) {
    setState(() {
      if (_selectedOperators.contains(operatorId)) {
        _selectedOperators.remove(operatorId);
      } else {
        _selectedOperators.add(operatorId);
      }
    });
  }

  Future<void> _saveSharing(DriverDocument document) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call backend API to update document sharing
      // await ref.read(documentStateProvider.notifier).updateSharing(
      //   document.documentId,
      //   _selectedOperators.toList(),
      // );

      // For now, show success message
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedOperators.isEmpty
                  ? 'Document is now private (not shared)'
                  : 'Document shared with ${_selectedOperators.length} operator(s)',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sharing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _DocumentInfoCard extends StatelessWidget {
  final DriverDocument document;

  const _DocumentInfoCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.documentType.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(status: document.status),
                      const SizedBox(width: 8),
                      if (document.expiryDate.isNotEmpty)
                        Text(
                          'Expires: ${document.expiryDate}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case DocumentStatus.verified:
        color = Colors.green;
        break;
      case DocumentStatus.pendingReview:
        color = Colors.orange;
        break;
      case DocumentStatus.rejected:
      case DocumentStatus.expired:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  final OperatorAccess operator;
  final bool isSelected;
  final VoidCallback onToggle;

  const _OperatorTile({
    required this.operator,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withAlpha(25)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Icon(
                  Icons.business,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withAlpha(179),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator.tenantId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected ? 'Shared' : 'Not shared',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withAlpha(128),
                          ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharingStatusCard extends StatelessWidget {
  final int totalOperators;
  final int sharedWith;

  const _SharingStatusCard({
    required this.totalOperators,
    required this.sharedWith,
  });

  @override
  Widget build(BuildContext context) {
    final isPrivate = sharedWith == 0;
    final isSharedWithAll = sharedWith == totalOperators;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrivate
            ? Colors.grey.withAlpha(25)
            : isSharedWithAll
                ? Colors.green.withAlpha(25)
                : Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrivate
              ? Colors.grey.withAlpha(50)
              : isSharedWithAll
                  ? Colors.green.withAlpha(50)
                  : Colors.blue.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPrivate
                ? Icons.lock
                : isSharedWithAll
                    ? Icons.public
                    : Icons.share,
            color: isPrivate
                ? Colors.grey
                : isSharedWithAll
                    ? Colors.green
                    : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrivate
                      ? 'Private'
                      : isSharedWithAll
                          ? 'Shared with all operators'
                          : 'Shared with $sharedWith of $totalOperators operators',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPrivate
                      ? 'This document is not visible to any operators'
                      : 'Operators can view this document in their portal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOperatorsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 48,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No operators to share with',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You need to be connected with at least one operator to share documents.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha(179),
                ),
          ),
        ],
      ),
    );
  }
}
