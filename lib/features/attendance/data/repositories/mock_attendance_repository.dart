import 'dart:typed_data';
import '../../../../core/error/app_error.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final TokenStorage tokenStorage;
  final Duration delay;
  final DateTime Function() clock;

  // In-memory attendance database keyed by employeeId
  // For each employee, store attendance records
  final Map<int, List<Attendance>> _database = {};

  // Testing hooks for simulating error challenges
  bool simulateTimeout = false;
  bool simulateUnauthorized = false;

  MockAttendanceRepository({
    required this.tokenStorage,
    DateTime Function()? clock,
    this.delay = const Duration(milliseconds: 600),
  }) : clock = clock ?? DateTime.now {
    _seedDummyData();
  }

  void _seedDummyData() {
    // Seed dummy history for employee 1 (Andi Pratama)
    _database[1] = [
      Attendance(
        id: 101,
        employeeId: 1,
        workDate: '2026-11-14',
        checkInAt: DateTime.parse('2026-11-14T08:21:00+07:00'),
        checkOutAt: DateTime.parse('2026-11-14T17:15:00+07:00'),
        rawStatus: 'terlambat',
      ),
      Attendance(
        id: 102,
        employeeId: 1,
        workDate: '2026-11-13',
        checkInAt: DateTime.parse('2026-11-13T07:48:00+07:00'),
        checkOutAt: DateTime.parse('2026-11-13T17:00:00+07:00'),
        rawStatus: 'tepat_waktu',
      ),
      Attendance(
        id: 103,
        employeeId: 1,
        workDate: '2026-11-12',
        checkInAt: DateTime.parse('2026-11-12T07:55:00+07:00'),
        checkOutAt: DateTime.parse('2026-11-12T17:02:00+07:00'),
        rawStatus: 'tepat_waktu',
      ),
    ];
  }

  Future<int> _getCurrentEmployeeId() async {
    final token = await tokenStorage.getToken();
    if (token == null || simulateUnauthorized) {
      // ATT-07: Token hilang atau tidak valid
      throw const UnauthorizedError();
    }
    // Expected token format: mock_sanctum_token_<id>
    final idStr = token.replaceAll('mock_sanctum_token_', '');
    return int.tryParse(idStr) ?? 1;
  }

  String _formatWorkDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  /// Evaluates attendance punctuality on the simulated server
  /// Cutoff: 08:15:00 is on time; 08:15:01 is late.
  String evaluateStatus(DateTime dt) {
    // 08:00 WIB with 15 minutes tolerance -> up to 08:15:00 is tepat_waktu
    if (dt.hour < 8) {
      return 'tepat_waktu';
    } else if (dt.hour == 8) {
      if (dt.minute < 15) {
        return 'tepat_waktu';
      } else if (dt.minute == 15 && dt.second == 0) {
        return 'tepat_waktu';
      } else {
        return 'terlambat';
      }
    } else {
      return 'terlambat';
    }
  }

  @override
  Future<Attendance?> getToday() async {
    await Future.delayed(delay);

    if (simulateTimeout) {
      // ATT-08
      throw const NetworkError();
    }

    final employeeId = await _getCurrentEmployeeId();
    final todayStr = _formatWorkDate(clock());

    final list = _database.putIfAbsent(employeeId, () => []);
    try {
      return list.firstWhere((a) => a.workDate == todayStr);
    } catch (_) {
      return null;
    }
  }

  void _validateLocationRadius(double? lat, double? lng) {
    if (lat == null && lng == null) {
      return; // If omitted in test/mock, skip or assume within office
    }
    final userLat = lat ?? LocationService.officeLatitude;
    final userLng = lng ?? LocationService.officeLongitude;
    final distance = LocationService.calculateDistance(
      userLat,
      userLng,
      LocationService.officeLatitude,
      LocationService.officeLongitude,
    );
    if (distance > LocationService.maxRadiusMeters) {
      final distStr = distance >= 1000
          ? '${(distance / 1000).toStringAsFixed(1)} km'
          : '${distance.toStringAsFixed(1)} m';
      throw ValidationError(
        'Di luar jangkauan. Jarak Anda $distStr dari titik pusat.',
      );
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
    await Future.delayed(delay);

    if (simulateTimeout) {
      // ATT-08
      throw const NetworkError();
    }

    if (isMocked) {
      throw const ValidationError(
        'Lokasi simulasi terdeteksi. Matikan aplikasi fake GPS untuk absen.',
      );
    }

    // Validasi radius lokasi (maksimal 25 meter)
    _validateLocationRadius(latitude, longitude);

    final employeeId = await _getCurrentEmployeeId();
    final now = clock();

    // Validasi hari Minggu: tidak bisa absen sama sekali
    if (now.weekday == DateTime.sunday) {
      throw const ValidationError(
        'Hari Minggu libur. Tidak dapat melakukan absensi',
      );
    }

    final todayStr = _formatWorkDate(now);
    final list = _database.putIfAbsent(employeeId, () => []);

    final existingIndex = list.indexWhere((a) => a.workDate == todayStr);
    if (existingIndex != -1) {
      final existing = list[existingIndex];
      if (existing.checkInAt != null) {
        // ATT-02: IN kedua pada tanggal yang sama ditolak tanpa duplikasi
        final timeStr = _formatTime(existing.checkInAt!);
        throw ValidationError('Kamu sudah absen masuk hari ini pukul $timeStr');
      }
    }

    // ATT-01: IN pertama berhasil
    final status = evaluateStatus(now);
    final newAttendance = Attendance(
      id: DateTime.now().millisecondsSinceEpoch,
      employeeId: employeeId,
      workDate: todayStr,
      checkInAt: now,
      checkOutAt: null,
      rawStatus: status,
    );

    if (existingIndex != -1) {
      list[existingIndex] = newAttendance;
    } else {
      list.insert(0, newAttendance);
    }

    return newAttendance;
  }

  @override
  Future<Attendance> checkOut({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    bool isMocked = false,
    Uint8List? photoBytes,
  }) async {
    await Future.delayed(delay);

    if (simulateTimeout) {
      // ATT-08
      throw const NetworkError();
    }

    if (isMocked) {
      throw const ValidationError(
        'Lokasi simulasi terdeteksi. Matikan aplikasi fake GPS untuk absen.',
      );
    }

    // Validasi radius lokasi (maksimal 25 meter)
    _validateLocationRadius(latitude, longitude);

    final employeeId = await _getCurrentEmployeeId();
    final now = clock();

    // Validasi hari Minggu: tidak bisa absen sama sekali
    if (now.weekday == DateTime.sunday) {
      throw const ValidationError(
        'Hari Minggu libur. Tidak dapat melakukan absensi',
      );
    }

    final todayStr = _formatWorkDate(now);
    final list = _database.putIfAbsent(employeeId, () => []);

    final existingIndex = list.indexWhere((a) => a.workDate == todayStr);

    // ATT-03: OUT tanpa IN ditolak
    if (existingIndex == -1 || list[existingIndex].checkInAt == null) {
      throw const ValidationError('Kamu belum absen masuk hari ini');
    }

    final current = list[existingIndex];

    // ATT-05: OUT kedua ditolak
    if (current.checkOutAt != null) {
      final timeStr = _formatTime(current.checkOutAt!);
      throw ValidationError('Kamu sudah absen pulang hari ini pukul $timeStr');
    }

    // Validasi jam absen pulang:
    // Senin - Jumat: baru bisa setelah pukul 17.00
    // Sabtu: baru bisa setelah pukul 16.00
    if (now.weekday >= DateTime.monday && now.weekday <= DateTime.friday) {
      if (now.hour < 17) {
        throw const ValidationError(
          'Absen pulang hari Senin—Jumat baru dapat dilakukan setelah pukul 17.00',
        );
      }
    } else if (now.weekday == DateTime.saturday) {
      if (now.hour < 16) {
        throw const ValidationError(
          'Absen pulang hari Sabtu baru dapat dilakukan setelah pukul 16.00',
        );
      }
    }

    // ATT-04: OUT setelah IN dan belum OUT berhasil
    final updated = current.copyWith(checkOutAt: now);
    list[existingIndex] = updated;
    return updated;
  }

  @override
  Future<List<Attendance>> getHistory() async {
    await Future.delayed(delay);

    if (simulateTimeout) {
      // ATT-08
      throw const NetworkError();
    }

    final employeeId = await _getCurrentEmployeeId();
    final list = _database.putIfAbsent(employeeId, () => []);
    // Return sorted descending by workDate
    final sorted = List<Attendance>.from(list);
    sorted.sort((a, b) => b.workDate.compareTo(a.workDate));
    return sorted;
  }
}
