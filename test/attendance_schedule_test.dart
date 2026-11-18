import 'package:attendance/features/attendance/data/attendance_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceSchedule.canCheckOutAt', () {
    test('weekdays open at 17:00', () {
      expect(
        AttendanceSchedule.canCheckOutAt(DateTime(2026, 11, 18, 16, 59, 59)),
        isFalse,
      );
      expect(
        AttendanceSchedule.canCheckOutAt(DateTime(2026, 11, 18, 17)),
        isTrue,
      );
    });

    test('Saturday opens at 16:00', () {
      expect(
        AttendanceSchedule.canCheckOutAt(DateTime(2026, 11, 21, 15, 59, 59)),
        isFalse,
      );
      expect(
        AttendanceSchedule.canCheckOutAt(DateTime(2026, 11, 21, 16)),
        isTrue,
      );
    });

    test('Sunday never opens', () {
      expect(
        AttendanceSchedule.canCheckOutAt(DateTime(2026, 11, 22, 23, 59)),
        isFalse,
      );
    });
  });
}
