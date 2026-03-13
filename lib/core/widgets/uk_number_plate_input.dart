import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UK Number Plate styled input field
/// Shows the authentic yellow plate with GB badge
/// 2-7 characters (alphanumeric only, no spaces)
class UKNumberPlateInput extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onLookup;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  const UKNumberPlateInput({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.isLoading = false,
    this.onLookup,
    this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700), // Yellow plate
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? Theme.of(context).colorScheme.error
                  : const Color(0xFF1A365D),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GB Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF003399), // EU blue
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🇬🇧',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'GB',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Input field
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled && !isLoading,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    fontFamily: 'Courier',
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText ?? 'YOUR REG',
                    hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      fontFamily: 'Courier',
                      color: Colors.black.withAlpha(100),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(7),
                    _UpperCaseTextFormatter(),
                  ],
                  onChanged: onChanged,
                  onSubmitted: (_) => onLookup?.call(),
                ),
              ),
            ],
          ),
        ),
        // Error text
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Formats input to uppercase
class _UpperCaseTextFormatter extends TextInputFormatter {
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
