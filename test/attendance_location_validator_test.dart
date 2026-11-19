import 'package:attendance/features/attendance/data/models/attendance_evidence.dart';
import 'package:attendance/features/attendance/presentation/services/attendance_location_validator.dart';
import 'package:attendance/features/office/data/models/office.dart';
import 'package:flutter_test/flutter_test.dart';

const _office = Office(
  id: 1,
  name: 'Kantor Pusat',
  address: 'Yogyakarta',
  latitude: -7.4296,
  longitude: 111.0095,
  radiusMeters: 25,
);

AttendanceEvidence _evidenceAtDistance(
  double meters, {
  double accuracyMeters = 1,
}) {
  return AttendanceEvidence(
    photoPath: 'attendance.jpg',
    latitude: _office.latitude + meters / 111195,
    longitude: _office.longitude,
    accuracyMeters: accuracyMeters,
  );
}

void main() {
  group('AttendanceLocationValidator', () {
    test('accepts a measured position within the 25 m limit', () {
      final distance = AttendanceLocationValidator.validateWithinRange(
        evidence: _evidenceAtDistance(4, accuracyMeters: 2),
        offices: const [_office],
      );

      expect(distance, closeTo(4, 0.2));
    });

    test('accepts a measured position just inside the 25 m limit', () {
      final distance = AttendanceLocationValidator.validateWithinRange(
        evidence: _evidenceAtDistance(24.9, accuracyMeters: 2),
        offices: const [_office],
      );

      expect(distance, closeTo(24.9, 0.2));
    });

    test('rejects a measured position farther than 25 m', () {
      expect(
        () => AttendanceLocationValidator.validateWithinRange(
          evidence: _evidenceAtDistance(26, accuracyMeters: 2),
          offices: const [_office],
        ),
        throwsA(
          isA<AttendanceLocationException>().having(
            (error) => error.message,
            'message',
            contains('26.0 m'),
          ),
        ),
      );
    });

    test(
      'accepts a position within 25 m regardless of GPS accuracy display',
      () {
        final distance = AttendanceLocationValidator.validateWithinRange(
          evidence: _evidenceAtDistance(20, accuracyMeters: 3),
          offices: const [_office],
        );

        expect(distance, closeTo(20, 0.2));
      },
    );

    test('uses the nearest active office', () {
      final nearbyOffice = Office(
        id: 2,
        name: 'Kantor Cabang',
        address: 'Yogyakarta',
        latitude: _office.latitude + 0.00002,
        longitude: _office.longitude,
      );

      final distance = AttendanceLocationValidator.validateWithinRange(
        evidence: _evidenceAtDistance(0, accuracyMeters: 2),
        offices: [_office, nearbyOffice],
      );

      expect(distance, closeTo(0, 0.2));
    });

    test('rejects when there is no active office coordinate', () {
      expect(
        () => AttendanceLocationValidator.validateWithinRange(
          evidence: _evidenceAtDistance(0),
          offices: const [
            Office(
              id: 2,
              name: 'Nonaktif',
              address: 'Yogyakarta',
              latitude: -7.4296,
              longitude: 111.0095,
              isActive: false,
            ),
          ],
        ),
        throwsA(isA<AttendanceLocationException>()),
      );
    });
  });
}
