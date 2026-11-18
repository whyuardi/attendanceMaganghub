import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiAuthRepository({
    required this.dio,
    required this.tokenStorage,
  });

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await dio.post(
        'login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      final token = data['token'] ?? data['access_token'] ?? data['data']?['token'];
      if (token != null) {
        await tokenStorage.saveToken(token.toString());
      }

      // Ambil data profil lengkap (/api/me) agar nama & kode karyawan dari tabel employees terisi
      try {
        return await getMe();
      } catch (_) {
        final userData = data['user'] ?? data['data']?['user'] ?? data['data'] ?? data;
        return User.fromJson(Map<String, dynamic>.from(userData as Map));
      }
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<User> getMe() async {
    try {
      final response = await dio.get('me');
      final data = response.data;
      final userData = data['data'] ?? data['user'] ?? data;
      return User.fromJson(Map<String, dynamic>.from(userData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('logout');
    } catch (_) {
      // Ignore network failure on logout; ensure local token is wiped
    } finally {
      await tokenStorage.clearToken();
    }
  }
}
