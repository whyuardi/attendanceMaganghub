import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/attendance.dart';
import 'status_pill.dart';

class AttendanceListItem extends StatelessWidget {
  final Attendance attendance;

  const AttendanceListItem({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  attendance.formattedDate,
                  style: AppTypography.itemTitle.copyWith(
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusPill(status: attendance.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 0.5, color: AppColors.gray100),
          ),
          Row(
            children: [
              Expanded(
                child: _AttendanceTime(
                  label: 'Masuk',
                  time: attendance.formattedCheckIn,
                ),
              ),
              Container(height: 36, width: 1, color: AppColors.gray100),
              const SizedBox(width: 20),
              Expanded(
                child: _AttendanceTime(
                  label: 'Pulang',
                  time: attendance.formattedCheckOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceTime extends StatelessWidget {
  final String label;
  final String time;

  const _AttendanceTime({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: AppTypography.monoMedium.copyWith(
            color: AppColors.sidebarBg,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
