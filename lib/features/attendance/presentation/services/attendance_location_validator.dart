import 'package:geolocator/geolocator.dart';
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

  static const maximumDistanceMeters = 10.0;

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

    final distanceMeters = activeOffices
        .map(
          (office) => Geolocator.distanceBetween(
            evidence.latitude,
            evidence.longitude,
            office.latitude,
            office.longitude,
          ),
        )
        .reduce((a, b) => a < b ? a : b);

    if (distanceMeters > maximumDistanceMeters) {
      throw AttendanceLocationException(
        'Jarak Anda ${distanceMeters.toStringAsFixed(1)} m dari kantor. '
        'Maksimal ${maximumDistanceMeters.toStringAsFixed(0)} m untuk absen.',
      );
    }

    if (distanceMeters + accuracy > maximumDistanceMeters) {
      throw AttendanceLocationException(
        'Akurasi GPS belum cukup untuk memastikan Anda dalam jarak '
        '${maximumDistanceMeters.toStringAsFixed(0)} m '
        '(terukur ${distanceMeters.toStringAsFixed(1)} m, '
        'akurasi ±${accuracy.toStringAsFixed(1)} m). '
        'Cari sinyal GPS yang lebih baik lalu coba lagi.',
      );
    }

    return distanceMeters;
  }
}
