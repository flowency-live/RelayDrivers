import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/relay_colors.dart';

/// UK Driving Licence Number format (16 characters):
/// 1-5:   First 5 letters of surname (padded with 9 if shorter)
/// 6:     Decade digit of birth year
/// 7-8:   Month of birth (+50 for females, but we don't capture gender)
/// 9-10:  Day of birth
/// 11:    Last digit of birth year
/// 12-13: First two initials (9 if no middle name)
/// 14:    Arbitrary digit (usually 9)
/// 15-16: Check digits (letters or numbers)
///
/// Example: MORGA657054SM9IJ
class DvlaLicenceInput extends StatefulWidget {
  final String? initialValue;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth; // Format: YYYY-MM-DD or DD/MM/YYYY
  final Future<bool> Function(String?) onSave;
  final bool enabled;

  const DvlaLicenceInput({
    super.key,
    this.initialValue,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    required this.onSave,
    this.enabled = true,
  });

  @override
  State<DvlaLicenceInput> createState() => _DvlaLicenceInputState();
}

class _DvlaLicenceInputState extends State<DvlaLicenceInput> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorText;
  String? _suggestionText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _generateSuggestion();
  }

  @override
  void didUpdateWidget(DvlaLicenceInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !_isEditing) {
      _controller.text = widget.initialValue ?? '';
    }
    if (oldWidget.firstName != widget.firstName ||
        oldWidget.lastName != widget.lastName ||
        oldWidget.dateOfBirth != widget.dateOfBirth) {
      _generateSuggestion();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateSuggestion() {
    final suggestion = _buildSuggestion();
    setState(() {
      _suggestionText = suggestion;
    });
  }

  String _buildSuggestion() {
    final parts = <String>[];

    // Chars 1-5: First 5 of surname, padded with 9s
    if (widget.lastName != null && widget.lastName!.isNotEmpty) {
      final surname = widget.lastName!
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z]'), '');
      if (surname.isNotEmpty) {
        parts.add(surname.padRight(5, '9').substring(0, 5));
      } else {
        parts.add('?????');
      }
    } else {
      parts.add('?????');
    }

    // Parse date of birth
    DateTime? dob;
    if (widget.dateOfBirth != null && widget.dateOfBirth!.isNotEmpty) {
      // Try YYYY-MM-DD format first
      dob = DateTime.tryParse(widget.dateOfBirth!);
      if (dob == null) {
        // Try DD/MM/YYYY format
        final parts = widget.dateOfBirth!.split('/');
        if (parts.length == 3) {
          dob = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }
    }

    if (dob != null) {
      // Char 6: Decade digit
      final decade = (dob.year ~/ 10) % 10;
      parts.add(decade.toString());

      // Chars 7-8: Month (we show ?? because we don't know gender)
      // Male: 01-12, Female: 51-62
      parts.add('??');

      // Chars 9-10: Day of birth
      parts.add(dob.day.toString().padLeft(2, '0'));

      // Char 11: Last digit of year
      parts.add((dob.year % 10).toString());
    } else {
      parts.add('?'); // decade
      parts.add('??'); // month
      parts.add('??'); // day
      parts.add('?'); // year
    }

    // Char 12: First initial
    if (widget.firstName != null && widget.firstName!.isNotEmpty) {
      final initial = widget.firstName!
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z]'), '');
      if (initial.isNotEmpty) {
        parts.add(initial[0]);
      } else {
        parts.add('?');
      }
    } else {
      parts.add('?');
    }

    // Chars 13-16: Middle initial + arbitrary + check digits (user must enter)
    parts.add('????');

    return parts.join('');
  }

  String? _validateLicence(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final upper = value.toUpperCase().replaceAll(' ', '');

    if (upper.length != 16) {
      return 'Must be exactly 16 characters';
    }

    // Check format: 5 letters, then alphanumeric
    final surnameChars = upper.substring(0, 5);
    if (!RegExp(r'^[A-Z9]{5}$').hasMatch(surnameChars)) {
      return 'First 5 characters must be letters or 9';
    }

    // Validate against known details if available
    if (widget.lastName != null && widget.lastName!.isNotEmpty) {
      final expectedSurname = widget.lastName!
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z]'), '')
          .padRight(5, '9')
          .substring(0, 5);
      if (surnameChars != expectedSurname) {
        return 'First 5 chars should be: $expectedSurname';
      }
    }

    // Check digit at position 6 (decade)
    if (!RegExp(r'^[0-9]$').hasMatch(upper[5])) {
      return 'Character 6 must be a digit (decade)';
    }

    // Check month at positions 7-8
    final month = int.tryParse(upper.substring(6, 8));
    if (month == null ||
        !((month >= 1 && month <= 12) || (month >= 51 && month <= 62))) {
      return 'Characters 7-8 must be valid month (01-12 or 51-62)';
    }

    // Check day at positions 9-10
    final day = int.tryParse(upper.substring(8, 10));
    if (day == null || day < 1 || day > 31) {
      return 'Characters 9-10 must be valid day (01-31)';
    }

    // Validate DOB if available
    if (widget.dateOfBirth != null && widget.dateOfBirth!.isNotEmpty) {
      DateTime? dob = DateTime.tryParse(widget.dateOfBirth!);
      if (dob == null) {
        final parts = widget.dateOfBirth!.split('/');
        if (parts.length == 3) {
          dob = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }

      if (dob != null) {
        final expectedDecade = (dob.year ~/ 10) % 10;
        final licenceDecade = int.tryParse(upper[5]);
        if (licenceDecade != expectedDecade) {
          return 'Decade digit should be $expectedDecade';
        }

        final expectedDay = dob.day.toString().padLeft(2, '0');
        final licenceDay = upper.substring(8, 10);
        if (licenceDay != expectedDay) {
          return 'Day should be $expectedDay';
        }

        final expectedYear = dob.year % 10;
        final licenceYear = int.tryParse(upper[10]);
        if (licenceYear != expectedYear) {
          return 'Year digit should be $expectedYear';
        }

        // Check month (allowing for male/female variants)
        final expectedMonthMale = dob.month.toString().padLeft(2, '0');
        final expectedMonthFemale =
            (dob.month + 50).toString().padLeft(2, '0');
        final licenceMonth = upper.substring(6, 8);
        if (licenceMonth != expectedMonthMale &&
            licenceMonth != expectedMonthFemale) {
          return 'Month should be $expectedMonthMale or $expectedMonthFemale';
        }
      }
    }

    return null;
  }

  void _startEditing() {
    if (!widget.enabled) return;
    setState(() {
      _isEditing = true;
      _errorText = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.initialValue ?? '';
      _errorText = null;
    });
  }

  Future<void> _save() async {
    final error = _validateLicence(_controller.text);
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final value = _controller.text.trim().toUpperCase().replaceAll(' ', '');
      final success = await widget.onSave(value.isEmpty ? null : value);

      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
        } else {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = 'Failed to save';
        });
      }
    }
  }

  void _applyTemplate() {
    if (_suggestionText == null) return;

    // Replace ?? with empty for user to fill in
    final template = _suggestionText!.replaceAll('?', '');
    _controller.text = template;
    _controller.selection = TextSelection.collapsed(offset: template.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isEditing) {
      return _buildEditMode(theme, isDark);
    }

    return _buildViewMode(theme, isDark);
  }

  Widget _buildViewMode(ThemeData theme, bool isDark) {
    final hasValue =
        widget.initialValue != null && widget.initialValue!.isNotEmpty;

    return GestureDetector(
      onTap: widget.enabled ? _startEditing : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color:
                isDark ? RelayColors.darkBorderSubtle : RelayColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 20,
              color: isDark ? RelayColors.darkTextMuted : RelayColors.lightTextMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Licence Number',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? RelayColors.darkTextMuted
                          : RelayColors.lightTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? _formatForDisplay(widget.initialValue!) : 'Not set',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hasValue
                          ? (isDark
                              ? RelayColors.darkTextPrimary
                              : RelayColors.lightTextPrimary)
                          : (isDark
                              ? RelayColors.darkTextMuted
                              : RelayColors.lightTextMuted),
                      letterSpacing: hasValue ? 1.5 : 0,
                      fontFamily: hasValue ? 'monospace' : null,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.enabled)
              Icon(
                Icons.edit,
                size: 16,
                color: isDark ? RelayColors.darkTextMuted : RelayColors.lightTextMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: RelayColors.primary.withAlpha(100),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card_outlined,
                size: 20,
                color: RelayColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Licence Number',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: RelayColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                IconButton(
                  icon: Icon(Icons.check, color: RelayColors.success),
                  onPressed: _save,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: RelayColors.danger),
                  onPressed: _cancelEditing,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Input field
          TextField(
            controller: _controller,
            enabled: !_isSaving,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: theme.textTheme.titleMedium?.copyWith(
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(16),
              UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: const OutlineInputBorder(),
              hintText: 'XXXXX0XX000X0XXX',
              hintStyle: TextStyle(
                letterSpacing: 2,
                color: isDark
                    ? RelayColors.darkTextMuted
                    : RelayColors.lightTextMuted,
              ),
              errorText: _errorText,
              counterText: '${_controller.text.length}/16',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Suggestion/Template
          if (_suggestionText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RelayColors.infoBackground,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: RelayColors.info.withAlpha(50),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: RelayColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Based on your details:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: RelayColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _applyTemplate,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Use template',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: RelayColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _suggestionText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      color: isDark
                          ? RelayColors.darkTextPrimary
                          : RelayColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '? = You need to fill in (month depends on gender)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? RelayColors.darkTextMuted
                          : RelayColors.lightTextMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Format guide
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? RelayColors.darkSurface3
                  : RelayColors.lightBorderSubtle.withAlpha(50),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UK Licence Format:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFormatRow('1-5', 'Surname (first 5 letters, 9 if shorter)',
                    isDark),
                _buildFormatRow('6', 'Decade of birth year', isDark),
                _buildFormatRow(
                    '7-8', 'Birth month (01-12 male, 51-62 female)', isDark),
                _buildFormatRow('9-10', 'Day of birth', isDark),
                _buildFormatRow('11', 'Last digit of birth year', isDark),
                _buildFormatRow('12-13', 'Initials (9 if no middle name)', isDark),
                _buildFormatRow('14-16', 'Arbitrary digit + check digits', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatRow(String position, String description, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              position,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: RelayColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? RelayColors.darkTextSecondary
                    : RelayColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatForDisplay(String value) {
    // Format as: XXXXX X XX XX X XXXX for readability
    if (value.length != 16) return value;
    return '${value.substring(0, 5)} ${value.substring(5, 6)} ${value.substring(6, 8)} ${value.substring(8, 10)} ${value.substring(10, 11)} ${value.substring(11)}';
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
