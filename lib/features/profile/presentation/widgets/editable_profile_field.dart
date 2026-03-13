import 'package:flutter/material.dart';

/// A profile field that supports inline tap-to-edit functionality.
///
/// Displays a label and value in view mode. When tapped (if editable),
/// transforms into an inline text field with save/cancel buttons.
class EditableProfileField extends StatefulWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Future<bool> Function(String?) onSave;
  final bool editable;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final TextInputType keyboardType;
  final bool masked;

  const EditableProfileField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onSave,
    this.editable = true,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
    this.masked = false,
  });

  @override
  State<EditableProfileField> createState() => _EditableProfileFieldState();
}

class _EditableProfileFieldState extends State<EditableProfileField> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(EditableProfileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (!widget.editable) return;
    setState(() {
      _isEditing = true;
      _controller.text = widget.value ?? '';
      _errorText = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.value ?? '';
      _errorText = null;
    });
  }

  Future<void> _save() async {
    // Validate first
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (error != null) {
        setState(() {
          _errorText = error;
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final value = _controller.text.trim();
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

  String _getDisplayValue() {
    if (widget.value == null || widget.value!.isEmpty) {
      return 'Not set';
    }
    if (widget.masked && widget.value!.length > 4) {
      return '****${widget.value!.substring(widget.value!.length - 4)}';
    }
    return widget.value!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _controller,
                        textCapitalization: widget.textCapitalization,
                        keyboardType: widget.keyboardType,
                        autofocus: true,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: const OutlineInputBorder(),
                          errorText: _errorText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isSaving)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  IconButton(
                    icon: Icon(
                      Icons.check,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: _save,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: _cancelEditing,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.editable ? _startEditing : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    _getDisplayValue(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.value == null
                          ? theme.textTheme.bodySmall?.color
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.editable)
              Icon(
                Icons.edit,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}
