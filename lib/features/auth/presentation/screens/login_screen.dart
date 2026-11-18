import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authNotifierProvider.notifier)
          .login(_emailController.text, _passwordController.text);
    }
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: _border(AppColors.gray300),
      enabledBorder: _border(AppColors.gray300),
      focusedBorder: _border(AppColors.sidebarBg, width: 1.5),
      errorBorder: _border(AppColors.statusRed),
      focusedErrorBorder: _border(AppColors.statusRed, width: 1.5),
      errorStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.statusRed,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          color: AppColors.sidebarBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x16061A14),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/app-logo.png',
                            fit: BoxFit.cover,
                            semanticLabel: 'Ethes Tech',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Workforce',
                      textAlign: TextAlign.center,
                      style: AppTypography.appTitle.copyWith(
                        color: AppColors.sidebarBg,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Attendance',
                      textAlign: TextAlign.center,
                      style: AppTypography.appTitle.copyWith(
                        color: AppColors.textDark,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Masuk untuk melanjutkan ke akun Anda',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.gray100),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C061A14),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textDark,
                            ),
                            cursorColor: AppColors.sidebarBg,
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.mail_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textDark,
                            ),
                            cursorColor: AppColors.sidebarBg,
                            decoration: _inputDecoration(
                              label: 'Kata sandi',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              authState.errorMessage!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.statusRed,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sidebarBg,
                                disabledBackgroundColor: AppColors.gray300,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryGold,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Masuk',
                                      style: AppTypography.button.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
