import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workforce Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppGate(),
    );
  }
}

/// Controls the full app lifecycle:
/// Splash → Auth Check → Login or Main
class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  bool _splashDone = false;

  void _onSplashComplete() {
    setState(() => _splashDone = true);
    // Trigger auth check after splash finishes
    ref.read(authNotifierProvider.notifier).checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Show splash
    if (!_splashDone) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    // Phase 2: Auth gate
    final authState = ref.watch(authNotifierProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (authState.status) {
        AuthStatus.initial || AuthStatus.loading => Scaffold(
            key: const ValueKey('loading'),
            backgroundColor: AppColors.white,
            body: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),
        AuthStatus.authenticated => const MainNavigationScreen(
            key: ValueKey('main'),
          ),
        AuthStatus.unauthenticated => const LoginScreen(
            key: ValueKey('login'),
          ),
      },
    );
  }
}
