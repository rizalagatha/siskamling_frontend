// lib/config.dart

class Config {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.73:4040/api',
  );
}
