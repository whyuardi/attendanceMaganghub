import 'dart:typed_data';
import '../models/attendance.dart';

abstract class AttendanceRepository {
  Future<Attendance?> getToday();
  Future<Attendance> checkIn({double? latitude, double? longitude, Uint8List? photoBytes});
  Future<Attendance> checkOut({double? latitude, double? longitude, Uint8List? photoBytes});
  Future<List<Attendance>> getHistory();
}
