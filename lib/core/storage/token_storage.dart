import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

class TokenStorage {
  final FlutterSecureStorage? _storage;
  String? _inMemoryToken;
  static const _keyToken = 'auth_token';

  TokenStorage([this._storage]);

  factory TokenStorage.inMemory([String? initialToken]) {
    final storage = TokenStorage(null);
    storage._inMemoryToken = initialToken;
    return storage;
  }

  Future<void> saveToken(String token) async {
    if (_storage != null) {
      await _storage.write(key: _keyToken, value: token);
    } else {
      _inMemoryToken = token;
    }
  }

  Future<String?> getToken() async {
    if (_storage != null) {
      return await _storage.read(key: _keyToken);
    }
    return _inMemoryToken;
  }

  Future<void> clearToken() async {
    if (_storage != null) {
      await _storage.delete(key: _keyToken);
    } else {
      _inMemoryToken = null;
    }
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
