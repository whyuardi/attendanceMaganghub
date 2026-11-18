import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  final Dio dio;

  ApiAttendanceRepository({required this.dio});

  @override
  Future<Attendance?> getToday() async {
    try {
      final response = await dio.get('/attendance/today');
      final data = response.data;
      final attData = data['data'] ?? data;
      if (attData == null || (attData is Map && attData.isEmpty)) {
        return null;
      }
      return Attendance.fromJson(Map<String, dynamic>.from(attData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<Attendance> checkIn({double? latitude, double? longitude}) async {
    try {
      final response = await dio.post(
        '/attendance/check-in',
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      final data = response.data;
      final attData = data['data'] ?? data['attendance'] ?? data;
      return Attendance.fromJson(Map<String, dynamic>.from(attData as Map));
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }

  @override
  Future<Attendance> checkOut({double? latitude, double? longitude}) async {
    try {
      final response = await dio.post(
        '/attendance/check-out',
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
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
      final response = await dio.get('/attendance/history');
      final data = response.data;
      final listData = data['data'] ?? data;
      if (listData is List) {
        return listData
            .map((item) => Attendance.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw mapDioExceptionToAppError(e);
    }
  }
}
