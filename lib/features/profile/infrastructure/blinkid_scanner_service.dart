import 'dart:io' show Platform;

import 'package:blinkid_flutter/blinkid_flutter.dart';
import 'package:flutter/foundation.dart';

/// Result from scanning a UK driving licence
class DrivingLicenceScanResult {
  final String? licenceNumber;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final DateTime? expiryDate;
  final String? address;

  const DrivingLicenceScanResult({
    this.licenceNumber,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.expiryDate,
    this.address,
  });

  bool get hasLicenceNumber => licenceNumber != null && licenceNumber!.isNotEmpty;
}

/// Service for scanning UK driving licences using BlinkID
class BlinkIdScannerService {
  static const String _iosLicenseKey =
      'sRwCABd1ay5vcHN0YWNrLnJlbGF5ZHJpdmVycwFsZXlKRGNtVmhkR1ZrVDI0aU9qRTNOek00TlRreE16UTVPREVzSWtOeVpXRjBaV1JHYjNJaU9pSXdZbVZsWkdZeU9DMWpOR05pTFRRMU16UXRZalV4WkMwMk9HRmlaakJpTW1VNE1qY2lmUT095BssMDVli+bt5PqxBt5qksb22YE9GR/KENuUij8EyMRVHBk382Spv7WA6ilGo/Nw5jTh/SU3PLWlAPlnaMwvJjmekP1x0XX34CUi7rY+jCH+MwiPMsK4eC2886xM';

  static const String _androidLicenseKey =
      'sRwCABd1ay5vcHN0YWNrLnJlbGF5ZHJpdmVycwBsZXlKRGNtVmhkR1ZrVDI0aU9qRTNOek00TlRreE16VXhOVE1zSWtOeVpXRjBaV1JHYjNJaU9pSXdZbVZsWkdZeU9DMWpOR05pTFRRMU16UXRZalV4WkMwMk9HRmlaakJpTW1VNE1qY2lmUT09CC+2jqPY0t18TbL3OqKV9muZRtBqbvHpgBMRGp/wxa+LENFzoF2hAHAHgFMm0QOAvmAiy9Tn5LIpmdY2MVqL1cN5I1vb3SC2Y94E+J0WTzajbOVcIprNbr2T3ZGg';

  /// Returns the appropriate license key for the current platform
  static String get _licenseKey {
    if (kIsWeb) {
      throw UnsupportedError('BlinkID is not supported on web platform');
    }
    if (Platform.isIOS) {
      return _iosLicenseKey;
    } else if (Platform.isAndroid) {
      return _androidLicenseKey;
    }
    throw UnsupportedError('BlinkID is only supported on iOS and Android');
  }

  /// Check if scanning is available on this platform
  static bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Scan a UK driving licence using the device camera
  /// Returns null if scanning was cancelled or failed
  static Future<DrivingLicenceScanResult?> scanDrivingLicence() async {
    if (!isAvailable) {
      debugPrint('BlinkID scanning not available on this platform');
      return null;
    }

    try {
      // Create SDK settings with license key
      final sdkSettings = BlinkIdSdkSettings(_licenseKey);

      // Create session settings - automatic mode for both sides
      final sessionSettings = BlinkIdSessionSettings();
      sessionSettings.scanningMode = ScanningMode.automatic;

      // Configure to filter for UK driving licences
      final classFilter = ClassFilter();
      classFilter.includeDocuments = [
        DocumentFilter(Country.uK, null, DocumentType.dl),
      ];

      // Perform the scan
      final blinkIdPlugin = BlinkidFlutter();
      final result = await blinkIdPlugin.performScan(
        sdkSettings,
        sessionSettings,
        null, // UX settings (use defaults)
        classFilter,
      );

      if (result == null) {
        debugPrint('Scan cancelled or no result');
        return null;
      }

      return _extractDrivingLicenceData(result);
    } catch (e, stackTrace) {
      debugPrint('Error scanning driving licence: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Extract driving licence data from BlinkID result
  static DrivingLicenceScanResult _extractDrivingLicenceData(
    BlinkIdScanningResult result,
  ) {
    // Extract licence number (document number for UK DL)
    String? licenceNumber = result.documentNumber?.value;

    // Clean up licence number (remove spaces and normalize)
    if (licenceNumber != null && licenceNumber.isNotEmpty) {
      licenceNumber = licenceNumber.replaceAll(' ', '').toUpperCase();
    }

    // Extract name
    final firstName = result.firstName?.value;
    final lastName = result.lastName?.value;

    // Extract dates
    DateTime? dateOfBirth;
    if (result.dateOfBirth?.date != null) {
      final dob = result.dateOfBirth!.date!;
      if (dob.year != null && dob.month != null && dob.day != null) {
        dateOfBirth = DateTime(dob.year!, dob.month!, dob.day!);
      }
    }

    DateTime? expiryDate;
    if (result.dateOfExpiry?.date != null) {
      final exp = result.dateOfExpiry!.date!;
      if (exp.year != null && exp.month != null && exp.day != null) {
        expiryDate = DateTime(exp.year!, exp.month!, exp.day!);
      }
    }

    // Extract address
    final address = result.address?.value;

    return DrivingLicenceScanResult(
      licenceNumber: licenceNumber,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      expiryDate: expiryDate,
      address: address,
    );
  }
}
