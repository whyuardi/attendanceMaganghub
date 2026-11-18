import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String currentName;
  final String? currentPhotoPath;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    this.currentPhotoPath,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);

    // Load local profile data
    Future.microtask(() {
      ref.read(profileEditProvider.notifier).loadLocalProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileEditProvider);

    // Listen for success/error snackbars
    ref.listen<ProfileEditState>(profileEditProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: const StadiumBorder(),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Clear password fields on success
        if (next.successMessage!.contains('Password')) {
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.statusRed,
            behavior: SnackBarBehavior.floating,
            shape: const StadiumBorder(),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });

    // Current photo: from state or widget prop
    final photoPath = profileState.photoPath?.isNotEmpty == true
        ? profileState.photoPath
        : widget.currentPhotoPath;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Photo ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: profileState.isLoading
                        ? null
                        : () {
                            ref
                                .read(profileEditProvider.notifier)
                                .pickPhotoFromGallery();
                          },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.gray100,
                          backgroundImage: photoPath != null &&
                                  photoPath.isNotEmpty &&
                                  File(photoPath).existsSync()
                              ? FileImage(File(photoPath))
                              : null,
                          child: (photoPath == null ||
                                  photoPath.isEmpty ||
                                  !File(photoPath).existsSync())
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.gray700,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Ketuk untuk ubah foto',
                    style: AppTypography.bodyMedium,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Name Section ───────────────────────────────
                _sectionLabel('Nama'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _nameController,
                  hintText: 'Masukkan nama baru',
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Simpan Nama',
                  isLoading: profileState.isLoading,
                  onPressed: () {
                    ref
                        .read(profileEditProvider.notifier)
                        .updateDisplayName(_nameController.text);
                  },
                  height: 48,
                ),

                const SizedBox(height: 36),

                // ── Divider ────────────────────────────────────
                const Divider(color: AppColors.gray100, thickness: 1),
                const SizedBox(height: 24),

                // ── Password Section ───────────────────────────
                _sectionLabel('Ubah Password'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _oldPasswordController,
                  hintText: 'Password lama',
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _newPasswordController,
                  hintText: 'Password baru',
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Konfirmasi password baru',
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Ubah Password',
                  isLoading: profileState.isLoading,
                  onPressed: () {
                    ref
                        .read(profileEditProvider.notifier)
                        .changePassword(
                          oldPassword: _oldPasswordController.text,
                          newPassword: _newPasswordController.text,
                          confirmPassword: _confirmPasswordController.text,
                        );
                  },
                  height: 48,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.itemTitle.copyWith(
        fontSize: 16,
        color: AppColors.black,
      ),
    );
  }
}
