import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../../domain/services/dvla_licence_service.dart';
import '../widgets/wizard_scaffold.dart';
import '../../../../core/services/postcode_service.dart';

/// Phase 1, Step 1: Personal Details
/// Collects name, DOB, and address with postcode autocomplete
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
  List<PostcodeAddress>? _addressSuggestions;
  bool _isLoadingAddresses = false;
  bool _showAddressSelector = false;

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

  Future<void> _lookupPostcode() async {
    final postcode = _postcodeController.text.trim();
    if (postcode.isEmpty) return;

    setState(() {
      _isLoadingAddresses = true;
      _addressSuggestions = null;
    });

    try {
      final addresses = await PostcodeService.lookupPostcode(postcode);
      setState(() {
        _addressSuggestions = addresses;
        _showAddressSelector = addresses.isNotEmpty;
        _isLoadingAddresses = false;
      });

      if (addresses.isEmpty) {
        _showNoAddressesDialog();
      }
    } catch (e) {
      setState(() {
        _isLoadingAddresses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not lookup postcode: $e')),
        );
      }
    }
  }

  void _showNoAddressesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Postcode Not Found'),
        content: const Text(
          'We couldn\'t find addresses for this postcode. '
          'Please check the postcode or enter your address manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectAddress(PostcodeAddress address) {
    setState(() {
      _addressController.text = address.line1;
      _cityController.text = address.city;
      _postcodeController.text = address.postcode;
      _showAddressSelector = false;
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
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Required for DVLA licence number verification',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const WizardInfoBanner(
              message: 'Enter your postcode and we\'ll find your address',
            ),
            const SizedBox(height: 16),

            // Postcode with lookup button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: WizardTextField(
                    controller: _postcodeController,
                    label: 'Postcode',
                    hint: 'BH1 1AA',
                    prefixIcon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoadingAddresses ? null : _lookupPostcode,
                    child: _isLoadingAddresses
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Find'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address selector (shown after postcode lookup)
            if (_showAddressSelector && _addressSuggestions != null) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _addressSuggestions!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final address = _addressSuggestions![index];
                    return ListTile(
                      dense: true,
                      title: Text(address.line1),
                      subtitle: Text(address.city),
                      onTap: () => _selectAddress(address),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manual address fields
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
