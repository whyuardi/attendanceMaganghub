import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'shared/widgets/loading_view.dart';

class AttendanceApp extends ConsumerStatefulWidget {
  const AttendanceApp({super.key});

  @override
  ConsumerState<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends ConsumerState<AttendanceApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'Workforce Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: switch (authState.status) {
        AuthStatus.initial => const Scaffold(body: LoadingView()),
        AuthStatus.authenticated => const MainNavigationScreen(),
        AuthStatus.unauthenticated || AuthStatus.loading => const LoginScreen(),
      },
    );
  }
}
