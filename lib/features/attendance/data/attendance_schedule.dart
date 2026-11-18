class AttendanceSchedule {
  AttendanceSchedule._();

  static int? checkOutStartHour(DateTime date) {
    if (date.weekday == DateTime.saturday) return 16;
    if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
      return 17;
    }
    return null;
  }

  static bool canCheckOutAt(DateTime dateTime) {
    final startHour = checkOutStartHour(dateTime);
    return startHour != null && dateTime.hour >= startHour;
  }
}
