import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/attendance.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/api_attendance_repository.dart';
import '../../data/repositories/mock_attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  if (AppConfig.useMock) {
    final tokenStorage = ref.watch(tokenStorageProvider);
    return MockAttendanceRepository(tokenStorage: tokenStorage);
  } else {
    final dio = ref.watch(dioProvider);
    return ApiAttendanceRepository(dio: dio);
  }
});

class TodayAttendanceState {
  final bool isLoading;
  final bool isSubmitting;
  final Attendance? attendance;
  final String? errorMessage;
  final String? successMessage;

  const TodayAttendanceState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.attendance,
    this.errorMessage,
    this.successMessage,
  });

  TodayAttendanceState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    Attendance? attendance,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TodayAttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      attendance: attendance ?? this.attendance,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TodayAttendanceNotifier extends StateNotifier<TodayAttendanceState> {
  final AttendanceRepository _repository;
  final LocationService _locationService;

  TodayAttendanceNotifier(
    this._repository,
    this._locationService,
  ) : super(const TodayAttendanceState(isLoading: true)) {
    loadToday();
  }

  Future<void> loadToday() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final today = await _repository.getToday();
      state = state.copyWith(
        isLoading: false,
        attendance: today,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> checkIn({double? latitude, double? longitude}) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final double lat;
      final double lng;
      if (latitude != null && longitude != null) {
        lat = latitude;
        lng = longitude;
      } else {
        final pos = await _locationService.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }

      final result = await _repository.checkIn(latitude: lat, longitude: lng);
      // ATT-01: Simpan status dan tampilkan jam
      state = state.copyWith(
        isSubmitting: false,
        attendance: result,
        successMessage: 'Absen masuk tercatat ${result.formattedCheckIn}',
      );
      return true;
    } catch (e) {
      // ATT-08: JANGAN tampilkan sukses palsu dan JANGAN ubah status lokal sebelum server membalas
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> checkOut({double? latitude, double? longitude}) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final double lat;
      final double lng;
      if (latitude != null && longitude != null) {
        lat = latitude;
        lng = longitude;
      } else {
        final pos = await _locationService.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }

      final result = await _repository.checkOut(latitude: lat, longitude: lng);
      // ATT-04: Simpan status check-out
      state = state.copyWith(
        isSubmitting: false,
        attendance: result,
        successMessage: 'Absen pulang tercatat ${result.formattedCheckOut}',
      );
      return true;
    } catch (e) {
      // ATT-08: JANGAN ubah status lokal jika gagal
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final todayAttendanceProvider =
    StateNotifierProvider<TodayAttendanceNotifier, TodayAttendanceState>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return TodayAttendanceNotifier(repo, locationService);
});

final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getHistory();
});
