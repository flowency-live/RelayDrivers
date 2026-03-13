/// API Keys Configuration
///
/// Keys are injected at build time via --dart-define
/// Example: flutter build apk --dart-define=EPOSTCODE_API_KEY=your-key
///
/// For local development, create a .env file or pass directly.
class ApiKeys {
  /// ePostcode API key for address autocomplete
  /// Injected via: --dart-define=EPOSTCODE_API_KEY=xxx
  static const String ePostcode = String.fromEnvironment(
    'EPOSTCODE_API_KEY',
    defaultValue: '',
  );

  /// Check if API keys are configured
  static bool get isConfigured => ePostcode.isNotEmpty;
}
