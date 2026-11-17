import '../../../../core/error/app_error.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final TokenStorage tokenStorage;
  final Duration delay;

  MockAuthRepository({
    required this.tokenStorage,
    this.delay = const Duration(milliseconds: 600),
  });

  static const List<User> _dummyUsers = [
    User(
      id: 1,
      name: 'Andi Pratama',
      email: 'andi@company.com',
      employeeCode: 'EMP-001',
      role: 'employee',
    ),
    User(
      id: 2,
      name: 'Budi Santoso',
      email: 'budi@company.com',
      employeeCode: 'EMP-002',
      role: 'employee',
    ),
    User(
      id: 3,
      name: 'Citra Dewi',
      email: 'citra@company.com',
      employeeCode: 'EMP-003',
      role: 'employee',
    ),
  ];

  User _currentUser = _dummyUsers[0];

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(delay);

    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const ValidationError('Email dan password wajib diisi');
    }

    final matched = _dummyUsers.cast<User?>().firstWhere(
          (u) => u?.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => null,
        );

    if (matched == null || password != 'password') {
      throw const ValidationError('Email atau kata sandi tidak sesuai');
    }

    _currentUser = matched;
    await tokenStorage.saveToken('mock_sanctum_token_${matched.id}');
    return _currentUser;
  }

  @override
  Future<User> getMe() async {
    await Future.delayed(delay);

    final token = await tokenStorage.getToken();
    if (token == null || !token.startsWith('mock_sanctum_token_')) {
      // ATT-07: Token tidak valid/hilang -> UnauthorizedError
      throw const UnauthorizedError();
    }

    final idStr = token.replaceAll('mock_sanctum_token_', '');
    final id = int.tryParse(idStr) ?? 1;
    final matched = _dummyUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => _currentUser,
    );

    _currentUser = matched;
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(delay);
    await tokenStorage.clearToken();
  }
}
