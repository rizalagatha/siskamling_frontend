// lib/config.dart

class Config {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://103.94.238.252:3003/api',
  );
}
