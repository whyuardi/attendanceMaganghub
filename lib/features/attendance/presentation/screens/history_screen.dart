import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_list_item.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(attendanceHistoryProvider),
          ),
          data: (historyList) {
            final today = DateTime.now();
            final weekStart = DateTime(
              today.year,
              today.month,
              today.day,
            ).subtract(Duration(days: today.weekday - DateTime.monday));
            final weekEnd = weekStart.add(const Duration(days: 7));
            final monthStart = DateTime(today.year, today.month);
            final nextMonthStart = DateTime(today.year, today.month + 1);
            final weeklyCount = _countAttendances(
              historyList,
              weekStart,
              weekEnd,
            );
            final monthlyCount = _countAttendances(
              historyList,
              monthStart,
              nextMonthStart,
            );
            final filteredHistory = _selectedDate == null
                ? historyList
                : historyList
                      .where(
                        (attendance) => _isOnDate(attendance, _selectedDate!),
                      )
                      .toList();

            return RefreshIndicator(
              color: AppColors.sidebarBg,
              backgroundColor: AppColors.white,
              onRefresh: () async {
                ref.invalidate(attendanceHistoryProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AKTIVITAS KEHADIRAN',
                        style: AppTypography.monoSecondary.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Riwayat Absensi',
                        style: AppTypography.greeting.copyWith(
                          color: AppColors.sidebarBg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pantau catatan kehadiranmu di sini.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Rekap Kehadiran',
                    style: AppTypography.itemTitle.copyWith(
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AttendanceSummaryCard(
                          title: 'Mingguan',
                          icon: Icons.date_range_rounded,
                          count: weeklyCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AttendanceSummaryCard(
                          title: 'Bulanan',
                          icon: Icons.calendar_month_rounded,
                          count: monthlyCount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Kehadiran',
                        style: AppTypography.itemTitle.copyWith(
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.filter_list_rounded, size: 18),
                        label: const Text('Filter tanggal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.sidebarBg,
                          side: const BorderSide(color: AppColors.gray100),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(_selectedDate!),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          child: const Text('Tampilkan semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (filteredHistory.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
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
                        children: [
                          const Icon(
                            Icons.event_note_rounded,
                            color: AppColors.primaryGold,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate == null
                                ? 'Belum ada riwayat'
                                : 'Tidak ada absensi pada tanggal ini',
                            style: AppTypography.itemTitle.copyWith(
                              color: AppColors.textDark,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedDate == null
                                ? 'Absen pertamamu akan muncul di sini.'
                                : 'Pilih tanggal lain atau tampilkan semua absensi.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredHistory.map(
                      (attendance) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AttendanceListItem(attendance: attendance),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

DateTime? _attendanceDate(Attendance attendance) {
  return DateTime.tryParse(attendance.workDate) ??
      attendance.checkInAt?.toLocal();
}

bool _isInPeriod(Attendance attendance, DateTime start, DateTime end) {
  final date = _attendanceDate(attendance);
  return date != null && !date.isBefore(start) && date.isBefore(end);
}

bool _isOnDate(Attendance attendance, DateTime selectedDate) {
  final date = _attendanceDate(attendance);
  return date != null &&
      date.year == selectedDate.year &&
      date.month == selectedDate.month &&
      date.day == selectedDate.day;
}

String _formatDate(DateTime date) {
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

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

int _countAttendances(List<Attendance> history, DateTime start, DateTime end) {
  return history.where((attendance) {
    if (attendance.checkInAt == null) return false;
    return _isInPeriod(attendance, start, end);
  }).length;
}

class _AttendanceSummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _AttendanceSummaryCard({
    required this.title,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A061A14),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$count hari',
            style: AppTypography.monoMedium.copyWith(
              color: AppColors.sidebarBg,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'hadir',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
