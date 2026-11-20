// lib/config.dart

class Config {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://sis.manksi.com/api',
  );
}
