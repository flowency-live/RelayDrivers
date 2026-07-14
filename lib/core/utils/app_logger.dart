import 'package:flutter/foundation.dart';

/// Lightweight logger that only emits in debug builds.
///
/// Replaces raw `print()` calls throughout the app. In release builds these
/// are compiled out via [kDebugMode], so no diagnostic data (including auth
/// tokens) is ever written to the browser console or device logs of a
/// production build.
///
/// Never log full token values - log presence/length only.
abstract class AppLogger {
  /// Log a debug message (debug builds only).
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Log an error message (debug builds only).
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint(message);
      if (error != null) debugPrint('  error: $error');
      if (stackTrace != null) debugPrint('  stack: $stackTrace');
    }
  }
}
