import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/domain/models/driver_user.dart';

/// My Operators page - shows all operators the driver has relationships with
/// Allows switching active operator and viewing operator details
class MyOperatorsPage extends ConsumerWidget {
  const MyOperatorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Operators')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeOperators = user.operators.where((op) => op.isActive).toList();
    final invitedOperators = user.operators.where((op) => op.isInvited).toList();
    final revokedOperators = user.operators.where((op) => op.isRevoked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Operators'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Driver-Owned Profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your profile belongs to you. You grant operators access to work with them. '
                    'You can share documents with each operator individually.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active Operators
            if (activeOperators.isNotEmpty) ...[
              _SectionHeader(
                title: 'Active Operators',
                count: activeOperators.length,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              ...activeOperators.map((op) => _OperatorCard(
                    operator: op,
                    isCurrentOperator: op.tenantId == user.activeOperator,
                    onTap: () => _showSwitchingComingSoon(context),
                    onManageDocuments: () => _manageDocuments(context, op.tenantId),
                  )),
              const SizedBox(height: 24),
            ],

            // Invited Operators (pending acceptance)
            if (invitedOperators.isNotEmpty) ...[
              _SectionHeader(
                title: 'Pending Invites',
                count: invitedOperators.length,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              ...invitedOperators.map((op) => _OperatorCard(
                    operator: op,
                    isCurrentOperator: false,
                    isPending: true,
                    onTap: () => _acceptInvite(context, ref, op.tenantId),
                  )),
              const SizedBox(height: 24),
            ],

            // Revoked (past operators)
            if (revokedOperators.isNotEmpty) ...[
              _SectionHeader(
                title: 'Past Operators',
                count: revokedOperators.length,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              ...revokedOperators.map((op) => _OperatorCard(
                    operator: op,
                    isCurrentOperator: false,
                    isRevoked: true,
                  )),
            ],

            // Empty state
            if (user.operators.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withAlpha(128),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Operators Yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have not been invited by any operators yet.\n'
                      'When an operator invites you, they will appear here.',
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
              ),
          ],
        ),
      ),
    );
  }

  void _showSwitchingComingSoon(BuildContext context) {
    // TODO: Multi-operator switching will require backend JWT refresh
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Multi-operator switching coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manageDocuments(BuildContext context, String operatorId) {
    // TODO: Navigate to document sharing page for this operator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document sharing for $operatorId coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _acceptInvite(BuildContext context, WidgetRef ref, String operatorId) {
    // TODO: Implement invite acceptance flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accepting invite from $operatorId...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

class _OperatorCard extends StatelessWidget {
  final OperatorAccess operator;
  final bool isCurrentOperator;
  final bool isPending;
  final bool isRevoked;
  final VoidCallback? onTap;
  final VoidCallback? onManageDocuments;

  const _OperatorCard({
    required this.operator,
    required this.isCurrentOperator,
    this.isPending = false,
    this.isRevoked = false,
    this.onTap,
    this.onManageDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isRevoked
        ? Colors.grey
        : isPending
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentOperator
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isRevoked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                operator.tenantId,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: isCurrentOperator
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                            if (isCurrentOperator)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Active',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRevoked && !isPending)
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withAlpha(128),
                    ),
                ],
              ),

              // Scopes
              if (operator.scopes.isNotEmpty && !isRevoked) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: operator.scopes.map((scope) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Text(
                        scope,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Action buttons for active operators
              if (!isRevoked && !isPending && onManageDocuments != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onManageDocuments,
                        icon: const Icon(Icons.folder_shared, size: 18),
                        label: const Text('Shared Documents'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Accept button for pending invites
              if (isPending && onTap != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept Invite'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (isRevoked) return 'Access revoked';
    if (isPending) return 'Invite pending acceptance';
    if (isCurrentOperator) return 'Currently active operator';
    return 'Tap to switch to this operator';
  }
}
