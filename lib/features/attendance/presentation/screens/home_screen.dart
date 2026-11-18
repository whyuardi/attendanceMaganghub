import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../widgets/status_pill.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user == null || user.name.trim().isEmpty) {
        ref.read(authNotifierProvider.notifier).checkAuthStatus();
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatLiveTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String _formatFullDate(DateTime dt) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis',
      'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final todayState = ref.watch(todayAttendanceProvider);
    final todayNotifier = ref.read(todayAttendanceProvider.notifier);

    final user = authState.user;
    final String firstName;
    if (user != null && user.name.trim().isNotEmpty) {
      firstName = user.name.trim().split(' ').first;
    } else if (user != null && user.email.isNotEmpty) {
      firstName = user.email.split('@').first;
    } else {
      firstName = 'Karyawan';
    }

    if (todayState.isLoading && todayState.attendance == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: LoadingView(),
      );
    }

    final attendance = todayState.attendance;
    final hasCheckedIn = attendance?.checkInAt != null;
    final hasCheckedOut = attendance?.checkOutAt != null;

    // Helper method to capture photo from camera and submit attendance
    Future<void> performAttendanceWithCamera(bool isCheckIn) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (pickedFile == null) {
          // Pengguna membatalkan pengambilan foto kamera
          return;
        }

        final photoBytes = await pickedFile.readAsBytes();
        final success = isCheckIn
            ? await todayNotifier.checkIn(photoBytes: photoBytes)
            : await todayNotifier.checkOut(photoBytes: photoBytes);

        if (success) {
          ref.invalidate(attendanceHistoryProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kamera tidak dapat diakses: $e')),
          );
        }
      }
    }

    // Determine button label and action
    final String buttonText;
    final VoidCallback? buttonAction;
    final bool isButtonDisabled;

    if (!hasCheckedIn) {
      buttonText = 'Absen masuk';
      buttonAction = () => performAttendanceWithCamera(true);
      isButtonDisabled = false;
    } else if (!hasCheckedOut) {
      buttonText = 'Absen pulang';
      buttonAction = () => performAttendanceWithCamera(false);
      isButtonDisabled = false;
    } else {
      // Both IN and OUT completed
      buttonText = 'Selesai hari ini';
      buttonAction = null;
      isButtonDisabled = true;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.blue,
          backgroundColor: AppColors.white,
          onRefresh: () async {
            await todayNotifier.loadToday();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Greeting
                Text(
                  'Halo, $firstName',
                  style: AppTypography.greeting,
                ),
                const SizedBox(height: 36),

                // 2. Hero Time (JetBrains Mono 400, 48sp)
                Center(
                  child: Column(
                    children: [
                      Text(
                        _formatLiveTime(_currentTime),
                        style: AppTypography.heroTime,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFullDate(_currentTime),
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 3. Exactly ONE card (radius 24, no shadow)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gray100, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status kehadiran',
                            style: AppTypography.bodyMedium,
                          ),
                          StatusPill(
                            status: attendance?.status ?? AttendanceStatus.belumAbsen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Masuk',
                                  style: AppTypography.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  attendance?.formattedCheckIn ?? '--.--',
                                  style: AppTypography.monoMedium.copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: AppColors.gray100,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pulang',
                                  style: AppTypography.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  attendance?.formattedCheckOut ?? '--.--',
                                  style: AppTypography.monoMedium.copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Feedback message (Success / ATT-02 / ATT-08)
                if (todayState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      todayState.errorMessage!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.statusRed,
                      ),
                    ),
                  ),
                ] else if (todayState.successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      todayState.successMessage!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.statusGreen,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // 4. Action Button
                AppButton(
                  text: buttonText,
                  isLoading: todayState.isSubmitting,
                  onPressed: isButtonDisabled ? null : buttonAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
