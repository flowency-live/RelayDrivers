import 'package:flutter_test/flutter_test.dart';
import 'package:relay_drivers/features/onboarding/domain/services/address_service.dart';

/// Tests for AddressService
///
/// The AddressService is a pure domain service that parses address data
/// from the ePostcode API. It has no external dependencies.
///
/// ePostcode API response format for Search (autocomplete):
/// {
///   "items": [
///     {
///       "key": "prem_12345",
///       "text": "1 High Street, Bournemouth, BH1 1AA",
///       "type": "Premise"
///     },
///     ...
///   ]
/// }
///
/// ePostcode API response format for GetPremise (full address):
/// {
///   "building": "1",
///   "street": "High Street",
///   "city": "Bournemouth",
///   "postcode": "BH1 1AA",
///   "latitude": 50.7192,
///   "longitude": -1.8808
/// }
void main() {
  late AddressService service;

  setUp(() {
    service = AddressService();
  });

  group('parseAutocompleteSuggestions()', () {
    test('should parse valid ePostcode search response', () {
      final response = {
        'items': [
          {'key': 'prem_123', 'text': '1 High Street, Bournemouth, BH1 1AA', 'type': 'Premise'},
          {'key': 'prem_456', 'text': '10 High Street, Bournemouth, BH1 1AB', 'type': 'Premise'},
          {'key': 'grp_789', 'text': 'High Street, Bournemouth', 'type': 'Group'},
        ],
      };

      final suggestions = service.parseAutocompleteSuggestions(response);

      expect(suggestions.length, equals(3));
      expect(suggestions[0].displayText, equals('1 High Street, Bournemouth, BH1 1AA'));
      expect(suggestions[0].id, equals('prem_123'));
      expect(suggestions[0].type, equals('Premise'));
      expect(suggestions[2].type, equals('Group'));
    });

    test('should return empty list for empty items', () {
      final response = {'items': <Map<String, dynamic>>[]};

      final suggestions = service.parseAutocompleteSuggestions(response);

      expect(suggestions, isEmpty);
    });

    test('should return empty list for null items', () {
      final response = <String, dynamic>{};

      final suggestions = service.parseAutocompleteSuggestions(response);

      expect(suggestions, isEmpty);
    });

    test('should handle malformed items gracefully', () {
      final response = {
        'items': [
          {'key': 'prem_123', 'text': '1 High Street, Bournemouth, BH1 1AA', 'type': 'Premise'},
          {'key': 'bad1', 'text': null, 'type': 'Premise'}, // Missing text
          {'text': '11 High Street, Bournemouth', 'type': 'Premise'}, // Missing key
        ],
      };

      final suggestions = service.parseAutocompleteSuggestions(response);

      // Should only include valid entries
      expect(suggestions.length, equals(1));
      expect(suggestions[0].id, equals('prem_123'));
    });

    test('should filter by Premise type only', () {
      final response = {
        'items': [
          {'key': 'prem_123', 'text': '1 High Street, Bournemouth, BH1 1AA', 'type': 'Premise'},
          {'key': 'grp_456', 'text': 'High Street, Bournemouth', 'type': 'Group'},
          {'key': 'prem_789', 'text': '2 High Street, Bournemouth, BH1 1AC', 'type': 'Premise'},
        ],
      };

      final premiseOnly = service.parseAutocompleteSuggestions(response, premiseOnly: true);

      expect(premiseOnly.length, equals(2));
      expect(premiseOnly.every((s) => s.type == 'Premise'), isTrue);
    });
  });

  group('parseAddressFromPremise()', () {
    test('should parse full premise response', () {
      final response = {
        'building': '1',
        'street': 'High Street',
        'city': 'Bournemouth',
        'postcode': 'BH1 1AA',
        'county': 'Dorset',
        'latitude': 50.7192,
        'longitude': -1.8808,
      };

      final address = service.parseAddressFromPremise(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('1 High Street'));
      expect(address.city, equals('Bournemouth'));
      expect(address.county, equals('Dorset'));
      expect(address.postcode, equals('BH1 1AA'));
    });

    test('should handle building with name instead of number', () {
      final response = {
        'building': 'Rose Cottage',
        'street': 'High Street',
        'city': 'Bournemouth',
        'postcode': 'BH1 1AA',
      };

      final address = service.parseAddressFromPremise(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('Rose Cottage, High Street'));
    });

    test('should handle missing building', () {
      final response = {
        'street': 'High Street',
        'city': 'Bournemouth',
        'postcode': 'BH1 1AA',
      };

      final address = service.parseAddressFromPremise(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('High Street'));
    });

    test('should handle flat/unit in building', () {
      final response = {
        'building': 'Flat 2, Rose House',
        'street': 'High Street',
        'city': 'Bournemouth',
        'postcode': 'BH1 1AA',
      };

      final address = service.parseAddressFromPremise(response);

      expect(address, isNotNull);
      expect(address!.line1, equals('Flat 2, Rose House'));
      expect(address.line2, equals('High Street'));
    });

    test('should return null for missing required fields', () {
      final response = {
        'building': '1',
        'street': 'High Street',
        // Missing city and postcode
      };

      final address = service.parseAddressFromPremise(response);

      expect(address, isNull);
    });

    test('should return null for empty response', () {
      final response = <String, dynamic>{};

      final address = service.parseAddressFromPremise(response);

      expect(address, isNull);
    });
  });

  group('buildSearchUrl()', () {
    test('should build correct ePostcode search URL', () {
      const apiKey = 'test_key_123';
      const query = '1 high street';

      final url = service.buildSearchUrl(query, apiKey);

      expect(url, contains('wsp.epostcode.com'));
      expect(url, contains('/Search'));
      expect(url, contains('key=test_key_123'));
      expect(url, contains('phrase=1%20high%20street')); // URL encoded
      expect(url, contains('opensearch=true'));
    });

    test('should handle special characters in query', () {
      const apiKey = 'test_key_123';
      const query = "Flat 1/2, O'Brien House";

      final url = service.buildSearchUrl(query, apiKey);

      // Spaces, commas, and slashes should be URL encoded
      expect(url, contains('%20')); // Space encoded
      expect(url, contains('%2C')); // Comma encoded
      expect(url, contains('%2F')); // Slash encoded
    });
  });

  group('buildGetPremiseUrl()', () {
    test('should build correct ePostcode GetPremise URL', () {
      const apiKey = 'test_key_123';
      const premiseId = 'prem_12345678';

      final url = service.buildGetPremiseUrl(premiseId, apiKey);

      expect(url, contains('wsp.epostcode.com'));
      expect(url, contains('/GetPremise'));
      expect(url, contains('key=test_key_123'));
      expect(url, contains('id=prem_12345678'));
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
