import 'package:attendance/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skip completes the splash only once', (tester) async {
    var completionCount = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onComplete: () => completionCount++)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(completionCount, 0);

    await tester.tap(find.text('Lewati'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(completionCount, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(completionCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
