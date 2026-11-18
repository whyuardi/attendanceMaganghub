import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../error/app_error.dart';

class LocationService {
  // Target office coordinates
  static const double officeLatitude = -7.254870;
  static const double officeLongitude = 110.185027;
  static const double maxRadiusMeters = 15.0;

  // Custom mock position for testing or simulation
  Position? mockPosition;

  LocationService({this.mockPosition});

  /// Calculates distance in meters between two coordinates using Haversine formula
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    const double earthRadiusMeters = 6371000.0;

    final double a = 0.5 -
        cos((endLatitude - startLatitude) * p) / 2 +
        cos(startLatitude * p) *
            cos(endLatitude * p) *
            (1 - cos((endLongitude - startLongitude) * p)) /
            2;

    return 2 * earthRadiusMeters * asin(sqrt(a));
  }

  /// Checks whether coordinates are within the maximum allowed radius
  static bool isWithinRadius(
    double userLat,
    double userLng, {
    double targetLat = officeLatitude,
    double targetLng = officeLongitude,
    double maxRadius = maxRadiusMeters,
  }) {
    final distance = calculateDistance(userLat, userLng, targetLat, targetLng);
    return distance <= maxRadius;
  }

  /// Gets the current user device position
  Future<Position> getCurrentPosition() async {
    // If mock position is set (e.g. for unit testing or specific mock flow)
    if (mockPosition != null) {
      return mockPosition!;
    }

    // In mock mode without explicit device GPS, provide office coordinate by default
    // so emulator can run smoothly unless specifically testing out-of-range
    if (AppConfig.useMock) {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (_) {
        serviceEnabled = false;
      }

      if (!serviceEnabled) {
        // Return default position inside office radius for mock mode
        return Position(
          latitude: officeLatitude,
          longitude: officeLongitude,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ValidationError(
        'Layanan lokasi (GPS) tidak aktif. Silakan aktifkan GPS pada perangkat',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const ValidationError(
          'Izin lokasi ditolak. Izin lokasi diperlukan untuk verifikasi kehadiran',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const ValidationError(
        'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk mengizinkan lokasi',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      throw const NetworkError(
        'Gagal mendapatkan lokasi GPS. Pastikan berada di area terbuka dan coba lagi',
      );
    }
  }

  /// Verifies if current location is within office radius (<= 15 meters).
  /// Throws [ValidationError] if outside 15m radius.
  Future<double> verifyRadius({
    double? latitude,
    double? longitude,
  }) async {
    final double userLat;
    final double userLng;

    if (latitude != null && longitude != null) {
      userLat = latitude;
      userLng = longitude;
    } else {
      final pos = await getCurrentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;
    }

    final distance = calculateDistance(
      userLat,
      userLng,
      officeLatitude,
      officeLongitude,
    );

    if (distance > maxRadiusMeters) {
      final distStr = distance >= 1000
          ? '${(distance / 1000).toStringAsFixed(1)} km'
          : '${distance.toStringAsFixed(1)} m';

      throw ValidationError(
        'Kamu berada di luar radius kantor ($distStr). Absen hanya dapat dilakukan dalam radius maksimal 15 m',
      );
    }

    return distance;
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
