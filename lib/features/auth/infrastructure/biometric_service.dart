import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric authentication service
/// Handles fingerprint/Face ID for session unlock
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastBiometricAuth = 'last_biometric_auth';
  static const String _keySessionToken = 'biometric_session_token';

  /// Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are available (enrolled)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Check if biometric login is enabled by user
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Enable biometric login
  Future<void> enableBiometric() async {
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _storage.write(key: _keyBiometricEnabled, value: 'false');
    await _storage.delete(key: _keySessionToken);
    await _storage.delete(key: _keyLastBiometricAuth);
  }

  /// Store session token for biometric unlock
  Future<void> storeSessionToken(String token) async {
    await _storage.write(key: _keySessionToken, value: token);
  }

  /// Get stored session token
  Future<String?> getSessionToken() async {
    return await _storage.read(key: _keySessionToken);
  }

  /// Clear session token
  Future<void> clearSessionToken() async {
    await _storage.delete(key: _keySessionToken);
    await _storage.delete(key: _keyLastBiometricAuth);
  }

  /// Check if biometric auth is required today
  /// Returns true if last successful biometric auth was > 24 hours ago
  Future<bool> requiresBiometricToday() async {
    final lastAuthStr = await _storage.read(key: _keyLastBiometricAuth);
    if (lastAuthStr == null) return true;

    try {
      final lastAuth = DateTime.parse(lastAuthStr);
      final now = DateTime.now();
      return now.difference(lastAuth).inHours >= 24;
    } catch (e) {
      return true;
    }
  }

  /// Authenticate with biometrics
  /// Returns true if authentication successful
  Future<BiometricResult> authenticate({
    String reason = 'Verify your identity to access Relay Drivers',
  }) async {
    try {
      // Check if device supports biometrics
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricResult.notSupported;
      }

      // Check if biometrics are available
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return BiometricResult.notEnrolled;
      }

      // Attempt authentication
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      if (didAuthenticate) {
        // Record successful authentication time
        await _storage.write(
          key: _keyLastBiometricAuth,
          value: DateTime.now().toIso8601String(),
        );
        return BiometricResult.success;
      }

      return BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        return BiometricResult.notSupported;
      }
      if (e.code == 'NotEnrolled') {
        return BiometricResult.notEnrolled;
      }
      if (e.code == 'LockedOut') {
        return BiometricResult.lockedOut;
      }
      if (e.code == 'PermanentlyLockedOut') {
        return BiometricResult.permanentlyLockedOut;
      }
      return BiometricResult.error;
    }
  }

  /// Get human-readable biometric type name
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    if (types.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }
}

/// Biometric authentication result
enum BiometricResult {
  /// Authentication successful
  success,

  /// User cancelled or failed authentication
  failed,

  /// Device doesn't support biometrics
  notSupported,

  /// No biometrics enrolled on device
  notEnrolled,

  /// Too many failed attempts - temporarily locked
  lockedOut,

  /// Too many failed attempts - permanently locked (needs device unlock)
  permanentlyLockedOut,

  /// Unknown error occurred
  error,
}

/// Extension for user-friendly messages
extension BiometricResultMessages on BiometricResult {
  String get message {
    switch (this) {
      case BiometricResult.success:
        return 'Authentication successful';
      case BiometricResult.failed:
        return 'Authentication failed. Please try again.';
      case BiometricResult.notSupported:
        return 'Biometric authentication is not supported on this device.';
      case BiometricResult.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint or Face ID in device settings.';
      case BiometricResult.lockedOut:
        return 'Too many failed attempts. Please wait and try again.';
      case BiometricResult.permanentlyLockedOut:
        return 'Biometric locked. Please unlock your device first.';
      case BiometricResult.error:
        return 'An error occurred. Please try again.';
    }
  }

  bool get isRecoverable {
    return this == BiometricResult.failed ||
        this == BiometricResult.lockedOut ||
        this == BiometricResult.error;
  }
}
