import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_list_item.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Riwayat'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(attendanceHistoryProvider),
          ),
          data: (historyList) {
            if (historyList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Belum ada riwayat.\nAbsen pertamamu akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: AppColors.white,
              onRefresh: () async {
                ref.invalidate(attendanceHistoryProvider);
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  return AttendanceListItem(attendance: historyList[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
