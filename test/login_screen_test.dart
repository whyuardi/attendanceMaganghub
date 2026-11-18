import 'package:attendance/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the white login layout and validates required fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('Workforce'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });
}
