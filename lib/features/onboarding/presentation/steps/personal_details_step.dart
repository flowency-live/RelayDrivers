import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../../domain/models/uk_address.dart';
import '../../domain/services/dvla_licence_service.dart';
import '../widgets/wizard_scaffold.dart';
import '../widgets/address_autocomplete_field.dart';
import '../../../../config/api_keys.dart';

/// Phase 1, Step 1: Personal Details
/// Collects name, DOB, and address with type-ahead autocomplete
class PersonalDetailsStep extends ConsumerStatefulWidget {
  const PersonalDetailsStep({super.key});

  @override
  ConsumerState<PersonalDetailsStep> createState() => _PersonalDetailsStepState();
}

class _PersonalDetailsStepState extends ConsumerState<PersonalDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  Gender? _selectedGender;
  bool _useManualAddressEntry = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = ref.read(onboardingWizardProvider).data;
    _firstNameController.text = data.firstName ?? '';
    _lastNameController.text = data.lastName ?? '';
    _middleNameController.text = data.middleName ?? '';
    _selectedGender = data.gender;
    _dobController.text = data.dateOfBirth ?? '';
    _postcodeController.text = data.postcode ?? '';
    _addressController.text = data.address ?? '';
    _cityController.text = data.city ?? '';

    // If address already exists, use manual entry mode
    if (_addressController.text.isNotEmpty) {
      _useManualAddressEntry = true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _dobController.dispose();
    _postcodeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onAddressSelected(UkAddress address) {
    setState(() {
      _addressController.text = address.line1;
      if (address.line2 != null && address.line2!.isNotEmpty) {
        _addressController.text += ', ${address.line2}';
      }
      _cityController.text = address.city;
      _postcodeController.text = address.postcode;
      _useManualAddressEntry = true;
    });
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: hundredYearsAgo,
      lastDate: eighteenYearsAgo,
      helpText: 'Select your date of birth',
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  bool get _isValid {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _selectedGender != null &&
        _dobController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _postcodeController.text.trim().isNotEmpty;
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    // Save to backend
    final success = await ref.read(onboardingWizardProvider.notifier).savePersonalDetails(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleName: _middleNameController.text.trim().isNotEmpty
              ? _middleNameController.text.trim()
              : null,
          gender: _selectedGender!,
          dateOfBirth: _dobController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          postcode: _postcodeController.text.trim().toUpperCase(),
        );

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
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(onboardingWizardProvider);
    final theme = Theme.of(context);

    return WizardScaffold(
      step: WizardStep.personalDetails,
      showBackButton: false,
      canGoNext: _isValid,
      isLoading: wizardState.isSaving,
      onNext: _saveAndContinue,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name row
            Row(
              children: [
                Expanded(
                  child: WizardTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WizardTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle name (optional - for DVLA licence generation)
            WizardTextField(
              controller: _middleNameController,
              label: 'Middle Name (Optional)',
              hint: 'For DVLA licence number generation',
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Gender selection (required for DVLA licence calculation)
            Text(
              'Gender',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Required for DVLA licence number verification',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _GenderOption(
                    gender: Gender.male,
                    selected: _selectedGender == Gender.male,
                    onTap: () => setState(() => _selectedGender = Gender.male),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderOption(
                    gender: Gender.female,
                    selected: _selectedGender == Gender.female,
                    onTap: () => setState(() => _selectedGender = Gender.female),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date of birth
            WizardTextField(
              controller: _dobController,
              label: 'Date of Birth',
              hint: 'DD/MM/YYYY',
              prefixIcon: Icons.cake_outlined,
              readOnly: true,
              onTap: _selectDateOfBirth,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Address section header
            Text(
              'Your Address',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Show autocomplete or manual entry based on state
            if (!_useManualAddressEntry && ApiKeys.isConfigured) ...[
              const WizardInfoBanner(
                message: 'Start typing your address to search',
              ),
              const SizedBox(height: 16),

              // Address autocomplete field
              AddressAutocompleteField(
                label: 'Search for your address',
                hint: 'Start typing your address...',
                onAddressSelected: _onAddressSelected,
              ),
              const SizedBox(height: 12),

              // Manual entry toggle
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useManualAddressEntry = true;
                  });
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Enter address manually'),
              ),
            ] else ...[
              // Manual address entry fields
              if (!ApiKeys.isConfigured) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Address autocomplete is not configured. Enter your address manually.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              WizardTextField(
                controller: _addressController,
                label: 'Address',
                hint: '123 Example Street',
                prefixIcon: Icons.home_outlined,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              WizardTextField(
                controller: _cityController,
                label: 'City',
                prefixIcon: Icons.location_city_outlined,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              WizardTextField(
                controller: _postcodeController,
                label: 'Postcode',
                hint: 'BH1 1AA',
                prefixIcon: Icons.location_on_outlined,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),

              // Option to use autocomplete (if configured)
              if (ApiKeys.isConfigured) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _useManualAddressEntry = false;
                      _addressController.clear();
                      _cityController.clear();
                      _postcodeController.clear();
                    });
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search for address instead'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Gender selection option widget
class _GenderOption extends StatelessWidget {
  final Gender gender;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withAlpha(50),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gender == Gender.male ? Icons.male : Icons.female,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                gender == Gender.male ? 'Male' : 'Female',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
