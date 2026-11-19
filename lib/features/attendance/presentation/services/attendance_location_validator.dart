import 'package:geolocator/geolocator.dart';
import '../../../../core/location/location_service.dart';
import '../../data/models/attendance_evidence.dart';
import '../../../office/data/models/office.dart';

class AttendanceLocationException implements Exception {
  final String message;

  const AttendanceLocationException(this.message);

  @override
  String toString() => message;
}

class AttendanceLocationValidator {
  AttendanceLocationValidator._();

  static double validateWithinRange({
    required AttendanceEvidence evidence,
    required List<Office> offices,
  }) {
    final accuracy = evidence.accuracyMeters;
    if (accuracy == null || !accuracy.isFinite || accuracy < 0) {
      throw const AttendanceLocationException(
        'Akurasi GPS tidak tersedia. Periksa GPS dan coba lagi.',
      );
    }

    if (!evidence.latitude.isFinite ||
        !evidence.longitude.isFinite ||
        evidence.latitude < -90 ||
        evidence.latitude > 90 ||
        evidence.longitude < -180 ||
        evidence.longitude > 180) {
      throw const AttendanceLocationException(
        'Lokasi GPS tidak valid. Coba ambil lokasi kembali.',
      );
    }

    final activeOffices = offices
        .where(
          (office) =>
              office.isActive &&
              office.latitude.isFinite &&
              office.longitude.isFinite &&
              office.latitude >= -90 &&
              office.latitude <= 90 &&
              office.longitude >= -180 &&
              office.longitude <= 180,
        )
        .toList();
    if (activeOffices.isEmpty) {
      throw const AttendanceLocationException(
        'Lokasi kantor aktif tidak tersedia. Muat ulang data kantor lalu coba lagi.',
      );
    }

    final nearestOffice = activeOffices.reduce((a, b) {
      final distanceA = Geolocator.distanceBetween(
        evidence.latitude,
        evidence.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        evidence.latitude,
        evidence.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA < distanceB ? a : b;
    });
    final distanceMeters = Geolocator.distanceBetween(
      evidence.latitude,
      evidence.longitude,
      nearestOffice.latitude,
      nearestOffice.longitude,
    );
    const maximumDistanceMeters = LocationService.maxRadiusMeters;

    if (distanceMeters > maximumDistanceMeters) {
      throw AttendanceLocationException(
        'Di luar jangkauan. Jarak Anda ${distanceMeters.toStringAsFixed(1)} m dari titik pusat.',
      );
    }

    return distanceMeters;
  }
}
