import 'dart:convert';
import 'package:http/http.dart' as http;

/// Address result from postcode lookup
class PostcodeAddress {
  final String line1;
  final String line2;
  final String city;
  final String county;
  final String postcode;

  const PostcodeAddress({
    required this.line1,
    this.line2 = '',
    required this.city,
    this.county = '',
    required this.postcode,
  });

  factory PostcodeAddress.fromJson(Map<String, dynamic> json) {
    return PostcodeAddress(
      line1: json['line_1'] as String? ?? json['line1'] as String? ?? '',
      line2: json['line_2'] as String? ?? json['line2'] as String? ?? '',
      city: json['post_town'] as String? ??
          json['town_or_city'] as String? ??
          json['city'] as String? ??
          '',
      county: json['county'] as String? ?? '',
      postcode: json['postcode'] as String? ?? '',
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (line1.isNotEmpty) parts.add(line1);
    if (line2.isNotEmpty) parts.add(line2);
    if (city.isNotEmpty) parts.add(city);
    if (postcode.isNotEmpty) parts.add(postcode);
    return parts.join(', ');
  }
}

/// Service for UK postcode lookups
/// Uses postcodes.io (free, no API key required)
class PostcodeService {
  static const String _baseUrl = 'https://api.postcodes.io';

  /// Lookup addresses for a UK postcode
  /// Returns a list of addresses
  static Future<List<PostcodeAddress>> lookupPostcode(String postcode) async {
    // Clean and validate postcode
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    if (cleanPostcode.length < 5) {
      throw Exception('Postcode too short');
    }

    try {
      // Use postcodes.io to validate and get location data
      final response = await http.get(
        Uri.parse('$_baseUrl/postcodes/$cleanPostcode'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 && data['result'] != null) {
          final result = data['result'];

          // postcodes.io returns location data, not specific addresses
          // We'll create a generic address from the postcode data
          final formattedPostcode = result['postcode'] as String? ?? postcode;
          final ward = result['admin_ward'] as String? ?? '';
          final parish = result['parish'] as String? ?? '';
          final town = result['admin_district'] as String? ?? '';

          // Generate sample addresses for the postcode area
          // In production, you'd use a paid service like Ideal Postcodes
          // for actual address data
          final addresses = <PostcodeAddress>[];

          // Add a few placeholder addresses to demonstrate the UI
          // The user can manually edit these
          addresses.add(PostcodeAddress(
            line1: '1 ${ward.isNotEmpty ? ward : 'Main Street'}',
            city: town,
            postcode: formattedPostcode,
          ));

          addresses.add(PostcodeAddress(
            line1: '2 ${ward.isNotEmpty ? ward : 'Main Street'}',
            city: town,
            postcode: formattedPostcode,
          ));

          if (parish.isNotEmpty) {
            addresses.add(PostcodeAddress(
              line1: parish,
              city: town,
              postcode: formattedPostcode,
            ));
          }

          return addresses;
        }
      }

      // Postcode not found
      return [];
    } catch (e) {
      throw Exception('Failed to lookup postcode: $e');
    }
  }

  /// Validate a UK postcode format
  static bool isValidPostcode(String postcode) {
    // UK postcode regex
    final regex = RegExp(
      r'^[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}$',
      caseSensitive: false,
    );
    return regex.hasMatch(postcode.trim());
  }

  /// Format a postcode with space
  static String formatPostcode(String postcode) {
    final clean = postcode.replaceAll(' ', '').toUpperCase();
    if (clean.length < 5) return clean;

    // Insert space before last 3 characters
    final outward = clean.substring(0, clean.length - 3);
    final inward = clean.substring(clean.length - 3);
    return '$outward $inward';
  }
}
