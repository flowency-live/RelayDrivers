import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/uk_number_plate_input.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../widgets/wizard_scaffold.dart';
import '../../../vehicles/application/vehicle_providers.dart';

/// Phase 2, Step 1: Vehicle Registration
/// Enter VRN and show DVLA lookup results
class VehicleRegistrationStep extends ConsumerStatefulWidget {
  const VehicleRegistrationStep({super.key});

  @override
  ConsumerState<VehicleRegistrationStep> createState() =>
      _VehicleRegistrationStepState();
}

class _VehicleRegistrationStepState
    extends ConsumerState<VehicleRegistrationStep> {
  final _vrnController = TextEditingController();
  bool _isLookingUp = false;
  bool _hasLookedUp = false;
  String? _lookupError;

  // Vehicle details from DVLA lookup
  String? _make;
  String? _colour;
  String? _motStatus;
  String? _motExpiry;
  String? _taxStatus;
  String? _taxDueDate;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = ref.read(onboardingWizardProvider).data;
    _vrnController.text = data.vehicleVrn ?? '';
    _make = data.vehicleMake;
    _colour = data.vehicleColour;
    _motStatus = data.vehicleMotStatus;
    _taxStatus = data.vehicleTaxStatus;

    if (data.vehicleVrn != null && data.vehicleVrn!.isNotEmpty) {
      _hasLookedUp = true;
    }
  }

  @override
  void dispose() {
    _vrnController.dispose();
    super.dispose();
  }

  Future<void> _lookupVehicle() async {
    final vrn = _vrnController.text.trim().toUpperCase().replaceAll(' ', '');
    if (vrn.isEmpty) return;

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _hasLookedUp = false;
    });

    try {
      // Use the vehicle notifier to lookup
      final result = await ref.read(vehicleStateProvider.notifier).lookupVehicle(vrn);

      if (result != null) {
        setState(() {
          _make = result.make;
          _colour = result.colour;
          _motStatus = result.motStatus;
          _motExpiry = result.motExpiryDate;
          _taxStatus = result.taxStatus;
          _taxDueDate = result.taxDueDate;
          _hasLookedUp = true;
        });
      } else {
        setState(() {
          _lookupError = 'Vehicle not found. Please check the registration.';
        });
      }
    } catch (e) {
      setState(() {
        _lookupError = 'Could not lookup vehicle: $e';
      });
    } finally {
      setState(() {
        _isLookingUp = false;
      });
    }
  }

  bool get _isValid {
    return _vrnController.text.trim().isNotEmpty && _hasLookedUp;
  }

  bool _isAdding = false;

  Future<void> _saveAndContinue() async {
    final vrn = _vrnController.text.trim().toUpperCase().replaceAll(' ', '');

    setState(() => _isAdding = true);

    try {
      // Add vehicle to backend (this also saves it)
      final success = await ref.read(onboardingWizardProvider.notifier).addVehicle(vrn: vrn);

      if (success) {
        ref.read(onboardingWizardProvider.notifier).nextStep();
      } else {
        final error = ref.read(onboardingWizardProvider).error;
        if (mounted && error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _goBack() {
    ref.read(onboardingWizardProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WizardScaffold(
      step: WizardStep.vehicleRegistration,
      canGoNext: _isValid,
      isLoading: _isAdding,
      onBack: _goBack,
      onNext: _saveAndContinue,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info banner
          const WizardInfoBanner(
            message:
                'Enter your vehicle registration and we\'ll check MOT and tax status',
            icon: Icons.directions_car,
          ),
          const SizedBox(height: 24),

          // VRN input with lookup button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: UKNumberPlateInput(
                  controller: _vrnController,
                  errorText: _lookupError,
                  enabled: !_isLookingUp,
                  isLoading: _isLookingUp,
                  onChanged: (_) {
                    setState(() {
                      _hasLookedUp = false;
                      _lookupError = null;
                    });
                  },
                  onLookup: _lookupVehicle,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLookingUp ? null : _lookupVehicle,
                  child: _isLookingUp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Check'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vehicle details card (shown after lookup)
          if (_hasLookedUp) ...[
            _VehicleDetailsCard(
              make: _make,
              colour: _colour,
              motStatus: _motStatus,
              motExpiry: _motExpiry,
              taxStatus: _taxStatus,
              taxDueDate: _taxDueDate,
            ),
            const SizedBox(height: 16),

            // Success message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vehicle found! Check the details are correct.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Not your vehicle hint
          if (_hasLookedUp) ...[
            const SizedBox(height: 24),
            Text(
              'Not your vehicle?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the correct registration number above and tap Check again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vehicle details card showing DVLA lookup results
class _VehicleDetailsCard extends StatelessWidget {
  final String? make;
  final String? colour;
  final String? motStatus;
  final String? motExpiry;
  final String? taxStatus;
  final String? taxDueDate;

  const _VehicleDetailsCard({
    this.make,
    this.colour,
    this.motStatus,
    this.motExpiry,
    this.taxStatus,
    this.taxDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle make and colour
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        make ?? 'Unknown Make',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (colour != null)
                        Text(
                          colour!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // MOT and Tax status
            Row(
              children: [
                Expanded(
                  child: _StatusItem(
                    label: 'MOT',
                    status: motStatus ?? 'Unknown',
                    date: motExpiry,
                    isValid: motStatus?.toLowerCase() == 'valid',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatusItem(
                    label: 'Road Tax',
                    status: taxStatus ?? 'Unknown',
                    date: taxDueDate,
                    isValid: taxStatus?.toLowerCase() == 'taxed',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String status;
  final String? date;
  final bool isValid;

  const _StatusItem({
    required this.label,
    required this.status,
    this.date,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isValid ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.warning,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  status,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 2),
            Text(
              'Expires: $date',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Text input formatter to convert to uppercase
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
