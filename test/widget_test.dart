import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/core/error/app_error.dart';
import 'package:attendance/core/storage/token_storage.dart';
import 'package:attendance/features/attendance/data/models/attendance.dart';
import 'package:attendance/features/attendance/data/repositories/mock_attendance_repository.dart';

void main() {
  group('Punctuality Cutoff Evaluation (08:00 WIB with 15 minutes tolerance)', () {
    late MockAttendanceRepository repo;
    late TokenStorage storage;

    setUp(() {
      storage = TokenStorage.inMemory('mock_sanctum_token_1');
      repo = MockAttendanceRepository(
        tokenStorage: storage,
        delay: Duration.zero,
      );
    });

    test('07:55:00 is on time (tepat_waktu)', () {
      final time = DateTime(2026, 11, 17, 7, 55, 0);
      expect(repo.evaluateStatus(time), 'tepat_waktu');
    });

    test('08:14:59 is on time (tepat_waktu)', () {
      final time = DateTime(2026, 11, 17, 8, 14, 59);
      expect(repo.evaluateStatus(time), 'tepat_waktu');
    });

    test('08:15:00 exact boundary is STILL on time (tepat_waktu)', () {
      final time = DateTime(2026, 11, 17, 8, 15, 0);
      expect(repo.evaluateStatus(time), 'tepat_waktu');
    });

    test('08:15:01 boundary cutoff is LATE (terlambat)', () {
      final time = DateTime(2026, 11, 17, 8, 15, 1);
      expect(repo.evaluateStatus(time), 'terlambat');
    });

    test('08:16:00 is LATE (terlambat)', () {
      final time = DateTime(2026, 11, 17, 8, 16, 0);
      expect(repo.evaluateStatus(time), 'terlambat');
    });
  });

  group('Attendance Business Rules (ATT-01 to ATT-08)', () {
    late TokenStorage storage;

    setUp(() {
      storage = TokenStorage.inMemory('mock_sanctum_token_1');
    });

    test('ATT-01: First check-in on workday succeeds with status and time', () async {
      final fixedTime = DateTime(2026, 11, 17, 8, 5, 0);
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => fixedTime,
        delay: Duration.zero,
      );

      final attendance = await repo.checkIn();
      expect(attendance.workDate, '2026-11-17');
      expect(attendance.checkInAt, fixedTime);
      expect(attendance.checkOutAt, isNull);
      expect(attendance.rawStatus, 'tepat_waktu');
      expect(attendance.status, AttendanceStatus.tepatWaktu);
      expect(attendance.formattedCheckIn, '08.05');
    });

    test('ATT-02: Second check-in on the same date is rejected without duplicate', () async {
      final fixedTime = DateTime(2026, 11, 17, 8, 5, 0);
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => fixedTime,
        delay: Duration.zero,
      );

      // First check-in
      await repo.checkIn();

      // Second check-in attempt
      expect(
        () async => await repo.checkIn(),
        throwsA(isA<ValidationError>().having(
          (e) => e.message,
          'message',
          contains('Kamu sudah absen masuk hari ini pukul 08.05'),
        )),
      );
    });

    test('ATT-03: OUT without IN is rejected', () async {
      final fixedTime = DateTime(2026, 11, 18, 17, 0, 0);
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => fixedTime,
        delay: Duration.zero,
      );

      expect(
        () async => await repo.checkOut(),
        throwsA(isA<ValidationError>().having(
          (e) => e.message,
          'message',
          contains('Kamu belum absen masuk hari ini'),
        )),
      );
    });

    test('ATT-04: OUT after IN and before OUT succeeds', () async {
      final inTime = DateTime(2026, 11, 19, 8, 0, 0);
      final outTime = DateTime(2026, 11, 19, 17, 3, 0);

      DateTime currentTime = inTime;
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => currentTime,
        delay: Duration.zero,
      );

      // Check-in
      final checkInResult = await repo.checkIn();
      expect(checkInResult.checkInAt, inTime);
      expect(checkInResult.checkOutAt, isNull);

      // Check-out
      currentTime = outTime;
      final checkOutResult = await repo.checkOut();
      expect(checkOutResult.checkInAt, inTime);
      expect(checkOutResult.checkOutAt, outTime);
      expect(checkOutResult.formattedCheckOut, '17.03');
    });

    test('ATT-05: Second OUT is rejected', () async {
      final inTime = DateTime(2026, 11, 20, 8, 0, 0);
      final outTime = DateTime(2026, 11, 20, 17, 3, 0);

      DateTime currentTime = inTime;
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => currentTime,
        delay: Duration.zero,
      );

      await repo.checkIn();
      currentTime = outTime;
      await repo.checkOut();

      // Second checkout
      expect(
        () async => await repo.checkOut(),
        throwsA(isA<ValidationError>().having(
          (e) => e.message,
          'message',
          contains('Kamu sudah absen pulang hari ini pukul 17.03'),
        )),
      );
    });

    test('ATT-07: Missing/invalid token throws UnauthorizedError', () async {
      final emptyStorage = TokenStorage.inMemory(null);
      final repo = MockAttendanceRepository(
        tokenStorage: emptyStorage,
        delay: Duration.zero,
      );

      expect(
        () async => await repo.checkIn(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('ATT-08: Network error/timeout throws NetworkError', () async {
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        delay: Duration.zero,
      );
      repo.simulateTimeout = true;

      expect(
        () async => await repo.checkIn(),
        throwsA(isA<NetworkError>()),
      );
    });
  });
}
