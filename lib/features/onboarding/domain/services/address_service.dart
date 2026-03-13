import '../models/uk_address.dart';

/// Represents an autocomplete suggestion from the ePostcode API
class AddressSuggestion {
  final String displayText;
  final String id;
  final String type; // "Premise" or "Group"

  const AddressSuggestion({
    required this.displayText,
    required this.id,
    required this.type,
  });

  /// Whether this is a specific address (Premise) vs a street/area (Group)
  bool get isPremise => type == 'Premise';

  @override
  String toString() => displayText;
}

/// Pure domain service for parsing address data from ePostcode API
///
/// This service has NO external dependencies - it only transforms data.
/// The actual HTTP calls are made by the AddressRepository (infrastructure layer).
///
/// ePostcode API: https://wsp.epostcode.com/uk/v1/
class AddressService {
  // ePostcode API base URL
  static const String _baseUrl = 'https://wsp.epostcode.com/uk/v1';

  /// Parses autocomplete suggestions from ePostcode Search response
  ///
  /// Expected response format:
  /// ```json
  /// {
  ///   "items": [
  ///     {"key": "prem_123", "text": "1 High Street, Bournemouth, BH1 1AA", "type": "Premise"},
  ///     {"key": "grp_456", "text": "High Street, Bournemouth", "type": "Group"}
  ///   ]
  /// }
  /// ```
  ///
  /// If [premiseOnly] is true, filters to only return Premise items (specific addresses)
  List<AddressSuggestion> parseAutocompleteSuggestions(
    Map<String, dynamic> response, {
    bool premiseOnly = false,
  }) {
    final items = response['items'];
    if (items == null || items is! List) {
      return [];
    }

    final suggestions = <AddressSuggestion>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final key = item['key'];
      final text = item['text'];
      final type = item['type'];

      // Skip entries with missing required fields
      if (key == null || key is! String) continue;
      if (text == null || text is! String) continue;
      if (type == null || type is! String) continue;

      // Filter by type if requested
      if (premiseOnly && type != 'Premise') continue;

      suggestions.add(AddressSuggestion(
        id: key,
        displayText: text,
        type: type,
      ));
    }

    return suggestions;
  }

  /// Parses a full address from ePostcode GetPremise response
  ///
  /// Expected response format:
  /// ```json
  /// {
  ///   "building": "1",
  ///   "street": "High Street",
  ///   "city": "Bournemouth",
  ///   "postcode": "BH1 1AA",
  ///   "county": "Dorset",
  ///   "latitude": 50.7192,
  ///   "longitude": -1.8808
  /// }
  /// ```
  UkAddress? parseAddressFromPremise(Map<String, dynamic> response) {
    final city = response['city'];
    final postcode = response['postcode'];
    final street = response['street'];

    // Required fields must be present
    if (city == null || city is! String || city.isEmpty) return null;
    if (postcode == null || postcode is! String || postcode.isEmpty) return null;

    final building = response['building'] as String?;
    final county = response['county'] as String?;

    // Build line1 and line2 based on building format
    String line1;
    String? line2;

    if (building != null && building.isNotEmpty) {
      // Check if building is a number (simple case) or a name/flat
      final isSimpleNumber = RegExp(r'^\d+[a-zA-Z]?$').hasMatch(building);

      if (isSimpleNumber && street != null && street.isNotEmpty) {
        // Simple number: "1 High Street"
        line1 = '$building $street';
      } else if (building.contains(',') || building.toLowerCase().startsWith('flat')) {
        // Complex building: "Flat 2, Rose House" -> line1, street -> line2
        line1 = building;
        line2 = street;
      } else if (street != null && street.isNotEmpty) {
        // Named building: "Rose Cottage, High Street"
        line1 = '$building, $street';
      } else {
        line1 = building;
      }
    } else if (street != null && street.isNotEmpty) {
      line1 = street;
    } else {
      return null; // No address line available
    }

    return UkAddress(
      line1: line1,
      line2: line2,
      city: city,
      county: county,
      postcode: postcode,
    );
  }

  /// Builds the URL for ePostcode Search (autocomplete)
  ///
  /// Uses opensearch=true for partial matching
  String buildSearchUrl(String query, String apiKey) {
    final encodedQuery = Uri.encodeComponent(query);
    return '$_baseUrl/Search?key=$apiKey&phrase=$encodedQuery&opensearch=true';
  }

  /// Builds the URL for ePostcode GetPremise (full address)
  String buildGetPremiseUrl(String premiseId, String apiKey) {
    return '$_baseUrl/GetPremise?key=$apiKey&id=$premiseId';
  }

  /// Checks if a query is valid for autocomplete
  ///
  /// Minimum 3 characters required to trigger autocomplete
  bool isValidQuery(String query) {
    return query.trim().length >= 3;
  }
}
