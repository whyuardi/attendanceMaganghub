import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final displayName = user?.name.trim() ?? '';
    final name = displayName.isEmpty ? 'Pengguna' : displayName;
    final nameParts = displayName.isEmpty
        ? const <String>[]
        : displayName.split(RegExp(r'\s+'));
    final initials = nameParts.isEmpty
        ? '--'
        : nameParts.length > 1
        ? '${nameParts.first[0]}${nameParts[1][0]}'.toUpperCase()
        : nameParts.first
              .substring(0, nameParts.first.length >= 2 ? 2 : 1)
              .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AKUN ANDA',
                    style: AppTypography.monoSecondary.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profil',
                    style: AppTypography.greeting.copyWith(
                      color: AppColors.sidebarBg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Informasi akunmu.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A061A14),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.cardBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: AppTypography.itemTitle.copyWith(
                          color: AppColors.sidebarBg,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: AppTypography.greeting.copyWith(
                        color: AppColors.sidebarBg,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.employeeCode ?? '',
                      textAlign: TextAlign.center,
                      style: AppTypography.monoSecondary.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A061A14),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INFORMASI AKUN',
                      style: AppTypography.monoSecondary.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileInfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: user?.email ?? '',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.gray100,
                      ),
                    ),
                    _ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Kode pegawai',
                      value: user?.employeeCode ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sidebarBg,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Keluar',
                        style: AppTypography.button.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.sidebarBg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                style: AppTypography.itemTitle.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
