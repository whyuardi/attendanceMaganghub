import 'dart:typed_data';

import 'package:attendance/features/attendance/data/models/attendance.dart';
import 'package:attendance/features/attendance/data/models/attendance_evidence.dart';
import 'package:attendance/features/attendance/data/repositories/attendance_repository.dart';
import 'package:attendance/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:attendance/features/attendance/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows dash for check-in before attendance and live clock separately',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(
              _FakeAttendanceRepository(null),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(r'^\d{2}\.\d{2}$').hasMatch(widget.data ?? ''),
        ),
        findsOneWidget,
      );
      expect(find.text('--.--'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('keeps the recorded check-in time after checking in', (
    tester,
  ) async {
    final checkInAt = DateTime(2026, 11, 18, 8, 5);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(
            _FakeAttendanceRepository(
              Attendance(
                id: 1,
                employeeId: 1,
                workDate: '2026-11-18',
                checkInAt: checkInAt,
                rawStatus: 'tepat_waktu',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('08.05'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows duplicate check-in message for selected IN', (
    tester,
  ) async {
    final checkInAt = DateTime(2026, 11, 18, 8, 5);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(
            _FakeAttendanceRepository(
              Attendance(
                id: 1,
                employeeId: 1,
                workDate: '2026-11-18',
                checkInAt: checkInAt,
                rawStatus: 'tepat_waktu',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('attendance-action-dropdown')),
    );
    await tester.tap(find.byKey(const Key('attendance-action-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IN - Absen masuk'));
    await tester.pumpAndSettle();

    final actionButton = find.byKey(const Key('attendance-action-button'));
    await tester.ensureVisible(actionButton);
    await tester.tap(actionButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Kamu sudah absen masuk hari ini pukul 08.05'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows duplicate check-out message when OUT is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(
            _FakeAttendanceRepository(
              Attendance(
                id: 1,
                employeeId: 1,
                workDate: '2026-11-18',
                checkInAt: DateTime(2026, 11, 18, 8, 5),
                checkOutAt: DateTime(2026, 11, 18, 17, 15),
                rawStatus: 'tepat_waktu',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final actionButton = find.byKey(const Key('attendance-action-button'));
    await tester.ensureVisible(actionButton);
    await tester.tap(actionButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Kamu sudah absen pulang hari ini pukul 17.15'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FakeAttendanceRepository implements AttendanceRepository {
  final Attendance? attendance;

  const _FakeAttendanceRepository(this.attendance);

  @override
  Future<Attendance?> getToday() async => attendance;

  @override
  Future<Attendance> checkIn({
    AttendanceEvidence? evidence,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  }) => throw UnimplementedError();

  @override
  Future<Attendance> checkOut({
    AttendanceEvidence? evidence,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  }) => throw UnimplementedError();

  @override
  Future<List<Attendance>> getHistory() => throw UnimplementedError();
}
