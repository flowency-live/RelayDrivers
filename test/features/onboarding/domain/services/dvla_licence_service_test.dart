import 'package:flutter_test/flutter_test.dart';
import 'package:relay_drivers/features/onboarding/domain/services/dvla_licence_service.dart';

/// Tests for DvlaLicenceService
///
/// UK DVLA Licence Number Format (16 characters):
/// MORGA657054SM9IJ
/// │    │     │  │
/// │    │     │  └─ 3 random security chars (USER ENTERS)
/// │    │     └──── 2 initials (from first name, middle name/pad with 9)
/// │    └────────── 6-char DOB: decade, month (female +50), day, year digit
/// └─────────────── 5 chars surname (pad with 9s if <5)
void main() {
  late DvlaLicenceService service;

  setUp(() {
    service = DvlaLicenceService();
  });

  group('generateSurnamePart()', () {
    test('should return first 5 chars of surname in uppercase', () {
      expect(service.generateSurnamePart('Morgan'), equals('MORGA'));
      expect(service.generateSurnamePart('SMITH'), equals('SMITH'));
      expect(service.generateSurnamePart('Brown'), equals('BROWN'));
    });

    test('should pad short surnames with 9s', () {
      expect(service.generateSurnamePart('Li'), equals('LI999'));
      expect(service.generateSurnamePart('Wu'), equals('WU999'));
      expect(service.generateSurnamePart('Fox'), equals('FOX99'));
      expect(service.generateSurnamePart('King'), equals('KING9'));
    });

    test('should handle exactly 5 char surnames', () {
      expect(service.generateSurnamePart('Jones'), equals('JONES'));
      expect(service.generateSurnamePart('Davis'), equals('DAVIS'));
    });

    test('should handle empty surname', () {
      expect(service.generateSurnamePart(''), equals('99999'));
    });

    test('should strip spaces and hyphens', () {
      expect(service.generateSurnamePart('O\'Brien'), equals('OBRIE'));
      expect(service.generateSurnamePart('Van Der Berg'), equals('VANDE'));
      expect(service.generateSurnamePart('Smith-Jones'), equals('SMITH'));
    });
  });

  group('generateDobPart()', () {
    // DOB format: decade (1 char), month (2 chars), day (2 chars), year digit (1 char)
    // For females: add 50 to month
    // Example: 05/07/1965 male = 657054
    //          05/07/1965 female = 657554 (07 + 50 = 57)

    test('should generate correct DOB part for male - July 1965', () {
      // 05/07/1965 male: decade=6, month=07, day=05, year=5
      // Result: 6 07 05 5 = 607055? Wait, let me re-read the spec
      // From user: "6 char code for DOB: 5th char = decade of birth"
      // Actually looking at MORGA657054SM9IJ:
      // 6 = decade (1960s), 57 = month (07+50 for female), 05 = day, 4 = year digit
      // Wait, that's Sarah Morgan who is female. Let me re-check for male.
      //
      // From user spec: "6 char code for DOB (5th char = decade of birth - 6 for the sixties)"
      // "month of birth (5th and 6th char)"
      // "date of birth (7th and 8th char)"
      // "9th char = year digit"
      // That's positions 5-10 (1-indexed), or chars 4-9 (0-indexed)
      //
      // So for 05/07/1965:
      // Position 5 (index 4): decade = 6
      // Position 6-7 (index 5-6): month = 07 (or 57 for female)
      // Position 8-9 (index 7-8): day = 05
      // Position 10 (index 9): year digit = 5
      //
      // Combined: 6 + 07 + 05 + 5 = 607055
      // Wait, that's only 6 chars total
      // But MORGA is 5 chars + 657054 is 6 chars = 11 so far
      expect(service.generateDobPart('05/07/1965', Gender.male), equals('607055'));
    });

    test('should generate correct DOB part for female - July 1965', () {
      // 05/07/1965 female: decade=6, month=57 (07+50), day=05, year=5
      expect(service.generateDobPart('05/07/1965', Gender.female), equals('657055'));
    });

    test('should handle different decades', () {
      // 15/03/1978: decade=7, month=03, day=15, year=8
      expect(service.generateDobPart('15/03/1978', Gender.male), equals('703158'));
      // 22/11/1992: decade=9, month=11, day=22, year=2
      expect(service.generateDobPart('22/11/1992', Gender.male), equals('911222'));
      // 01/01/2000: decade=0, month=01, day=01, year=0
      expect(service.generateDobPart('01/01/2000', Gender.male), equals('001010'));
    });

    test('should handle December correctly', () {
      // December = month 12, female = 62
      expect(service.generateDobPart('25/12/1985', Gender.male), equals('812255'));
      expect(service.generateDobPart('25/12/1985', Gender.female), equals('862255'));
    });

    test('should handle ISO date format', () {
      expect(service.generateDobPart('1965-07-05', Gender.male), equals('607055'));
    });
  });

  group('generateInitialsPart()', () {
    test('should return first char of first and middle name', () {
      expect(service.generateInitialsPart('Sarah', 'Mary'), equals('SM'));
      expect(service.generateInitialsPart('John', 'William'), equals('JW'));
    });

    test('should pad with 9 if no middle name', () {
      expect(service.generateInitialsPart('John', null), equals('J9'));
      expect(service.generateInitialsPart('Sarah', ''), equals('S9'));
    });

    test('should handle empty first name', () {
      expect(service.generateInitialsPart('', null), equals('99'));
    });

    test('should uppercase initials', () {
      expect(service.generateInitialsPart('john', 'william'), equals('JW'));
    });
  });

  group('generateLicencePrefix()', () {
    test('should generate complete 13-char prefix for Sarah Morgan', () {
      // MORGA + 657055 + SM = MORGA657055SM (12 chars actually)
      // Wait, the user said 13 chars auto-generated, 3 user-entered
      // Let me re-check: MORGA657054SM9IJ
      // MORGA = 5 (surname)
      // 657054 = 6 (DOB)  - wait, 657054 not 657055
      // SM = 2 (initials)
      // 9IJ = 3 (security - user enters)
      // That's 5 + 6 + 2 = 13 auto-generated, correct!
      //
      // The example has 657054 for DOB:
      // decade=6, month=57 (July+50 female), day=05, year=4
      // Wait, that means the year digit is 4, but 1965 has digit 5...
      // Unless they're showing 1964? Let me use 5 for 1965.
      final prefix = service.generateLicencePrefix(
        surname: 'Morgan',
        dateOfBirth: '05/07/1965',
        firstName: 'Sarah',
        middleName: 'Mary',
        gender: Gender.female,
      );
      expect(prefix.length, equals(13));
      expect(prefix.substring(0, 5), equals('MORGA'));
      expect(prefix.substring(5, 11), equals('657055'));
      expect(prefix.substring(11, 13), equals('SM'));
    });

    test('should generate prefix for John Smith (male, no middle name)', () {
      final prefix = service.generateLicencePrefix(
        surname: 'Smith',
        dateOfBirth: '15/03/1978',
        firstName: 'John',
        middleName: null,
        gender: Gender.male,
      );
      expect(prefix.length, equals(13));
      expect(prefix.substring(0, 5), equals('SMITH'));
      expect(prefix.substring(11, 13), equals('J9'));
    });
  });

  group('buildFullLicenceNumber()', () {
    test('should combine prefix with security chars', () {
      final full = service.buildFullLicenceNumber('MORGA657055SM', 'ABC');
      expect(full, equals('MORGA657055SMABC'));
      expect(full.length, equals(16));
    });

    test('should uppercase security chars', () {
      final full = service.buildFullLicenceNumber('MORGA657055SM', 'abc');
      expect(full, equals('MORGA657055SMABC'));
    });

    test('should reject wrong length security chars', () {
      expect(() => service.buildFullLicenceNumber('MORGA657055SM', 'AB'), throwsArgumentError);
      expect(() => service.buildFullLicenceNumber('MORGA657055SM', 'ABCD'), throwsArgumentError);
    });
  });

  group('validateLicenceNumber()', () {
    test('should validate correct licence format', () {
      expect(service.validateLicenceNumber('MORGA657055SMABC'), isTrue);
      expect(service.validateLicenceNumber('SMITH703157J9XYZ'), isTrue);
    });

    test('should reject wrong length', () {
      expect(service.validateLicenceNumber('MORGA657055SM'), isFalse);
      expect(service.validateLicenceNumber('MORGA657055SMABCDEF'), isFalse);
    });

    test('should reject invalid characters', () {
      expect(service.validateLicenceNumber('MORGA657055SM@BC'), isFalse);
    });
  });

  group('canAutoGenerate()', () {
    test('should return true when all required fields present', () {
      expect(
        service.canAutoGenerate(
          surname: 'Morgan',
          dateOfBirth: '05/07/1965',
          firstName: 'Sarah',
          gender: Gender.female,
        ),
        isTrue,
      );
    });

    test('should return false when surname missing', () {
      expect(
        service.canAutoGenerate(
          surname: null,
          dateOfBirth: '05/07/1965',
          firstName: 'Sarah',
          gender: Gender.female,
        ),
        isFalse,
      );
    });

    test('should return false when DOB missing', () {
      expect(
        service.canAutoGenerate(
          surname: 'Morgan',
          dateOfBirth: null,
          firstName: 'Sarah',
          gender: Gender.female,
        ),
        isFalse,
      );
    });

    test('should return false when firstName missing', () {
      expect(
        service.canAutoGenerate(
          surname: 'Morgan',
          dateOfBirth: '05/07/1965',
          firstName: null,
          gender: Gender.female,
        ),
        isFalse,
      );
    });

    test('should return false when gender missing', () {
      expect(
        service.canAutoGenerate(
          surname: 'Morgan',
          dateOfBirth: '05/07/1965',
          firstName: 'Sarah',
          gender: null,
        ),
        isFalse,
      );
    });
  });
}
