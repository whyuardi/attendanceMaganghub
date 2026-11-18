import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileEditProvider.notifier).loadLocalProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileEditProvider);
    final user = authState.user;

    // Use local display name if available, otherwise backend name
    final displayName = (profileState.displayName?.isNotEmpty == true)
        ? profileState.displayName!
        : (user?.name ?? '');

    // Use local photo if available
    final photoPath = profileState.photoPath;
    final hasPhoto = photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync();

    // Compute initials from displayName
    String initials = '--';
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0]
            .substring(0, parts[0].length >= 2 ? 2 : 1)
            .toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.gray700),
            tooltip: 'Edit Profil',
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    currentName: displayName,
                    currentPhotoPath: photoPath,
                  ),
                ),
              );
              if (result == true) {
                // Reload local profile to reflect changes
                ref.read(profileEditProvider.notifier).loadLocalProfile();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Avatar Circle — show photo or initials
              hasPhoto
                  ? CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.gray100,
                      backgroundImage: FileImage(File(photoPath)),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.gray100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: AppTypography.itemTitle.copyWith(
                          fontSize: 24,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Name
              Text(
                displayName,
                style: AppTypography.greeting.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Employee Code (JetBrains Mono 500)
              Text(
                user?.employeeCode ?? '',
                style: AppTypography.monoSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                user?.email ?? '',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Edit Profile Button
              AppButton(
                text: 'Edit Profil',
                variant: AppButtonVariant.primary,
                height: 48,
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        currentName: displayName,
                        currentPhotoPath: photoPath,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.read(profileEditProvider.notifier).loadLocalProfile();
                  }
                },
              ),
              const SizedBox(height: 12),

              // Logout Button (Pill with red outline)
              AppButton(
                text: 'Keluar',
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
