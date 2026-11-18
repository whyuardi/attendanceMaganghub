import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/api_profile_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiProfileRepository(dio: dio);
});

// ── State ───────────────────────────────────────────────────────────────

class ProfileEditState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String? displayName;
  final String? photoPath;

  const ProfileEditState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.displayName,
    this.photoPath,
  });

  ProfileEditState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? displayName,
    String? photoPath,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final ProfileRepository _repo;
  final AuthNotifier _authNotifier;

  ProfileEditNotifier(this._repo, this._authNotifier)
      : super(const ProfileEditState());

  /// Load saved local profile data.
  Future<void> loadLocalProfile() async {
    final name = await _repo.getDisplayName();
    final photo = await _repo.getProfilePhotoPath();
    state = state.copyWith(
      displayName: name ?? '',
      photoPath: photo ?? '',
      clearError: true,
      clearSuccess: true,
    );
  }

  /// Update display name (local only).
  Future<void> updateDisplayName(String name) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Nama tidak boleh kosong',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repo.saveDisplayName(name.trim());
      state = state.copyWith(
        isLoading: false,
        displayName: name.trim(),
        successMessage: 'Nama berhasil diperbarui',
      );

      // Refresh auth state so name is reflected everywhere
      await _authNotifier.checkAuthStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Change password via backend.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validations
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Semua kolom password harus diisi',
        clearSuccess: true,
      );
      return;
    }
    if (newPassword.length < 6) {
      state = state.copyWith(
        errorMessage: 'Password baru minimal 6 karakter',
        clearSuccess: true,
      );
      return;
    }
    if (newPassword != confirmPassword) {
      state = state.copyWith(
        errorMessage: 'Password baru dan konfirmasi tidak cocok',
        clearSuccess: true,
      );
      return;
    }
    if (oldPassword == newPassword) {
      state = state.copyWith(
        errorMessage: 'Password baru harus berbeda dari password lama',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repo.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password berhasil diubah',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Pick photo from gallery and save locally.
  Future<void> pickPhotoFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return; // user cancelled

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      // Copy to app documents directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

      await _repo.saveProfilePhotoPath(savedFile.path);
      state = state.copyWith(
        isLoading: false,
        photoPath: savedFile.path,
        successMessage: 'Foto profil berhasil diperbarui',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyimpan foto: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final profileEditProvider =
    StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  final authNotifier = ref.read(authNotifierProvider.notifier);
  return ProfileEditNotifier(repo, authNotifier);
});
