class AppConfig {
  AppConfig._();

  /// Change this single flag to switch between Mock Repository and Live API
  static const bool useMock = false;

  /// Backend API Base URL
  static const String baseUrl = 'http://192.168.0.130:3000/api/';

  /// Network timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
