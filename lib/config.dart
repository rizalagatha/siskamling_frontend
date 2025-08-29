// lib/config.dart

class Config {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.191:3000/api',
  );
}
