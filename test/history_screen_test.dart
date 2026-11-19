import 'dart:typed_data';

import 'package:attendance/features/attendance/data/models/attendance.dart';
import 'package:attendance/features/attendance/data/models/attendance_evidence.dart';
import 'package:attendance/features/attendance/data/repositories/attendance_repository.dart';
import 'package:attendance/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:attendance/features/attendance/presentation/screens/history_screen.dart';
import 'package:attendance/features/attendance/presentation/widgets/attendance_list_item.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters history by date and can restore all attendance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final today = DateTime.now();
    final oldDate = DateTime(2000, 1, 1);
    final history = [
      Attendance(
        id: 1,
        employeeId: 1,
        workDate: _formatDate(today),
        checkInAt: today,
        rawStatus: 'tepat_waktu',
      ),
      Attendance(
        id: 2,
        employeeId: 1,
        workDate: _formatDate(oldDate),
        checkInAt: oldDate,
        rawStatus: 'terlambat',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(
            _FakeAttendanceRepository(history),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mingguan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
    expect(find.text('1 hari'), findsNWidgets(2));
    expect(find.byType(AttendanceListItem), findsNWidgets(2));
    expect(find.byIcon(Icons.history_rounded), findsNothing);

    await tester.tap(find.text('Filter tanggal'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceListItem), findsOneWidget);
    expect(find.text('Tampilkan semua'), findsOneWidget);

    await tester.tap(find.text('Tampilkan semua'));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceListItem), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _FakeAttendanceRepository implements AttendanceRepository {
  final List<Attendance> history;

  const _FakeAttendanceRepository(this.history);

  @override
  Future<Attendance?> getToday() async => null;

  @override
  Future<List<Attendance>> getHistory() async => history;

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
}
