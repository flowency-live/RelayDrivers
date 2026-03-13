import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/address_providers.dart';
import '../../domain/models/uk_address.dart';
import '../../domain/services/address_service.dart';

/// A text field with address autocomplete suggestions
///
/// As the user types, suggestions appear in a dropdown.
/// When a suggestion is selected, the full address is resolved
/// and passed to the onAddressSelected callback.
class AddressAutocompleteField extends ConsumerStatefulWidget {
  /// Called when a complete address is selected and resolved
  final void Function(UkAddress address) onAddressSelected;

  /// Initial value for the text field
  final String? initialValue;

  /// Hint text for the field
  final String hint;

  /// Label text for the field
  final String label;

  /// Whether the field is enabled
  final bool enabled;

  const AddressAutocompleteField({
    super.key,
    required this.onAddressSelected,
    this.initialValue,
    this.hint = 'Start typing your address...',
    this.label = 'Address',
    this.enabled = true,
  });

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay removal to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(addressAutocompleteProvider.notifier).search(value);
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  Widget _buildSuggestionsList() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(addressAutocompleteProvider);

        if (state.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state.suggestions.isEmpty) {
          if (_controller.text.trim().length >= 3) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No addresses found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: state.suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final suggestion = state.suggestions[index];
              return ListTile(
                dense: true,
                title: Text(
                  suggestion.displayText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () => _onSuggestionSelected(suggestion),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onSuggestionSelected(AddressSuggestion suggestion) async {
    setState(() {
      _isResolving = true;
    });

    _removeOverlay();
    ref.read(addressAutocompleteProvider.notifier).clear();

    // Resolve the full address
    final address = await ref
        .read(addressAutocompleteProvider.notifier)
        .resolveAddress(suggestion);

    setState(() {
      _isResolving = false;
    });

    if (address != null) {
      _controller.text = address.formatted;
      widget.onAddressSelected(address);
    } else {
      // If resolution fails, use the suggestion text as fallback
      _controller.text = suggestion.displayText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resolve address details. Please enter manually.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes to show/hide overlay
    ref.listen<AddressAutocompleteState>(addressAutocompleteProvider,
        (previous, next) {
      if (next.suggestions.isNotEmpty || next.isLoading) {
        if (_focusNode.hasFocus) {
          _showOverlay();
        }
      } else {
        _removeOverlay();
      }
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled && !_isResolving,
        onChanged: _onTextChanged,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: _isResolving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        ref.read(addressAutocompleteProvider.notifier).clear();
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
