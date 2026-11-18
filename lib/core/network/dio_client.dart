import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../error/app_error.dart';
import '../storage/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // ATT-07: Response 401 -> hapus token
        if (e.response?.statusCode == 401) {
          await tokenStorage.clearToken();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});

AppError mapDioExceptionToAppError(dynamic error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return const UnauthorizedError();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkError();
    }
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map) {
        final err = data['error'];
        if (err is Map && err['message'] != null) {
          return ValidationError(err['message'].toString());
        }
        if (err is String) {
          return ValidationError(err);
        }
        if (data['message'] != null) {
          return ValidationError(data['message'].toString());
        }
      }
      return ValidationError('Request ditolak oleh server (${error.response?.statusCode})');
    }
    return const NetworkError();
  }
  if (error is AppError) {
    return error;
  }
  return UnknownError(error.toString());
}
