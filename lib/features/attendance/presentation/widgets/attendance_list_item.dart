import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/attendance.dart';
import 'status_pill.dart';

class AttendanceListItem extends StatelessWidget {
  final Attendance attendance;

  const AttendanceListItem({
    super.key,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.formattedDate,
                      style: AppTypography.itemTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${attendance.formattedCheckIn} — ${attendance.formattedCheckOut}',
                      style: AppTypography.monoSecondary,
                    ),
                  ],
                ),
              ),
              StatusPill(status: attendance.status),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: AppColors.gray100,
        ),
      ],
    );
  }
}
