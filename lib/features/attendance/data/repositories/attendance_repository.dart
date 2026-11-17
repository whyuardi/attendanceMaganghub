import '../models/attendance.dart';

abstract class AttendanceRepository {
  Future<Attendance?> getToday();
  Future<Attendance> checkIn();
  Future<Attendance> checkOut();
  Future<List<Attendance>> getHistory();
}
