import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/dio_client.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

// Minimal valid 1x1 JPEG image bytes for attendance camera proof
final _defaultPhotoBytes = Uint8List.fromList([
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
  0x01,
  0x01,
  0x00,
  0x48,
  0x00,
  0x48,
  0x00,
  0x00,
  0xFF,
  0xDB,
  0x00,
  0x43,
  0x00,
  0x08,
  0x06,
  0x06,
  0x07,
  0x06,
  0x05,
  0x08,
  0x07,
  0x07,
  0x07,
  0x09,
  0x09,
  0x08,
  0x0A,
  0x0C,
  0x14,
  0x0D,
  0x0C,
  0x0B,
  0x0B,
  0x0C,
  0x19,
  0x12,
  0x13,
  0x0F,
  0x14,
  0x1D,
  0x1A,
  0x1F,
  0x1E,
  0x1D,
  0x1A,
  0x1C,
  0x1C,
  0x20,
  0x24,
  0x2E,
  0x27,
  0x20,
  0x22,
  0x2C,
  0x23,
  0x1C,
  0x1C,
  0x28,
  0x37,
  0x29,
  0x2C,
  0x30,
  0x31,
  0x34,
  0x34,
  0x34,
  0x1F,
  0x27,
  0x39,
  0x3D,
  0x38,
  0x32,
  0x3C,
  0x2E,
  0x33,
  0x34,
  0x32,
  0xFF,
  0xC0,
  0x00,
  0x0B,
  0x08,
  0x00,
  0x01,
  0x00,
  0x01,
  0x01,
  0x01,
  0x11,
  0x00,
  0xFF,
  0xC4,
  0x00,
  0x1F,
  0x00,
  0x00,
  0x01,
  0x05,
  0x01,
  0x01,
  0x01,
  0x01,
  0x01,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08,
  0x09,
  0x0A,
  0x0B,
  0xFF,
  0xDA,
  0x00,
  0x08,
  0x01,
  0x01,
  0x00,
  0x00,
  0x3F,
  0x00,
  0xBF,
  0x80,
  0xFF,
  0xD9,
]);

class ApiAttendanceRepository implements AttendanceRepository {
  final Dio dio;

  ApiAttendanceRepository({required this.dio});

  @override
  Future<Attendance?> getToday() async {
    try {
      final response = await dio.get('attendance/today');
      final data = response.data;
      final attData = data['attendance'] ?? data['data'];
      if (attData == null || (attData is Map && attData.isEmpty)) {
        return null;
      }
      return Attendance.fromJson(Map<String, dynamic>.from(attData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<Attendance> checkIn({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  }) async {
    try {
      final lat = latitude ?? LocationService.officeLatitude;
      final lng = longitude ?? LocationService.officeLongitude;
      final bytes = photoBytes ?? _defaultPhotoBytes;

      // Backend menggunakan multer upload (field 'photo', 'lat', 'lng')
      final formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'latitude': lat,
        'longitude': lng,
        if (accuracyMeters != null) 'accuracy': accuracyMeters,
        'is_mocked': isMocked ? 'true' : 'false',
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: 'photo.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.post('attendance/check-in', data: formData);
      final data = response.data;
      final attData = data['data'] ?? data['attendance'] ?? data;
      return Attendance.fromJson(Map<String, dynamic>.from(attData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<Attendance> checkOut({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  }) async {
    try {
      final lat = latitude ?? LocationService.officeLatitude;
      final lng = longitude ?? LocationService.officeLongitude;
      final bytes = photoBytes ?? _defaultPhotoBytes;

      final formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'latitude': lat,
        'longitude': lng,
        if (accuracyMeters != null) 'accuracy': accuracyMeters,
        'is_mocked': isMocked ? 'true' : 'false',
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: 'photo.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.post('attendance/check-out', data: formData);
      final data = response.data;
      final attData = data['data'] ?? data['attendance'] ?? data;
      return Attendance.fromJson(Map<String, dynamic>.from(attData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<List<Attendance>> getHistory() async {
    try {
      final response = await dio.get('attendance/history');
      final data = response.data;
      final listData = data['data'] ?? data;
      if (listData is List) {
        return listData
            .map(
              (item) =>
                  Attendance.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }
}
