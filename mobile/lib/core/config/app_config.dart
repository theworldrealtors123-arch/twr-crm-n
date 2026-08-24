/// Environment configuration.
///
/// The API base URL is supplied at build time so that no environment specific
/// value is hard-coded into the binary:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
///
/// Defaults target the Android emulator loopback (10.0.2.2 -> host machine).
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static const String appName = 'TWR CRM';
  static const String companyName = 'TWR REAL ESTATE';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const int leadsPageSize = 20;
  static const Duration searchDebounce = Duration(milliseconds: 400);
}
