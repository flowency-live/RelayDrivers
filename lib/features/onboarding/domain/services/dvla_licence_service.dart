/// Pure domain service for DVLA licence number generation
/// ZERO framework imports - pure Dart only
///
/// UK DVLA Licence Number Format (16 characters):
/// MORGA657054SM9IJ
/// │    │     │  │
/// │    │     │  └─ 3 random security chars (USER ENTERS)
/// │    │     └──── 2 initials (first name initial + middle name initial or 9)
/// │    └────────── 6-char DOB: decade, month (female +50), day, year digit
/// └─────────────── 5 chars surname (pad with 9s if <5)

/// Gender enum for DVLA licence calculation
enum Gender {
  male,
  female,
}

/// Service for generating and validating UK DVLA driving licence numbers
class DvlaLicenceService {
  /// Generate the 5-character surname part of the licence number
  ///
  /// - Takes first 5 characters of surname
  /// - Pads with 9s if surname is shorter than 5 characters
  /// - Strips apostrophes, spaces, and hyphens
  /// - Returns uppercase
  String generateSurnamePart(String surname) {
    // Strip non-alphanumeric characters
    final cleaned = surname.replaceAll(RegExp(r"[^a-zA-Z]"), '').toUpperCase();

    if (cleaned.isEmpty) {
      return '99999';
    }

    if (cleaned.length >= 5) {
      return cleaned.substring(0, 5);
    }

    // Pad with 9s
    return cleaned.padRight(5, '9');
  }

  /// Generate the 6-character DOB part of the licence number
  ///
  /// Format: DMMDDY where:
  /// - D = decade digit (6 for 1960s)
  /// - MM = month (female adds 50, so July female = 57)
  /// - DD = day
  /// - Y = last digit of year
  ///
  /// Accepts dates in DD/MM/YYYY or YYYY-MM-DD format
  String generateDobPart(String dateOfBirth, Gender gender) {
    int day, month, year;

    if (dateOfBirth.contains('-')) {
      // ISO format: YYYY-MM-DD
      final parts = dateOfBirth.split('-');
      year = int.parse(parts[0]);
      month = int.parse(parts[1]);
      day = int.parse(parts[2]);
    } else if (dateOfBirth.contains('/')) {
      // UK format: DD/MM/YYYY
      final parts = dateOfBirth.split('/');
      day = int.parse(parts[0]);
      month = int.parse(parts[1]);
      year = int.parse(parts[2]);
    } else {
      throw ArgumentError('Invalid date format: $dateOfBirth');
    }

    // Decade digit (e.g., 1965 -> 6, 1978 -> 7, 2000 -> 0)
    final decade = (year ~/ 10) % 10;

    // Month - add 50 for females
    final adjustedMonth = gender == Gender.female ? month + 50 : month;

    // Year digit (last digit)
    final yearDigit = year % 10;

    // Format: D + MM + DD + Y
    final decadeStr = decade.toString();
    final monthStr = adjustedMonth.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    final yearStr = yearDigit.toString();

    return '$decadeStr$monthStr$dayStr$yearStr';
  }

  /// Generate the 2-character initials part of the licence number
  ///
  /// - First character: first letter of first name
  /// - Second character: first letter of middle name, or 9 if no middle name
  String generateInitialsPart(String firstName, String? middleName) {
    String first = '9';
    String second = '9';

    if (firstName.isNotEmpty) {
      first = firstName[0].toUpperCase();
    }

    if (middleName != null && middleName.isNotEmpty) {
      second = middleName[0].toUpperCase();
    }

    return '$first$second';
  }

  /// Generate the complete 13-character prefix that can be auto-generated
  ///
  /// This is everything except the 3 security characters which the user enters.
  String generateLicencePrefix({
    required String surname,
    required String dateOfBirth,
    required String firstName,
    String? middleName,
    required Gender gender,
  }) {
    final surnamePart = generateSurnamePart(surname);
    final dobPart = generateDobPart(dateOfBirth, gender);
    final initialsPart = generateInitialsPart(firstName, middleName);

    return '$surnamePart$dobPart$initialsPart';
  }

  /// Combine the auto-generated prefix with user-entered security characters
  ///
  /// Throws [ArgumentError] if security chars is not exactly 3 characters.
  String buildFullLicenceNumber(String prefix, String securityChars) {
    final cleaned = securityChars.trim().toUpperCase();

    if (cleaned.length != 3) {
      throw ArgumentError(
        'Security characters must be exactly 3 characters, got: ${cleaned.length}',
      );
    }

    return '$prefix$cleaned';
  }

  /// Validate a complete 16-character licence number format
  ///
  /// - Must be exactly 16 characters
  /// - Must be alphanumeric only
  bool validateLicenceNumber(String licenceNumber) {
    if (licenceNumber.length != 16) {
      return false;
    }

    // Must be alphanumeric only
    return RegExp(r'^[A-Z0-9]+$').hasMatch(licenceNumber.toUpperCase());
  }

  /// Check if we have enough information to auto-generate the licence prefix
  bool canAutoGenerate({
    String? surname,
    String? dateOfBirth,
    String? firstName,
    Gender? gender,
  }) {
    return surname != null &&
        surname.isNotEmpty &&
        dateOfBirth != null &&
        dateOfBirth.isNotEmpty &&
        firstName != null &&
        firstName.isNotEmpty &&
        gender != null;
  }
}
