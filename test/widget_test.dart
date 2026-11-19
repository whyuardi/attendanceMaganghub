import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/core/error/app_error.dart';
import 'package:attendance/core/location/location_service.dart';
import 'package:attendance/core/storage/token_storage.dart';
import 'package:attendance/features/attendance/data/models/attendance.dart';
import 'package:attendance/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group(
    'Punctuality Cutoff Evaluation (08:00 WIB with 15 minutes tolerance)',
    () {
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
    },
  );

  group('Attendance Business Rules (ATT-01 to ATT-08)', () {
    late TokenStorage storage;

    setUp(() {
      storage = TokenStorage.inMemory('mock_sanctum_token_1');
    });

    test(
      'ATT-01: First check-in on workday succeeds with status and time',
      () async {
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
      },
    );

    test(
      'ATT-02: Second check-in on the same date is rejected without duplicate',
      () async {
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
          throwsA(
            isA<ValidationError>().having(
              (e) => e.message,
              'message',
              contains('Kamu sudah absen masuk hari ini pukul 08.05'),
            ),
          ),
        );
      },
    );

    test('ATT-03: OUT without IN is rejected', () async {
      final fixedTime = DateTime(2026, 11, 18, 17, 0, 0);
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => fixedTime,
        delay: Duration.zero,
      );

      expect(
        () async => await repo.checkOut(),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.message,
            'message',
            contains('Kamu belum absen masuk hari ini'),
          ),
        ),
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
        throwsA(
          isA<ValidationError>().having(
            (e) => e.message,
            'message',
            contains('Kamu sudah absen pulang hari ini pukul 17.03'),
          ),
        ),
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

      expect(() async => await repo.checkIn(), throwsA(isA<NetworkError>()));
    });
  });

  group('Day & Time-Specific Check-Out / Holiday Rules', () {
    late TokenStorage storage;

    setUp(() {
      storage = TokenStorage.inMemory('mock_sanctum_token_1');
    });

    test('Sunday: Check-in is rejected (cannot attend on Sunday)', () async {
      final sundayTime = DateTime(2026, 11, 22, 8, 0, 0); // Sunday
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => sundayTime,
        delay: Duration.zero,
      );

      expect(
        () async => await repo.checkIn(),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.message,
            'message',
            contains('Hari Minggu libur'),
          ),
        ),
      );
    });

    test('Sunday: Check-out is rejected (cannot attend on Sunday)', () async {
      final sundayTime = DateTime(2026, 11, 22, 17, 0, 0); // Sunday
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => sundayTime,
        delay: Duration.zero,
      );

      expect(
        () async => await repo.checkOut(),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.message,
            'message',
            contains('Hari Minggu libur'),
          ),
        ),
      );
    });

    test(
      'Monday—Friday: Check-out before 17:00 (e.g. 16:59:59) is rejected',
      () async {
        final mondayIn = DateTime(2026, 11, 16, 8, 0, 0); // Monday
        final mondayEarlyOut = DateTime(2026, 11, 16, 16, 59, 59);

        DateTime currentTime = mondayIn;
        final repo = MockAttendanceRepository(
          tokenStorage: storage,
          clock: () => currentTime,
          delay: Duration.zero,
        );

        await repo.checkIn();

        currentTime = mondayEarlyOut;
        expect(
          () async => await repo.checkOut(),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.message,
              'message',
              contains(
                'Absen pulang hari Senin—Jumat baru dapat dilakukan setelah pukul 17.00',
              ),
            ),
          ),
        );
      },
    );

    test(
      'Monday—Friday: Check-out at or after 17:00 (e.g. 17:00:00) succeeds',
      () async {
        final mondayIn = DateTime(2026, 11, 16, 8, 0, 0); // Monday
        final mondayValidOut = DateTime(2026, 11, 16, 17, 0, 0);

        DateTime currentTime = mondayIn;
        final repo = MockAttendanceRepository(
          tokenStorage: storage,
          clock: () => currentTime,
          delay: Duration.zero,
        );

        await repo.checkIn();

        currentTime = mondayValidOut;
        final result = await repo.checkOut();
        expect(result.checkOutAt, mondayValidOut);
        expect(result.formattedCheckOut, '17.00');
      },
    );

    test(
      'Saturday: Check-out before 16:00 (e.g. 15:59:59) is rejected',
      () async {
        final saturdayIn = DateTime(2026, 11, 21, 8, 0, 0); // Saturday
        final saturdayEarlyOut = DateTime(2026, 11, 21, 15, 59, 59);

        DateTime currentTime = saturdayIn;
        final repo = MockAttendanceRepository(
          tokenStorage: storage,
          clock: () => currentTime,
          delay: Duration.zero,
        );

        await repo.checkIn();

        currentTime = saturdayEarlyOut;
        expect(
          () async => await repo.checkOut(),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.message,
              'message',
              contains(
                'Absen pulang hari Sabtu baru dapat dilakukan setelah pukul 16.00',
              ),
            ),
          ),
        );
      },
    );

    test(
      'Saturday: Check-out at or after 16:00 (e.g. 16:00:00) succeeds',
      () async {
        final saturdayIn = DateTime(2026, 11, 21, 8, 0, 0); // Saturday
        final saturdayValidOut = DateTime(2026, 11, 21, 16, 0, 0);

        DateTime currentTime = saturdayIn;
        final repo = MockAttendanceRepository(
          tokenStorage: storage,
          clock: () => currentTime,
          delay: Duration.zero,
        );

        await repo.checkIn();

        currentTime = saturdayValidOut;
        final result = await repo.checkOut();
        expect(result.checkOutAt, saturdayValidOut);
        expect(result.formattedCheckOut, '16.00');
      },
    );
  });

  group('Office Geofencing / 25m Radius Validation', () {
    late TokenStorage storage;

    setUp(() {
      storage = TokenStorage.inMemory('mock_sanctum_token_1');
    });

    test('fresh cached position improves a poor current GPS fix', () {
      final now = DateTime.now();
      final current = Position(
        latitude: LocationService.officeLatitude + 0.0002,
        longitude: LocationService.officeLongitude,
        timestamp: now,
        accuracy: 50,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final cached = Position(
        latitude: LocationService.officeLatitude,
        longitude: LocationService.officeLongitude,
        timestamp: now.subtract(const Duration(minutes: 1)),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final fused = LocationService.fuseWithCachedPosition(current, cached);
      final distance = LocationService.calculateDistance(
        fused.latitude,
        fused.longitude,
        LocationService.officeLatitude,
        LocationService.officeLongitude,
      );

      expect(fused.accuracy, lessThan(current.accuracy));
      expect(distance, lessThan(30));
    });

    test('Distance at exact office coordinate is 0m', () {
      final distance = LocationService.calculateDistance(
        LocationService.officeLatitude,
        LocationService.officeLongitude,
        LocationService.officeLatitude,
        LocationService.officeLongitude,
      );
      expect(distance, closeTo(0.0, 0.01));
      expect(
        LocationService.isWithinRadius(
          LocationService.officeLatitude,
          LocationService.officeLongitude,
        ),
        isTrue,
      );
    });

    test('Distance within 25m radius (e.g. ~5.5m) is valid', () {
      // 0.00005 deg latitude offset is roughly 5.5 meters
      final latWithin = LocationService.officeLatitude + 0.00005;
      final lngWithin = LocationService.officeLongitude;
      final distance = LocationService.calculateDistance(
        latWithin,
        lngWithin,
        LocationService.officeLatitude,
        LocationService.officeLongitude,
      );
      expect(distance, lessThanOrEqualTo(LocationService.maxRadiusMeters));
      expect(LocationService.isWithinRadius(latWithin, lngWithin), isTrue);
    });

    test('Distance outside 25m radius (e.g. ~55m away) is invalid', () {
      // 0.0005 deg offset is roughly 55 meters
      final latOutside = LocationService.officeLatitude + 0.0005;
      final lngOutside = LocationService.officeLongitude;
      final distance = LocationService.calculateDistance(
        latOutside,
        lngOutside,
        LocationService.officeLatitude,
        LocationService.officeLongitude,
      );
      expect(distance, greaterThan(LocationService.maxRadiusMeters));
      expect(LocationService.isWithinRadius(latOutside, lngOutside), isFalse);
    });

    test(
      'Check-in outside 25m radius is rejected with ValidationError',
      () async {
        final workdayTime = DateTime(2026, 11, 16, 8, 5, 0); // Monday 08:05
        final repo = MockAttendanceRepository(
          tokenStorage: storage,
          clock: () => workdayTime,
          delay: Duration.zero,
        );

        final latFar = LocationService.officeLatitude + 0.001; // ~111m away
        final lngFar = LocationService.officeLongitude;

        expect(
          () async => await repo.checkIn(latitude: latFar, longitude: lngFar),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.message,
              'message',
              contains('Di luar jangkauan'),
            ),
          ),
        );
      },
    );

    test('Check-in within 25m radius succeeds', () async {
      final workdayTime = DateTime(2026, 11, 16, 8, 5, 0); // Monday 08:05
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => workdayTime,
        delay: Duration.zero,
      );

      // Within 5 meters of office
      final latClose = LocationService.officeLatitude + 0.00004;
      final lngClose = LocationService.officeLongitude;

      final result = await repo.checkIn(
        latitude: latClose,
        longitude: lngClose,
      );
      expect(result.workDate, '2026-11-16');
      expect(result.checkInAt, workdayTime);
    });

    test('Check-in rejects a mocked GPS position', () async {
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => DateTime(2026, 11, 16, 8, 5),
        delay: Duration.zero,
      );

      expect(
        () => repo.checkIn(
          latitude: LocationService.officeLatitude,
          longitude: LocationService.officeLongitude,
          isMocked: true,
        ),
        throwsA(
          isA<ValidationError>().having(
            (error) => error.message,
            'message',
            contains('Lokasi simulasi terdeteksi'),
          ),
        ),
      );
    });

    test(
      'Check-out outside 25m radius is rejected with ValidationError',
      () async {
        final inTime = DateTime(2026, 11, 16, 8, 0, 0);
        final outTime = DateTime(2026, 11, 16, 17, 5, 0);

        DateTime currentTime = inTime;
        final repo = MockAttendanceRepository(
          tokenStorage: storage,
          clock: () => currentTime,
          delay: Duration.zero,
        );

        // Check-in inside office
        await repo.checkIn(
          latitude: LocationService.officeLatitude,
          longitude: LocationService.officeLongitude,
        );

        // Try checking out outside 25m
        currentTime = outTime;
        final latFar = LocationService.officeLatitude + 0.001;
        final lngFar = LocationService.officeLongitude;

        expect(
          () async => await repo.checkOut(latitude: latFar, longitude: lngFar),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.message,
              'message',
              contains('Di luar jangkauan'),
            ),
          ),
        );
      },
    );

    test('Check-out within 25m radius succeeds', () async {
      final inTime = DateTime(2026, 11, 16, 8, 0, 0);
      final outTime = DateTime(2026, 11, 16, 17, 5, 0);

      DateTime currentTime = inTime;
      final repo = MockAttendanceRepository(
        tokenStorage: storage,
        clock: () => currentTime,
        delay: Duration.zero,
      );

      // Check-in inside office
      await repo.checkIn(
        latitude: LocationService.officeLatitude,
        longitude: LocationService.officeLongitude,
      );

      // Check-out inside office
      currentTime = outTime;
      final result = await repo.checkOut(
        latitude: LocationService.officeLatitude,
        longitude: LocationService.officeLongitude,
      );

      expect(result.checkOutAt, outTime);
      expect(result.formattedCheckOut, '17.05');
    });
  });
}
