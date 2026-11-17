class AppConfig {
  AppConfig._();

  /// Change this single flag to switch between Mock Repository and Laravel API
  static const bool useMock = true;

  /// Laravel API Base URL
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator localhost

  /// Network timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
