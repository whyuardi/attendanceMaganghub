import 'dart:typed_data';
import '../models/attendance.dart';
import '../models/attendance_evidence.dart';

abstract class AttendanceRepository {
  Future<Attendance?> getToday();
  Future<Attendance> checkIn({
    AttendanceEvidence? evidence,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  });
  Future<Attendance> checkOut({
    AttendanceEvidence? evidence,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  });
  Future<List<Attendance>> getHistory();
}
