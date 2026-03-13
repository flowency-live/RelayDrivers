import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/domain/models/driver_user.dart';
import '../../../../core/network/dio_client.dart';

/// Operator selector widget - shows when driver has multiple operators
/// Allows switching between operators for multi-operator drivers
class OperatorSelector extends ConsumerWidget {
  const OperatorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);

    if (user == null) return const SizedBox.shrink();

    // Only show if driver has multiple active operators
    if (!authService.hasMultipleOperators(user)) {
      return const SizedBox.shrink();
    }

    final activeOperator = user.activeOperatorAccess;
    final operators = user.operators.where((op) => op.isActive).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showOperatorPicker(context, ref, user, operators),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Operator',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withAlpha(179),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeOperator?.tenantId ?? 'No operator selected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${operators.length} operators',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(width: 8),
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
        ),
      ),
    );
  }

  void _showOperatorPicker(
    BuildContext context,
    WidgetRef ref,
    DriverUser user,
    List<OperatorAccess> operators,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OperatorPickerSheet(
        user: user,
        operators: operators,
        onSelect: (operatorId) async {
          Navigator.pop(context);
          await _switchOperator(context, ref, user, operatorId);
        },
      ),
    );
  }

  Future<void> _switchOperator(
    BuildContext context,
    WidgetRef ref,
    DriverUser user,
    String operatorId,
  ) async {
    // Update local storage for the DioClient
    final dioClient = ref.read(dioClientProvider);
    await dioClient.setActiveOperator(operatorId);

    // Show confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to operator: $operatorId'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // TODO: In a full implementation, we would also:
    // 1. Call backend to get a new JWT with updated activeOperator
    // 2. Update the user state with the new activeOperator
    // For now, the X-Operator-Id header will be used for API calls
  }
}

class _OperatorPickerSheet extends StatelessWidget {
  final DriverUser user;
  final List<OperatorAccess> operators;
  final void Function(String operatorId) onSelect;

  const _OperatorPickerSheet({
    required this.user,
    required this.operators,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Operator',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which operator to work with',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha(179),
                ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: operators.length,
            itemBuilder: (context, index) {
              final operator = operators[index];
              final isActive = operator.tenantId == user.activeOperator;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary.withAlpha(25)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Icon(
                    Icons.business,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withAlpha(179),
                  ),
                ),
                title: Text(
                  operator.tenantId,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  'Scopes: ${operator.scopes.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: isActive
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => onSelect(operator.tenantId),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
