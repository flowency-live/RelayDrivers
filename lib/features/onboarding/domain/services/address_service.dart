import '../models/uk_address.dart';

/// Represents an autocomplete suggestion from the ePostcode API
class AddressSuggestion {
  final String displayText;
  final String id;

  const AddressSuggestion({
    required this.displayText,
    required this.id,
  });

  @override
  String toString() => displayText;
}

/// Pure domain service for parsing address data from ePostcode API
///
/// This service has NO external dependencies - it only transforms data.
/// The actual HTTP calls are made by the AddressRepository (infrastructure layer).
class AddressService {
  // ePostcode API base URL
  static const String _baseUrl = 'https://api.ideal-postcodes.co.uk/v1';

  /// Parses autocomplete suggestions from ePostcode API response
  ///
  /// Expected response format:
  /// ```json
  /// {
  ///   "result": [
  ///     {"suggestion": "1 High Street, Bournemouth, BH1 1AA", "id": "abc123"},
  ///     ...
  ///   ]
  /// }
  /// ```
  List<AddressSuggestion> parseAutocompleteSuggestions(
    Map<String, dynamic> response,
  ) {
    final result = response['result'];
    if (result == null || result is! List) {
      return [];
    }

    final suggestions = <AddressSuggestion>[];
    for (final item in result) {
      if (item is! Map<String, dynamic>) continue;

      final suggestion = item['suggestion'];
      final id = item['id'];

      // Skip entries with missing required fields
      if (suggestion == null || suggestion is! String) continue;
      if (id == null || id is! String) continue;

      suggestions.add(AddressSuggestion(
        displayText: suggestion,
        id: id,
      ));
    }

    return suggestions;
  }

  /// Parses a full address from ePostcode API address lookup response
  ///
  /// Expected response format:
  /// ```json
  /// {
  ///   "result": {
  ///     "line_1": "1 High Street",
  ///     "line_2": "Flat 2",
  ///     "line_3": "",
  ///     "post_town": "BOURNEMOUTH",
  ///     "county": "Dorset",
  ///     "postcode": "BH1 1AA"
  ///   }
  /// }
  /// ```
  UkAddress? parseAddressById(Map<String, dynamic> response) {
    final result = response['result'];
    if (result == null || result is! Map<String, dynamic>) {
      return null;
    }

    final line1 = result['line_1'];
    final postTown = result['post_town'];
    final postcode = result['postcode'];

    // Required fields must be present
    if (line1 == null || line1 is! String || line1.isEmpty) return null;
    if (postTown == null || postTown is! String || postTown.isEmpty) return null;
    if (postcode == null || postcode is! String || postcode.isEmpty) return null;

    // Combine line_2 and line_3 if both present
    final line2Raw = result['line_2'] as String?;
    final line3Raw = result['line_3'] as String?;
    String? line2;

    if (line2Raw != null && line2Raw.isNotEmpty) {
      if (line3Raw != null && line3Raw.isNotEmpty) {
        line2 = '$line2Raw, $line3Raw';
      } else {
        line2 = line2Raw;
      }
    } else if (line3Raw != null && line3Raw.isNotEmpty) {
      line2 = line3Raw;
    }

    return UkAddress(
      line1: line1,
      line2: line2,
      city: _toTitleCase(postTown),
      county: result['county'] as String?,
      postcode: postcode,
    );
  }

  /// Converts a string to Title Case (first letter of each word capitalized)
  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Builds the URL for autocomplete suggestions
  ///
  /// Uses the Ideal Postcodes autocomplete endpoint
  String buildAutocompleteUrl(String query, String apiKey) {
    final encodedQuery = Uri.encodeComponent(query);
    return '$_baseUrl/autocomplete/addresses?api_key=$apiKey&query=$encodedQuery';
  }

  /// Builds the URL for looking up a full address by ID
  String buildAddressLookupUrl(String addressId, String apiKey) {
    return '$_baseUrl/autocomplete/addresses/$addressId?api_key=$apiKey';
  }

  /// Checks if a query is valid for autocomplete
  ///
  /// Minimum 3 characters required to trigger autocomplete
  bool isValidQuery(String query) {
    return query.trim().length >= 3;
  }
}
