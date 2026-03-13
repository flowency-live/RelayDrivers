import 'package:flutter_test/flutter_test.dart';
import 'package:relay_drivers/features/onboarding/domain/models/uk_address.dart';

/// Tests for UkAddress model
///
/// UkAddress represents a UK postal address with:
/// - line1: Primary address line (required)
/// - line2: Secondary address line (optional)
/// - city: City/town name (required)
/// - county: County (optional)
/// - postcode: UK postcode (required)
void main() {
  group('UkAddress', () {
    test('should create valid address with all fields', () {
      final address = UkAddress(
        line1: '1 High Street',
        line2: 'Flat 2',
        city: 'Bournemouth',
        county: 'Dorset',
        postcode: 'BH1 1AA',
      );

      expect(address.line1, equals('1 High Street'));
      expect(address.line2, equals('Flat 2'));
      expect(address.city, equals('Bournemouth'));
      expect(address.county, equals('Dorset'));
      expect(address.postcode, equals('BH1 1AA'));
    });

    test('should create valid address without optional fields', () {
      final address = UkAddress(
        line1: '10 Main Road',
        city: 'London',
        postcode: 'SW1A 1AA',
      );

      expect(address.line1, equals('10 Main Road'));
      expect(address.line2, isNull);
      expect(address.city, equals('London'));
      expect(address.county, isNull);
      expect(address.postcode, equals('SW1A 1AA'));
    });
  });

  group('UkAddress.formatted', () {
    test('should format address with all fields', () {
      final address = UkAddress(
        line1: '1 High Street',
        line2: 'Flat 2',
        city: 'Bournemouth',
        county: 'Dorset',
        postcode: 'BH1 1AA',
      );

      expect(
        address.formatted,
        equals('1 High Street, Flat 2, Bournemouth, Dorset, BH1 1AA'),
      );
    });

    test('should format address without optional fields', () {
      final address = UkAddress(
        line1: '10 Main Road',
        city: 'London',
        postcode: 'SW1A 1AA',
      );

      expect(address.formatted, equals('10 Main Road, London, SW1A 1AA'));
    });

    test('should skip empty line2', () {
      final address = UkAddress(
        line1: '1 High Street',
        line2: '',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );

      expect(address.formatted, equals('1 High Street, Bournemouth, BH1 1AA'));
    });

    test('should skip empty county', () {
      final address = UkAddress(
        line1: '1 High Street',
        city: 'Bournemouth',
        county: '',
        postcode: 'BH1 1AA',
      );

      expect(address.formatted, equals('1 High Street, Bournemouth, BH1 1AA'));
    });
  });

  group('UkAddress.singleLine', () {
    test('should format as single line with commas', () {
      final address = UkAddress(
        line1: '1 High Street',
        line2: 'Flat 2',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );

      expect(
        address.singleLine,
        equals('1 High Street, Flat 2, Bournemouth, BH1 1AA'),
      );
    });
  });

  group('UkAddress.copyWith', () {
    test('should copy with new values', () {
      final original = UkAddress(
        line1: '1 High Street',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );

      final modified = original.copyWith(
        line2: 'Flat 3',
        county: 'Dorset',
      );

      expect(modified.line1, equals('1 High Street'));
      expect(modified.line2, equals('Flat 3'));
      expect(modified.city, equals('Bournemouth'));
      expect(modified.county, equals('Dorset'));
      expect(modified.postcode, equals('BH1 1AA'));
    });

    test('should not modify original', () {
      final original = UkAddress(
        line1: '1 High Street',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );

      original.copyWith(line2: 'Flat 3');

      expect(original.line2, isNull);
    });
  });

  group('UkAddress.fromJson', () {
    test('should parse full address from JSON', () {
      final json = {
        'line1': '1 High Street',
        'line2': 'Flat 2',
        'city': 'Bournemouth',
        'county': 'Dorset',
        'postcode': 'BH1 1AA',
      };

      final address = UkAddress.fromJson(json);

      expect(address.line1, equals('1 High Street'));
      expect(address.line2, equals('Flat 2'));
      expect(address.city, equals('Bournemouth'));
      expect(address.county, equals('Dorset'));
      expect(address.postcode, equals('BH1 1AA'));
    });

    test('should parse address with missing optional fields', () {
      final json = {
        'line1': '10 Main Road',
        'city': 'London',
        'postcode': 'SW1A 1AA',
      };

      final address = UkAddress.fromJson(json);

      expect(address.line1, equals('10 Main Road'));
      expect(address.line2, isNull);
      expect(address.city, equals('London'));
      expect(address.county, isNull);
      expect(address.postcode, equals('SW1A 1AA'));
    });

    test('should handle alternative API field names', () {
      // ePostcode API returns different field names
      final json = {
        'line_1': '1 High Street',
        'line_2': 'Flat 2',
        'post_town': 'BOURNEMOUTH',
        'county': 'Dorset',
        'postcode': 'BH1 1AA',
      };

      final address = UkAddress.fromEPostcodeJson(json);

      expect(address.line1, equals('1 High Street'));
      expect(address.line2, equals('Flat 2'));
      expect(address.city, equals('Bournemouth')); // Title case normalized
      expect(address.county, equals('Dorset'));
      expect(address.postcode, equals('BH1 1AA'));
    });
  });

  group('UkAddress.toJson', () {
    test('should serialize to JSON', () {
      final address = UkAddress(
        line1: '1 High Street',
        line2: 'Flat 2',
        city: 'Bournemouth',
        county: 'Dorset',
        postcode: 'BH1 1AA',
      );

      final json = address.toJson();

      expect(json['line1'], equals('1 High Street'));
      expect(json['line2'], equals('Flat 2'));
      expect(json['city'], equals('Bournemouth'));
      expect(json['county'], equals('Dorset'));
      expect(json['postcode'], equals('BH1 1AA'));
    });

    test('should serialize null optional fields as null', () {
      final address = UkAddress(
        line1: '10 Main Road',
        city: 'London',
        postcode: 'SW1A 1AA',
      );

      final json = address.toJson();

      expect(json['line2'], isNull);
      expect(json['county'], isNull);
    });
  });

  group('UkAddress equality', () {
    test('should be equal for same values', () {
      final a = UkAddress(
        line1: '1 High Street',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );
      final b = UkAddress(
        line1: '1 High Street',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('should not be equal for different values', () {
      final a = UkAddress(
        line1: '1 High Street',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );
      final b = UkAddress(
        line1: '2 High Street',
        city: 'Bournemouth',
        postcode: 'BH1 1AA',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
