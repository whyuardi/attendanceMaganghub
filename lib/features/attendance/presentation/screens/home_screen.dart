import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/location/location_service.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../widgets/status_pill.dart';

enum _AttendanceAction { checkIn, checkOut }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  bool _locationPermissionPromptHandled = false;
  bool _isOpeningCamera = false;
  _AttendanceAction? _selectedAttendanceAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user == null || user.name.trim().isEmpty) {
        ref.read(authNotifierProvider.notifier).checkAuthStatus();
      }
      ref.read(todayAttendanceProvider.notifier).loadToday();
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

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aktifkan GPS/lokasi perangkat untuk meningkatkan akurasi absensi.',
            ),
          ),
        );
      }
      await Geolocator.openLocationSettings();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi diperlukan agar absensi dapat diverifikasi secara akurat.',
            ),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi ditolak permanen. Aktifkan izin dari pengaturan aplikasi.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _promptLocationPermissionOnce() async {
    if (_locationPermissionPromptHandled) return;
    _locationPermissionPromptHandled = true;

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.denied) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted || !serviceEnabled) {
      return;
    }

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Izinkan akses lokasi'),
          content: const Text(
            'Aplikasi menggunakan lokasi perangkat presisi untuk memverifikasi bahwa Anda berada dalam radius 25 meter dari titik absensi kantor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Izinkan'),
            ),
          ],
        );
      },
    );

    if (allow == true) {
      await _ensureLocationPermission();
    }
  }

  String _formatLiveTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String _formatFullDate(DateTime dt) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
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

    if (authState.status == AuthStatus.authenticated &&
        !_locationPermissionPromptHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _promptLocationPermissionOnce();
        }
      });
    }

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
        backgroundColor: AppColors.scaffoldBg,
        body: LoadingView(),
      );
    }

    final attendance = todayState.attendance;
    final hasCheckedIn = attendance?.checkInAt != null;
    final hasCheckedOut = attendance?.checkOutAt != null;
    final checkInTime = attendance?.formattedCheckIn ?? '--.--';

    // Helper method to capture photo from camera and submit attendance
    Future<void> performAttendanceWithCamera(bool isCheckIn) async {
      if (_isOpeningCamera) return;

      setState(() {
        _isOpeningCamera = true;
      });

      try {
        if (isCheckIn && hasCheckedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kamu sudah absen masuk hari ini pukul ${attendance!.formattedCheckIn}',
              ),
              backgroundColor: AppColors.statusRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (!isCheckIn && hasCheckedOut) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kamu sudah absen pulang hari ini pukul ${attendance!.formattedCheckOut}',
              ),
              backgroundColor: AppColors.statusRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (!isCheckIn && !hasCheckedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamu belum absen masuk hari ini'),
              backgroundColor: AppColors.statusRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Validasi waktu sebelum membuka kamera untuk absen pulang (Opsi A)
        if (!isCheckIn) {
          final now = DateTime.now();
          if (now.weekday == DateTime.sunday) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Hari Minggu libur. Tidak dapat melakukan absensi.',
                ),
                backgroundColor: AppColors.statusRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          if (now.weekday >= DateTime.monday &&
              now.weekday <= DateTime.friday) {
            if (now.hour < 17) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Belum waktunya absen pulang. Absen pulang hari Senin—Jumat baru dapat dilakukan mulai pukul 17.00 WIB.',
                  ),
                  backgroundColor: AppColors.statusRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
          }

          if (now.weekday == DateTime.saturday) {
            if (now.hour < 16) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Belum waktunya absen pulang. Absen pulang hari Sabtu baru dapat dilakukan mulai pukul 16.00 WIB.',
                  ),
                  backgroundColor: AppColors.statusRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
          }
        }

        // Validasi lokasi dan radius mobile (maks 15 meter) sebelum membuka kamera
        try {
          final locationService = ref.read(locationServiceProvider);
          final pos = await locationService.getCurrentPosition();
          await locationService.verifyRadius(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        } catch (e) {
          if (context.mounted) {
            final msg = e
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('ValidationError: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: AppColors.statusRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        try {
          final hasLocationPermission = await _ensureLocationPermission();
          if (!hasLocationPermission) return;

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
      } finally {
        if (mounted) {
          setState(() {
            _isOpeningCamera = false;
          });
        }
      }
    }

    final selectedAttendanceAction =
        _selectedAttendanceAction ??
        (hasCheckedIn ? _AttendanceAction.checkOut : _AttendanceAction.checkIn);
    final buttonText = selectedAttendanceAction == _AttendanceAction.checkIn
        ? 'Absen masuk'
        : 'Absen pulang';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.sidebarBg,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELAMAT DATANG',
                      style: AppTypography.monoSecondary.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      firstName,
                      style: AppTypography.greeting.copyWith(
                        color: AppColors.sidebarBg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'WAKTU SAAT INI',
                            style: AppTypography.monoSecondary.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatLiveTime(_currentTime),
                        style: AppTypography.heroTime.copyWith(
                          color: AppColors.sidebarBg,
                          fontSize: 46,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatFullDate(_currentTime),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A061A14),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status kehadiran',
                            style: AppTypography.itemTitle.copyWith(
                              color: AppColors.textDark,
                              fontSize: 15,
                            ),
                          ),
                          StatusPill(
                            status:
                                attendance?.status ??
                                AttendanceStatus.belumAbsen,
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
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  checkInTime,
                                  style: AppTypography.monoMedium.copyWith(
                                    color: AppColors.sidebarBg,
                                    fontSize: 18,
                                  ),
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
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  attendance?.formattedCheckOut ?? '--.--',
                                  style: AppTypography.monoMedium.copyWith(
                                    color: AppColors.sidebarBg,
                                    fontSize: 18,
                                  ),
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
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.statusRed),
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
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      todayState.successMessage!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.statusGreen,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                DropdownButtonFormField<_AttendanceAction>(
                  key: const Key('attendance-action-dropdown'),
                  initialValue: selectedAttendanceAction,
                  decoration: const InputDecoration(
                    labelText: 'Pilih jenis absensi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _AttendanceAction.checkIn,
                      child: Text('IN - Absen masuk'),
                    ),
                    DropdownMenuItem(
                      value: _AttendanceAction.checkOut,
                      child: Text('OUT - Absen pulang'),
                    ),
                  ],
                  onChanged: todayState.isSubmitting
                      ? null
                      : (action) {
                          if (action != null) {
                            setState(() {
                              _selectedAttendanceAction = action;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    key: const Key('attendance-action-button'),
                    onPressed: todayState.isSubmitting || _isOpeningCamera
                        ? null
                        : () => performAttendanceWithCamera(
                            selectedAttendanceAction ==
                                _AttendanceAction.checkIn,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidebarBg,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.gray300,
                      disabledForegroundColor: AppColors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: todayState.isSubmitting || _isOpeningCamera
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGold,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.primaryGold,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                buttonText,
                                style: AppTypography.button.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
