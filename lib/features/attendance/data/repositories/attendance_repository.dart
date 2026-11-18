import '../models/attendance.dart';

abstract class AttendanceRepository {
  Future<Attendance?> getToday();
  Future<Attendance> checkIn({double? latitude, double? longitude});
  Future<Attendance> checkOut({double? latitude, double? longitude});
  Future<List<Attendance>> getHistory();
}
