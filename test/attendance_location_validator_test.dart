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
);

AttendanceEvidence _evidenceAtDistance(
  double meters, {
  double accuracyMeters = 1,
}) {
  return AttendanceEvidence(
    photoPath: 'attendance.jpg',
    latitude: _office.latitude + meters / 111000,
    longitude: _office.longitude,
    accuracyMeters: accuracyMeters,
  );
}

void main() {
  group('AttendanceLocationValidator', () {
    test('accepts a measured position within the 10 m limit', () {
      final distance = AttendanceLocationValidator.validateWithinRange(
        evidence: _evidenceAtDistance(4, accuracyMeters: 2),
        offices: const [_office],
      );

      expect(distance, closeTo(4, 0.2));
    });

    test('rejects a measured position farther than 10 m', () {
      expect(
        () => AttendanceLocationValidator.validateWithinRange(
          evidence: _evidenceAtDistance(12, accuracyMeters: 2),
          offices: const [_office],
        ),
        throwsA(
          isA<AttendanceLocationException>().having(
            (error) => error.message,
            'message',
            contains('12.0 m dari kantor'),
          ),
        ),
      );
    });

    test('rejects a GPS fix too imprecise to confirm the 10 m limit', () {
      expect(
        () => AttendanceLocationValidator.validateWithinRange(
          evidence: _evidenceAtDistance(8, accuracyMeters: 3),
          offices: const [_office],
        ),
        throwsA(
          isA<AttendanceLocationException>().having(
            (error) => error.message,
            'message',
            contains('Akurasi GPS belum cukup'),
          ),
        ),
      );
    });

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
