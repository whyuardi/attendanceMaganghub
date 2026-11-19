import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../error/app_error.dart';

class LocationService {
  // Target office coordinates
  static const double officeLatitude = -7.2548218409116085;
  static const double officeLongitude = 110.1850344181774;
  static const double maxRadiusMeters = 25.0;
  static const Duration cacheValidity = Duration(minutes: 5);
  static const double cacheMaximumMovementMeters = 250.0;

  // Custom mock position for testing or simulation
  Position? mockPosition;

  LocationService({this.mockPosition});

  static Future<File> _cacheFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}location_cache.json',
    );
  }

  Future<Position?> getCachedPosition() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final timestamp = DateTime.tryParse(data['timestamp']?.toString() ?? '');
      if (timestamp == null ||
          DateTime.now().difference(timestamp).abs() > cacheValidity) {
        return null;
      }
      final latitude = (data['latitude'] as num).toDouble();
      final longitude = (data['longitude'] as num).toDouble();
      final accuracy = (data['accuracy'] as num).toDouble();
      final isMocked = data['isMocked'] == true;
      if (!latitude.isFinite ||
          !longitude.isFinite ||
          !accuracy.isFinite ||
          accuracy < 0) {
        return null;
      }
      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: isMocked,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> cachePosition(Position position) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(
        jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'isMocked': position.isMocked,
          'timestamp': position.timestamp.toIso8601String(),
        }),
        flush: true,
      );
    } catch (_) {
      // Cache failure must not block attendance.
    }
  }

  static Position fuseWithCachedPosition(Position current, Position cached) {
    final movement = calculateDistance(
      current.latitude,
      current.longitude,
      cached.latitude,
      cached.longitude,
    );
    if (movement > cacheMaximumMovementMeters) return current;

    final currentAccuracy = current.accuracy.clamp(1, 1000).toDouble();
    final cachedAccuracy = cached.accuracy.clamp(1, 1000).toDouble();
    if (cachedAccuracy >= currentAccuracy) return current;

    const cacheWeight = 0.25;
    final fusedLatitude =
        current.latitude * (1 - cacheWeight) + cached.latitude * cacheWeight;
    final fusedLongitude =
        current.longitude * (1 - cacheWeight) + cached.longitude * cacheWeight;
    final fusedAccuracy =
        (currentAccuracy * (1 - cacheWeight) + cachedAccuracy * cacheWeight)
            .clamp(0.1, 1000)
            .toDouble();

    return Position(
      latitude: fusedLatitude,
      longitude: fusedLongitude,
      timestamp: current.timestamp,
      accuracy: fusedAccuracy,
      altitude: current.altitude,
      altitudeAccuracy: current.altitudeAccuracy,
      heading: current.heading,
      headingAccuracy: current.headingAccuracy,
      speed: current.speed,
      speedAccuracy: current.speedAccuracy,
    );
  }

  /// Calculates distance in meters between two coordinates using Haversine formula
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    const double earthRadiusMeters = 6371000.0;

    final double a =
        0.5 -
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
      await cachePosition(mockPosition!);
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
        final position = Position(
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
        await cachePosition(position);
        return position;
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
      Position? bestPosition;

      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: Duration(seconds: 15),
            ),
          );
          if (bestPosition == null ||
              position.accuracy < bestPosition.accuracy) {
            bestPosition = position;
          }
          if (position.accuracy <= 20) break;
        } catch (_) {
          // Try once more so a slow or weak first GPS fix is not reused.
        }
      }

      if (bestPosition == null) {
        throw const NetworkError(
          'Gagal mendapatkan lokasi GPS baru. Pastikan GPS aktif dan berada di area terbuka, lalu coba lagi.',
        );
      }

      await cachePosition(bestPosition);
      return bestPosition;
    } catch (error) {
      if (error is ValidationError || error is NetworkError) rethrow;
      throw const NetworkError(
        'Gagal mendapatkan lokasi GPS. Pastikan berada di area terbuka dan coba lagi',
      );
    }
  }

  /// Verifies if current location is within the 25-meter office radius.
  Future<double> verifyRadius({double? latitude, double? longitude}) async {
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
        'Di luar jangkauan. Jarak Anda $distStr dari titik pusat.',
      );
    }

    return distance;
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
