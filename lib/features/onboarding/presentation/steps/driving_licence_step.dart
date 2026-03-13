import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../application/onboarding_wizard_provider.dart';
import '../../domain/services/dvla_licence_service.dart';
import '../widgets/wizard_scaffold.dart';

/// Phase 1, Step 2: UK Driving Licence
/// Collects DVLA licence number and check code
///
/// Smart Entry: Auto-generates 13 of 16 chars from personal details,
/// user only enters 3 security characters.
class DrivingLicenceStep extends ConsumerStatefulWidget {
  const DrivingLicenceStep({super.key});

  @override
  ConsumerState<DrivingLicenceStep> createState() => _DrivingLicenceStepState();
}

class _DrivingLicenceStepState extends ConsumerState<DrivingLicenceStep> {
  final _formKey = GlobalKey<FormState>();
  final _securityCharsController = TextEditingController();
  final _fullLicenceController = TextEditingController();
  final _checkCodeController = TextEditingController();
  final _expiryController = TextEditingController();

  final _dvlaService = DvlaLicenceService();
  bool _enterManually = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = ref.read(onboardingWizardProvider).data;
    _checkCodeController.text = data.dvlaCheckCode ?? '';
    _expiryController.text = data.dvlaLicenceExpiry ?? '';

    // If licence already exists, check if it matches the prefix
    if (data.dvlaLicenceNumber != null && data.dvlaLicenceNumber!.length == 16) {
      final expectedPrefix = _generatedPrefix;
      if (expectedPrefix != null && data.dvlaLicenceNumber!.startsWith(expectedPrefix)) {
        // Extract the security chars from existing licence
        _securityCharsController.text = data.dvlaLicenceNumber!.substring(13);
      } else {
        // Different prefix, switch to manual entry
        _enterManually = true;
        _fullLicenceController.text = data.dvlaLicenceNumber!;
      }
    }
  }

  @override
  void dispose() {
    _securityCharsController.dispose();
    _fullLicenceController.dispose();
    _checkCodeController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  /// Get the auto-generated 13-char prefix from personal details
  String? get _generatedPrefix {
    final data = ref.read(onboardingWizardProvider).data;

    if (!_dvlaService.canAutoGenerate(
      surname: data.lastName,
      dateOfBirth: data.dateOfBirth,
      firstName: data.firstName,
      gender: data.gender,
    )) {
      return null;
    }

    return _dvlaService.generateLicencePrefix(
      surname: data.lastName!,
      dateOfBirth: data.dateOfBirth!,
      firstName: data.firstName!,
      middleName: data.middleName,
      gender: data.gender!,
    );
  }

  /// Check if we can auto-generate the prefix
  bool get _canAutoGenerate {
    final data = ref.read(onboardingWizardProvider).data;
    return _dvlaService.canAutoGenerate(
      surname: data.lastName,
      dateOfBirth: data.dateOfBirth,
      firstName: data.firstName,
      gender: data.gender,
    );
  }

  /// Get the complete licence number
  String get _completeLicenceNumber {
    if (_enterManually) {
      return _fullLicenceController.text.trim().toUpperCase();
    }

    final prefix = _generatedPrefix;
    if (prefix == null) return '';

    final securityChars = _securityCharsController.text.trim().toUpperCase();
    if (securityChars.length != 3) return '';

    return '$prefix$securityChars';
  }

  Future<void> _openDvlaCheckCode() async {
    final url = Uri.parse('https://www.gov.uk/view-driving-licence');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final tenYearsFromNow = DateTime(now.year + 10, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: tenYearsFromNow,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      helpText: 'Select licence expiry date',
    );

    if (picked != null) {
      setState(() {
        _expiryController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  bool get _isValid {
    final licenceNumber = _completeLicenceNumber;
    final checkCode = _checkCodeController.text.trim();
    return licenceNumber.length == 16 && checkCode.isNotEmpty;
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(onboardingWizardProvider.notifier).saveDrivingLicence(
          licenceNumber: _completeLicenceNumber,
          checkCode: _checkCodeController.text.trim().toUpperCase(),
          expiryDate: _expiryController.text.trim(),
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

  void _goBack() {
    ref.read(onboardingWizardProvider.notifier).previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wizardState = ref.watch(onboardingWizardProvider);
    final canAutoGen = _canAutoGenerate;
    final prefix = _generatedPrefix;

    return WizardScaffold(
      step: WizardStep.drivingLicence,
      canGoNext: _isValid,
      isLoading: wizardState.isSaving,
      onBack: _goBack,
      onNext: _saveAndContinue,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            const WizardInfoBanner(
              message: 'Enter your UK driving licence details',
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 24),

            // Smart entry or manual entry
            if (canAutoGen && !_enterManually) ...[
              // Auto-generated prefix display
              _buildSmartEntrySection(theme, prefix!),
            ] else ...[
              // Manual entry fallback
              _buildManualEntrySection(theme),
            ],

            // Toggle between smart and manual entry
            if (canAutoGen) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _enterManually = !_enterManually),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _enterManually ? Icons.auto_fix_high : Icons.edit,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _enterManually
                            ? 'Use smart entry instead'
                            : 'Enter full licence number manually',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Check code section
            _buildCheckCodeSection(theme),

            const SizedBox(height: 24),

            // Expiry date (optional)
            WizardTextField(
              controller: _expiryController,
              label: 'Licence Expiry Date (Optional)',
              hint: 'DD/MM/YYYY',
              prefixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: _selectExpiryDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartEntrySection(ThemeData theme, String prefix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Based on your details, your licence starts with:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),

        // Prefix + security chars input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              // Auto-generated prefix (read-only)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-generated',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prefix,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Security chars input
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter last 3 chars',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _securityCharsController,
                      maxLength: 3,
                      textCapitalization: TextCapitalization.characters,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'ABC',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length != 3) {
                          return 'Enter 3 characters';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Preview of complete licence
        if (_securityCharsController.text.length == 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Complete: $_completeLicenceNumber',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildManualEntrySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_canAutoGenerate) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withAlpha(50),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete your personal details (including gender) to enable smart licence entry.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        WizardTextField(
          controller: _fullLicenceController,
          label: 'Driving Licence Number',
          hint: 'MORGA657054SM9IJ',
          helper: '16 characters from your photocard licence',
          prefixIcon: Icons.credit_card_outlined,
          textCapitalization: TextCapitalization.characters,
          maxLength: 16,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().length != 16) return 'Must be 16 characters';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Help text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Where to find your licence number',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your 16-character licence number is in section 5 on the front of your photocard driving licence, below your photo.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckCodeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'DVLA Check Code',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _openDvlaCheckCode,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Get code'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(50),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How to get your check code',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Visit gov.uk/view-driving-licence\n'
                '2. Sign in with GOV.UK One Login\n'
                '3. Generate a check code\n'
                '4. Enter the 8-character code below',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        WizardTextField(
          controller: _checkCodeController,
          label: 'Check Code',
          hint: 'ABC123XY',
          prefixIcon: Icons.pin_outlined,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
