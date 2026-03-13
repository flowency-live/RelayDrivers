/// Represents a UK postal address
///
/// This is an immutable value object that stores address components
/// for UK addresses. It supports multiple source formats including
/// standard JSON and ePostcode API responses.
class UkAddress {
  final String line1;
  final String? line2;
  final String city;
  final String? county;
  final String postcode;

  const UkAddress({
    required this.line1,
    this.line2,
    required this.city,
    this.county,
    required this.postcode,
  });

  /// Creates a UkAddress from standard JSON format
  factory UkAddress.fromJson(Map<String, dynamic> json) {
    return UkAddress(
      line1: json['line1'] as String,
      line2: json['line2'] as String?,
      city: json['city'] as String,
      county: json['county'] as String?,
      postcode: json['postcode'] as String,
    );
  }

  /// Creates a UkAddress from ePostcode API response format
  ///
  /// ePostcode uses different field names:
  /// - line_1, line_2 (with underscores)
  /// - post_town (instead of city, often uppercase)
  factory UkAddress.fromEPostcodeJson(Map<String, dynamic> json) {
    // Normalize post_town from UPPERCASE to Title Case
    final postTown = json['post_town'] as String?;
    final normalizedCity = postTown != null ? _toTitleCase(postTown) : '';

    return UkAddress(
      line1: json['line_1'] as String,
      line2: json['line_2'] as String?,
      city: normalizedCity,
      county: json['county'] as String?,
      postcode: json['postcode'] as String,
    );
  }

  /// Converts a string to Title Case
  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Converts the address to JSON format
  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'county': county,
      'postcode': postcode,
    };
  }

  /// Returns the address as a formatted multi-line string
  /// Excludes empty/null optional fields
  String get formatted {
    final parts = <String>[
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      city,
      if (county != null && county!.isNotEmpty) county!,
      postcode,
    ];
    return parts.join(', ');
  }

  /// Returns the address as a single line with commas
  /// Same as formatted, kept for compatibility
  String get singleLine => formatted;

  /// Creates a copy of this address with updated fields
  UkAddress copyWith({
    String? line1,
    String? line2,
    String? city,
    String? county,
    String? postcode,
  }) {
    return UkAddress(
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      county: county ?? this.county,
      postcode: postcode ?? this.postcode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UkAddress &&
        other.line1 == line1 &&
        other.line2 == line2 &&
        other.city == city &&
        other.county == county &&
        other.postcode == postcode;
  }

  @override
  int get hashCode {
    return Object.hash(line1, line2, city, county, postcode);
  }

  @override
  String toString() {
    return 'UkAddress($formatted)';
  }
}
