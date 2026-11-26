/// Public build configuration. Credentials must never be embedded here.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://example-campus-api.test',
  );

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}
