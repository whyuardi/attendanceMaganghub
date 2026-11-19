import 'package:attendance/features/office/data/models/office.dart';
import 'package:attendance/features/office/presentation/providers/office_provider.dart';
import 'package:attendance/features/office/presentation/screens/office_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows office details and the Google Maps action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          officeProvider.overrideWith(
            (ref) async => const Office(
              id: 1,
              name: 'Kantor Pusat',
              address: 'Jl. Contoh No. 10, Yogyakarta',
              latitude: -7.4296,
              longitude: 111.0095,
              radiusMeters: 150,
            ),
          ),
        ],
        child: const MaterialApp(home: OfficeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kantor Anda'), findsOneWidget);
    expect(find.text('Kantor Pusat'), findsOneWidget);
    expect(find.text('Jl. Contoh No. 10, Yogyakarta'), findsOneWidget);
    expect(find.text('-7.4296, 111.0095'), findsOneWidget);
    expect(find.text('Buka di Google Maps'), findsOneWidget);
  });
}
