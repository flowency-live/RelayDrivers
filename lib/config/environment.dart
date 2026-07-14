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

/// Selected environment name, injected at build time via
/// `--dart-define=ENVIRONMENT=dev|staging|prod`.
///
/// Defaults to **prod** so that a release build with no explicit flavor ships
/// production configuration (logging off, no tenant-spoof header). Local dev
/// and CI must pass `--dart-define=ENVIRONMENT=dev` (or staging) explicitly.
const String _environmentName =
    String.fromEnvironment('ENVIRONMENT', defaultValue: 'prod');

/// Current environment - resolved from the build-time flavor. Remains a
/// compile-time constant so it can be tree-shaken and used in const contexts.
const EnvironmentConfig currentEnvironment = _environmentName == 'dev'
    ? EnvironmentConfig.dev
    : _environmentName == 'staging'
        ? EnvironmentConfig.staging
        : EnvironmentConfig.prod;

/// App version - injected via --dart-define=APP_VERSION at build time
/// Falls back to version string for local development
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.29');
