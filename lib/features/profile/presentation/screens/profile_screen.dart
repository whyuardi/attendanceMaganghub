import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Avatar Circle (gray100 bg, initials)
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user?.initials ?? '--',
                  style: AppTypography.itemTitle.copyWith(
                    fontSize: 20,
                    color: AppColors.gray700,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                user?.name ?? '',
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
