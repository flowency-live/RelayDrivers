import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/vehicle_providers.dart';
import '../../domain/models/vehicle.dart';

/// Bottom sheet for adding a new vehicle by VRN
class AddVehicleSheet extends ConsumerStatefulWidget {
  const AddVehicleSheet({super.key});

  @override
  ConsumerState<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _vrnController = TextEditingController();

  bool _isLookingUp = false;
  bool _isAdding = false;
  String? _error;
  DvlaLookupResult? _lookupResult;

  @override
  void dispose() {
    _vrnController.dispose();
    super.dispose();
  }

  String _formatVrn(String vrn) {
    return vrn.toUpperCase().replaceAll(' ', '');
  }

  bool _isValidVrn(String vrn) {
    final formatted = _formatVrn(vrn);
    // UK VRN patterns: AB12 CDE, AB12CDE, A123 BCD, etc.
    final vrnRegex = RegExp(r'^[A-Z]{2}\d{2}[A-Z]{3}$|^[A-Z]\d{3}[A-Z]{3}$|^[A-Z]{3}\d{3}[A-Z]$|^[A-Z]\d[A-Z]{3}$|^[A-Z]{2}\d{3}$|^[A-Z]{3}\d{3}$|^\d{3}[A-Z]{3}$|^[A-Z]{1,3}\d{1,4}$|^\d{1,4}[A-Z]{1,3}$');
    return vrnRegex.hasMatch(formatted);
  }

  Future<void> _lookupVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLookingUp = true;
      _error = null;
      _lookupResult = null;
    });

    final vrn = _formatVrn(_vrnController.text);
    final result = await ref.read(vehicleStateProvider.notifier).lookupVehicle(vrn);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _lookupResult = result;
        _isLookingUp = false;
      });
    } else {
      setState(() {
        _error = 'Could not find vehicle. Please check the registration number.';
        _isLookingUp = false;
      });
    }
  }

  Future<void> _addVehicle() async {
    setState(() {
      _isAdding = true;
      _error = null;
    });

    final vrn = _formatVrn(_vrnController.text);
    final success = await ref.read(vehicleStateProvider.notifier).addVehicle(vrn);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_lookupResult?.make ?? vrn} added successfully'),
          backgroundColor: const Color(0xFF2ECC71),
        ),
      );
    } else {
      setState(() {
        _error = 'Failed to add vehicle. Please try again.';
        _isAdding = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _lookupResult = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Add Vehicle',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your vehicle registration number and we\'ll fetch details from DVLA.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha(179),
                ),
          ),
          const SizedBox(height: 24),

          if (_lookupResult == null) ...[
            // VRN input form
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _vrnController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'e.g. AB12 CDE',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a registration number';
                  }
                  if (!_isValidVrn(value)) {
                    return 'Please enter a valid UK registration number';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _lookupVehicle(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLookingUp ? null : _lookupVehicle,
              child: _isLookingUp
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Look Up Vehicle'),
            ),
          ] else ...[
            // Lookup result preview
            _VehiclePreview(
              result: _lookupResult!,
              onConfirm: _addVehicle,
              onCancel: _reset,
              isAdding: _isAdding,
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Preview of vehicle details before confirming addition
class _VehiclePreview extends StatelessWidget {
  final DvlaLookupResult result;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isAdding;

  const _VehiclePreview({
    required this.result,
    required this.onConfirm,
    required this.onCancel,
    required this.isAdding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // VRN badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              result.vrn,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Vehicle details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Column(
            children: [
              _DetailRow(
                label: 'Make',
                value: result.make ?? 'Unknown',
              ),
              const Divider(height: 24),
              _DetailRow(
                label: 'Model',
                value: result.model ?? 'Unknown',
              ),
              const Divider(height: 24),
              _DetailRow(
                label: 'Colour',
                value: result.colour ?? 'Unknown',
              ),
              const Divider(height: 24),
              _DetailRow(
                label: 'MOT Status',
                value: result.motStatus ?? 'Unknown',
                valueColor: _getStatusColor(result.motStatus),
              ),
              if (result.motExpiryDate != null) ...[
                const SizedBox(height: 4),
                _DetailRow(
                  label: 'MOT Expiry',
                  value: _formatDate(result.motExpiryDate!),
                ),
              ],
              const Divider(height: 24),
              _DetailRow(
                label: 'Tax Status',
                value: result.taxStatus ?? 'Unknown',
                valueColor: _getStatusColor(result.taxStatus),
              ),
              if (result.taxDueDate != null) ...[
                const SizedBox(height: 4),
                _DetailRow(
                  label: 'Tax Due',
                  value: _formatDate(result.taxDueDate!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isAdding ? null : onCancel,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isAdding ? null : onConfirm,
                child: isAdding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Vehicle'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color? _getStatusColor(String? status) {
    if (status == null) return null;
    final lower = status.toLowerCase();
    if (lower.contains('valid') || lower == 'taxed') {
      return const Color(0xFF2ECC71);
    }
    if (lower.contains('expired') || lower == 'sorn' || lower == 'untaxed') {
      return const Color(0xFFE63946);
    }
    return null;
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(179),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
