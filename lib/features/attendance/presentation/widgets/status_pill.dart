import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/attendance.dart';

class StatusPill extends StatelessWidget {
  final AttendanceStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case AttendanceStatus.tepatWaktu:
        color = AppColors.statusGreen;
        label = 'Tepat waktu';
        break;
      case AttendanceStatus.terlambat:
        color = AppColors.statusRed;
        label = 'Terlambat';
        break;
      case AttendanceStatus.belumAbsen:
        color = AppColors.statusGray;
        label = 'Belum absen';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const ShapeDecoration(
        color: AppColors.gray100,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.monoMedium.copyWith(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
