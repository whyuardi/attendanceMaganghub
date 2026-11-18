/// Abstract profile repository for employee self-service actions.
abstract class ProfileRepository {
  /// Update display name locally (backend lacks employee self-service endpoint).
  Future<void> saveDisplayName(String name);

  /// Get locally stored display name (returns null if not set).
  Future<String?> getDisplayName();

  /// Change password via backend.
  /// Throws if old password is wrong or backend rejects.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Save profile photo path locally.
  Future<void> saveProfilePhotoPath(String path);

  /// Get locally stored profile photo path.
  Future<String?> getProfilePhotoPath();

  /// Clear all local profile data (on logout).
  Future<void> clearLocalProfile();
}
