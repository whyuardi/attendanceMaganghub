import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  final Dio dio;
  final FlutterSecureStorage _storage;

  static const _keyDisplayName = 'profile_display_name';
  static const _keyPhotoPath = 'profile_photo_path';

  ApiProfileRepository({
    required this.dio,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  // ── Local name ──────────────────────────────────────────────────────

  @override
  Future<void> saveDisplayName(String name) async {
    await _storage.write(key: _keyDisplayName, value: name);
  }

  @override
  Future<String?> getDisplayName() async {
    return await _storage.read(key: _keyDisplayName);
  }

  // ── Password change ─────────────────────────────────────────────────

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Try the self-service password change endpoint first
      await dio.put(
        'me/password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Endpoint doesn't exist — try alternative: re-login to verify old password,
        // then call employees endpoint
        await _changePasswordViaLogin(oldPassword, newPassword);
      } else {
        throw mapDioExceptionToAppError(e);
      }
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  Future<void> _changePasswordViaLogin(
    String oldPassword,
    String newPassword,
  ) async {
    // Step 1: Get current user email via /me
    final meResponse = await dio.get('me');
    final meData = meResponse.data;
    final userData = meData['data'] ?? meData['user'] ?? meData;
    final email = userData['email'] as String?;
    if (email == null || email.isEmpty) {
      throw Exception('Tidak dapat memverifikasi identitas pengguna');
    }

    // Step 2: Verify old password by attempting login
    try {
      await dio.post('login', data: {
        'email': email,
        'password': oldPassword,
      });
    } catch (_) {
      throw Exception('Password lama salah');
    }

    // Step 3: Get employee_id from /me response
    final employeeData = userData['employee'];
    final employeeId = employeeData?['id'] ?? userData['employee_id'];
    if (employeeId == null) {
      throw Exception('Data karyawan tidak ditemukan');
    }

    // Step 4: Try to update password via employees endpoint
    // This may fail with 403 if backend requires HR role
    try {
      await dio.put(
        'employees/$employeeId',
        data: {'password': newPassword},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception(
          'Fitur ubah password belum tersedia. Hubungi HR untuk mengubah password.',
        );
      }
      throw mapDioExceptionToAppError(e);
    }
  }

  // ── Local photo ─────────────────────────────────────────────────────

  @override
  Future<void> saveProfilePhotoPath(String path) async {
    await _storage.write(key: _keyPhotoPath, value: path);
  }

  @override
  Future<String?> getProfilePhotoPath() async {
    return await _storage.read(key: _keyPhotoPath);
  }

  // ── Clear ───────────────────────────────────────────────────────────

  @override
  Future<void> clearLocalProfile() async {
    await _storage.delete(key: _keyDisplayName);
    await _storage.delete(key: _keyPhotoPath);
  }
}
