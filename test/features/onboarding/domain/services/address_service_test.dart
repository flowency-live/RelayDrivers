import 'package:flutter_test/flutter_test.dart';
import 'package:relay_drivers/features/onboarding/domain/services/address_service.dart';
import 'package:relay_drivers/features/onboarding/domain/models/uk_address.dart';

/// Tests for AddressService
///
/// The AddressService is a pure domain service that parses address data
/// from the ePostcode API. It has no external dependencies.
///
/// ePostcode API response format for autocomplete:
/// {
///   "result": [
///     {
///       "suggestion": "1 High Street, Bournemouth, BH1 1AA",
///       "id": "abc123"
///     },
///     ...
///   ]
/// }
///
/// ePostcode API response format for address lookup by ID:
/// {
///   "result": {
///     "line_1": "1 High Street",
///     "line_2": "",
///     "line_3": "",
///     "post_town": "BOURNEMOUTH",
///     "county": "Dorset",
///     "postcode": "BH1 1AA"
///   }
/// }
void main() {
  late AddressService service;

  setUp(() {
    service = AddressService();
  });

  group('parseAutocompleteSuggestions()', () {
    test('should parse valid autocomplete response', () {
      final response = {
        'result': [
          {'suggestion': '1 High Street, Bournemouth, BH1 1AA', 'id': 'abc123'},
          {'suggestion': '10 High Street, Bournemouth, BH1 1AB', 'id': 'def456'},
          {'suggestion': '11 High Street, Bournemouth, BH1 1AC', 'id': 'ghi789'},
        ],
      };

      final suggestions = service.parseAutocompleteSuggestions(response);

      expect(suggestions.length, equals(3));
      expect(suggestions[0].displayText, equals('1 High Street, Bournemouth, BH1 1AA'));
      expect(suggestions[0].id, equals('abc123'));
      expect(suggestions[1].displayText, equals('10 High Street, Bournemouth, BH1 1AB'));
      expect(suggestions[1].id, equals('def456'));
    });

    test('should return empty list for empty result', () {
      final response = {'result': <Map<String, dynamic>>[]};

      final suggestions = service.parseAutocompleteSuggestions(response);

      expect(suggestions, isEmpty);
    });

    test('should return empty list for null result', () {
      final response = <String, dynamic>{};

      final suggestions = service.parseAutocompleteSuggestions(response);

      expect(suggestions, isEmpty);
    });

    test('should handle malformed suggestions gracefully', () {
      final response = {
        'result': [
          {'suggestion': '1 High Street, Bournemouth, BH1 1AA', 'id': 'abc123'},
          {'suggestion': null, 'id': 'bad1'}, // Missing suggestion
          {'suggestion': '11 High Street, Bournemouth, BH1 1AC'}, // Missing id
        ],
      };

      final suggestions = service.parseAutocompleteSuggestions(response);

      // Should only include valid entries
      expect(suggestions.length, equals(1));
      expect(suggestions[0].id, equals('abc123'));
    });
  });

  group('parseAddressById()', () {
    test('should parse full address response', () {
      final response = {
        'result': {
          'line_1': '1 High Street',
          'line_2': 'Flat 2',
          'line_3': '',
          'post_town': 'BOURNEMOUTH',
          'county': 'Dorset',
          'postcode': 'BH1 1AA',
        },
      };

      final address = service.parseAddressById(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('1 High Street'));
      expect(address.line2, equals('Flat 2'));
      expect(address.city, equals('Bournemouth')); // Normalized from UPPERCASE
      expect(address.county, equals('Dorset'));
      expect(address.postcode, equals('BH1 1AA'));
    });

    test('should parse address without line2', () {
      final response = {
        'result': {
          'line_1': '10 Main Road',
          'post_town': 'LONDON',
          'postcode': 'SW1A 1AA',
        },
      };

      final address = service.parseAddressById(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('10 Main Road'));
      expect(address.line2, isNull);
      expect(address.city, equals('London'));
      expect(address.postcode, equals('SW1A 1AA'));
    });

    test('should combine line_2 and line_3 if both present', () {
      final response = {
        'result': {
          'line_1': '1 High Street',
          'line_2': 'Flat 2',
          'line_3': 'Building A',
          'post_town': 'BOURNEMOUTH',
          'postcode': 'BH1 1AA',
        },
      };

      final address = service.parseAddressById(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('1 High Street'));
      expect(address.line2, equals('Flat 2, Building A'));
    });

    test('should return null for empty result', () {
      final response = <String, dynamic>{};

      final address = service.parseAddressById(response);

      expect(address, isNull);
    });

    test('should return null for missing required fields', () {
      final response = {
        'result': {
          'line_1': '1 High Street',
          // Missing post_town and postcode
        },
      };

      final address = service.parseAddressById(response);

      expect(address, isNull);
    });

    test('should handle empty line_2 string', () {
      final response = {
        'result': {
          'line_1': '1 High Street',
          'line_2': '',
          'post_town': 'BOURNEMOUTH',
          'postcode': 'BH1 1AA',
        },
      };

      final address = service.parseAddressById(response);

      expect(address, isNotNull);
      expect(address!.line2, isNull); // Empty string converted to null
    });
  });

  group('buildAutocompleteUrl()', () {
    test('should build correct URL with query', () {
      const apiKey = 'test_key_123';
      const query = '1 high street';

      final url = service.buildAutocompleteUrl(query, apiKey);

      expect(url, contains('api_key=test_key_123'));
      expect(url, contains('query=1%20high%20street')); // URL encoded
    });

    test('should handle special characters in query', () {
      const apiKey = 'test_key_123';
      const query = "Flat 1/2, O'Brien House";

      final url = service.buildAutocompleteUrl(query, apiKey);

      // Spaces, commas, and slashes should be URL encoded
      expect(url, contains('%20')); // Space encoded
      expect(url, contains('%2C')); // Comma encoded
      expect(url, contains('%2F')); // Slash encoded
    });
  });

  group('buildAddressLookupUrl()', () {
    test('should build correct URL with address ID', () {
      const apiKey = 'test_key_123';
      const addressId = 'paf_12345678';

      final url = service.buildAddressLookupUrl(addressId, apiKey);

      expect(url, contains('api_key=test_key_123'));
      expect(url, contains(addressId));
    });
  });

  group('isValidQuery()', () {
    test('should return true for queries >= 3 chars', () {
      expect(service.isValidQuery('abc'), isTrue);
      expect(service.isValidQuery('1 high street'), isTrue);
      expect(service.isValidQuery('BH1'), isTrue);
    });

    test('should return false for queries < 3 chars', () {
      expect(service.isValidQuery('ab'), isFalse);
      expect(service.isValidQuery('a'), isFalse);
      expect(service.isValidQuery(''), isFalse);
    });

    test('should trim whitespace before checking length', () {
      expect(service.isValidQuery('  ab  '), isFalse); // Only 2 chars after trim
      expect(service.isValidQuery('  abc  '), isTrue);
    });
  });
}

/// Test double for AddressSuggestion
/// The actual implementation is in address_service.dart
class AddressSuggestionTest {
  final String displayText;
  final String id;

  AddressSuggestionTest({required this.displayText, required this.id});
}
