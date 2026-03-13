import 'package:dio/dio.dart';
import '../domain/models/uk_address.dart';
import '../domain/services/address_service.dart';

/// Repository for address lookup using ePostcode API
///
/// This is the infrastructure layer - it handles HTTP communication
/// and delegates parsing to the domain service.
///
/// Configuration:
/// - API keys are stored in the app config (gitignored)
/// - Uses ePostcode API: https://wsp.epostcode.com/uk/v1/
///
/// Pricing note:
/// - 2.4-3.8p per lookup
/// - Credits never expire
/// - Smart duplicate detection (no charge for user errors)
class AddressRepository {
  final Dio _dio;
  final AddressService _addressService;
  final String _apiKey;

  AddressRepository({
    required Dio dio,
    required String apiKey,
    AddressService? addressService,
  })  : _dio = dio,
        _apiKey = apiKey,
        _addressService = addressService ?? AddressService();

  /// Fetches autocomplete suggestions for a partial address query
  ///
  /// Returns an empty list if the query is too short (<3 chars)
  /// or if the API call fails.
  ///
  /// If [premiseOnly] is true, only returns specific addresses (Premise type)
  /// and not street/area results (Group type).
  Future<List<AddressSuggestion>> autocomplete(
    String query, {
    bool premiseOnly = false,
  }) async {
    if (!_addressService.isValidQuery(query)) {
      return [];
    }

    try {
      final url = _addressService.buildSearchUrl(query, _apiKey);
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return _addressService.parseAutocompleteSuggestions(
          response.data as Map<String, dynamic>,
          premiseOnly: premiseOnly,
        );
      }
      return [];
    } on DioException catch (e) {
      // Log error but don't throw - graceful degradation
      // ignore: avoid_print
      print('Address autocomplete error: ${e.message}');
      return [];
    }
  }

  /// Fetches the full address details for a given premise ID
  ///
  /// This is the billable call - only called when user selects a suggestion.
  /// Returns null if the lookup fails.
  Future<UkAddress?> getAddressById(String premiseId) async {
    try {
      final url = _addressService.buildGetPremiseUrl(premiseId, _apiKey);
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return _addressService.parseAddressFromPremise(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException catch (e) {
      // Log error but don't throw
      // ignore: avoid_print
      print('Address lookup error: ${e.message}');
      return null;
    }
  }
}
