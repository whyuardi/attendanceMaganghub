import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../providers/office_provider.dart';

class OfficeScreen extends ConsumerWidget {
  const OfficeScreen({super.key});

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officeAsync = ref.watch(officeProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Lokasi kantor'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: officeAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(officeProvider),
          ),
          data: (office) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    office.name,
                    style: AppTypography.itemTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    office.address,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    office.formattedCoordinates,
                    style: AppTypography.monoSecondary,
                  ),
                  const Spacer(),
                  AppButton(
                    text: 'Buka di Maps',
                    onPressed: () => _openMaps(office.latitude, office.longitude),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
