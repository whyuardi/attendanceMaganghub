enum AttendanceStatus { tepatWaktu, terlambat, belumAbsen }

class Attendance {
  final int id;
  final int employeeId;
  final String workDate; // YYYY-MM-DD
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String rawStatus;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.workDate,
    this.checkInAt,
    this.checkOutAt,
    required this.rawStatus,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toLocal();
        }
      }
      return null;
    }

    final inAt = parseDate(json['check_in_at']);
    final outAt = parseDate(json['check_out_at']);

    final rawStatusValue = json['status'] ?? json['state'] ?? json['attendance_status'];
    String statusStr = rawStatusValue?.toString() ?? '';
    if (statusStr.isEmpty || statusStr == 'null') {
      if (inAt != null) {
        final hour = inAt.hour;
        final minute = inAt.minute;
        statusStr = (hour > 8 || (hour == 8 && minute > 15)) ? 'terlambat' : 'tepat_waktu';
      } else {
        statusStr = 'belum_absen';
      }
    }

    return Attendance(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      employeeId: json['employee_id'] is int
          ? json['employee_id'] as int
          : int.tryParse(json['employee_id']?.toString() ?? '0') ?? 0,
      workDate: json['work_date'] as String? ?? '',
      checkInAt: inAt,
      checkOutAt: outAt,
      rawStatus: statusStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'work_date': workDate,
      'check_in_at': checkInAt?.toIso8601String(),
      'check_out_at': checkOutAt?.toIso8601String(),
      'status': rawStatus,
    };
  }

  AttendanceStatus get status {
    final s = rawStatus.toLowerCase().trim();
    if (s.contains('terlambat') || s == 'late') {
      return AttendanceStatus.terlambat;
    }
    if (s.contains('tepat') ||
        s == 'on_time' ||
        s.contains('hadir') ||
        s == 'masuk' ||
        s == 'present' ||
        s == 'sudah_in' ||
        s == 'sudah_out') {
      return AttendanceStatus.tepatWaktu;
    }

    // Jika karyawan sudah absen masuk, evaluasi berdasarkan waktu jam masuk
    if (checkInAt != null) {
      final hour = checkInAt!.hour;
      final minute = checkInAt!.minute;
      if (hour > 8 || (hour == 8 && minute > 15)) {
        return AttendanceStatus.terlambat;
      }
      return AttendanceStatus.tepatWaktu;
    }

    return AttendanceStatus.belumAbsen;
  }

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.tepatWaktu:
        return 'Tepat waktu';
      case AttendanceStatus.terlambat:
        return 'Terlambat';
      case AttendanceStatus.belumAbsen:
        return 'Belum absen';
    }
  }

  /// Formatted time e.g. "07.52" or "--.--" in local timezone (WIB)
  String get formattedCheckIn {
    if (checkInAt == null) return '--.--';
    final dt = checkInAt!.toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  String get formattedCheckOut {
    if (checkOutAt == null) return '--.--';
    final dt = checkOutAt!.toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  /// Formatted date in Indonesian e.g. "Sen, 17 Nov 2026"
  String get formattedDate {
    DateTime? date;
    if (checkInAt != null) {
      date = checkInAt;
    } else {
      date = DateTime.tryParse(workDate);
    }
    if (date == null) return workDate;

    // Indonesian day and month names
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  Attendance copyWith({
    int? id,
    int? employeeId,
    String? workDate,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? rawStatus,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      workDate: workDate ?? this.workDate,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      rawStatus: rawStatus ?? this.rawStatus,
    );
  }
}
