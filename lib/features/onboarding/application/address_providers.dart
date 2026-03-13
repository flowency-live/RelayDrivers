import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../domain/models/uk_address.dart';
import '../domain/services/address_service.dart';
import '../infrastructure/address_repository.dart';
import '../../../config/api_keys.dart';

/// Provider for the AddressService (domain layer - no dependencies)
final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

/// Provider for the AddressRepository (infrastructure layer)
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 5);
  dio.options.receiveTimeout = const Duration(seconds: 5);

  return AddressRepository(
    dio: dio,
    apiKey: ApiKeys.ePostcode,
    addressService: ref.watch(addressServiceProvider),
  );
});

/// State for address autocomplete
class AddressAutocompleteState {
  final List<AddressSuggestion> suggestions;
  final bool isLoading;
  final String? error;

  const AddressAutocompleteState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  AddressAutocompleteState copyWith({
    List<AddressSuggestion>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return AddressAutocompleteState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for address autocomplete state and actions
final addressAutocompleteProvider = StateNotifierProvider<
    AddressAutocompleteNotifier, AddressAutocompleteState>((ref) {
  return AddressAutocompleteNotifier(ref);
});

class AddressAutocompleteNotifier extends StateNotifier<AddressAutocompleteState> {
  final Ref _ref;

  AddressAutocompleteNotifier(this._ref)
      : super(const AddressAutocompleteState());

  /// Fetch autocomplete suggestions for a query
  Future<void> search(String query) async {
    if (query.trim().length < 3) {
      state = state.copyWith(suggestions: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(addressRepositoryProvider);
      final suggestions = await repository.autocomplete(query);
      state = state.copyWith(suggestions: suggestions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        suggestions: [],
        isLoading: false,
        error: 'Failed to fetch address suggestions',
      );
    }
  }

  /// Clear suggestions
  void clear() {
    state = const AddressAutocompleteState();
  }

  /// Get full address details for a selected suggestion
  Future<UkAddress?> resolveAddress(AddressSuggestion suggestion) async {
    try {
      final repository = _ref.read(addressRepositoryProvider);
      return await repository.getAddressById(suggestion.id);
    } catch (e) {
      return null;
    }
  }
}
