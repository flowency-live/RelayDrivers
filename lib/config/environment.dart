/// Environment configuration for Relay Drivers app
enum Environment {
  dev,
  staging,
  prod,
}

class EnvironmentConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final String? tenantId; // For dev/test mode only

  const EnvironmentConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    this.tenantId,
  });

  static const dev = EnvironmentConfig._(
    environment: Environment.dev,
    apiBaseUrl: 'https://relay.api.opstack.uk',
    enableLogging: true,
    tenantId: 'TENANT#001', // DorsetTC for dev testing
  );

  static const staging = EnvironmentConfig._(
    environment: Environment.staging,
    apiBaseUrl: 'https://relay.api.opstack.uk',
    enableLogging: true,
  );

  static const prod = EnvironmentConfig._(
    environment: Environment.prod,
    apiBaseUrl: 'https://relay.api.opstack.uk',
    enableLogging: false,
  );

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}

/// Current environment - set via build configuration
const currentEnvironment = EnvironmentConfig.dev;

/// App version - injected via --dart-define=APP_VERSION at build time
/// Falls back to version string for local development
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.21');
