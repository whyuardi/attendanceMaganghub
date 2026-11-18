import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/office.dart';
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
        elevation: 0,
      ),
      body: SafeArea(
        child: officeAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(officeProvider),
          ),
          data: (office) {
            return RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: AppColors.white,
              onRefresh: () async => ref.refresh(officeProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Gambaran Peta / Map Preview Card
                    _OfficeMapPreview(
                      office: office,
                      onTap: () => _openMaps(office.latitude, office.longitude),
                    ),
                    const SizedBox(height: 24),

                    // 2. Info Card (Radius 24, Minimalist Coinbase Style)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                              Expanded(
                                child: Text(
                                  office.name,
                                  style: AppTypography.itemTitle.copyWith(fontSize: 18),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.radar,
                                      size: 14,
                                      color: AppColors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Radius ${office.radiusM} m',
                                      style: AppTypography.monoSecondary.copyWith(
                                        fontSize: 12,
                                        color: AppColors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Alamat',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.gray700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            office.address,
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Titik koordinat',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.gray700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            office.formattedCoordinates,
                            style: AppTypography.monoMedium.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. Action Button
                    AppButton(
                      text: 'Buka di Google Maps',
                      onPressed: () => _openMaps(office.latitude, office.longitude),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfficeMapPreview extends StatelessWidget {
  final Office office;
  final VoidCallback onTap;

  const _OfficeMapPreview({
    required this.office,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mapUrl =
        'https://staticmap.openstreetmap.de/staticmap.php?center=${office.latitude},${office.longitude}&zoom=17&size=680x380&maptype=mapnik';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Map Image with network loading & offline vector fallback
            Image.network(
              mapUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackVectorMap(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _buildFallbackVectorMap();
              },
            ),

            // Geofence Radius Circle Indicator
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.18),
                border: Border.all(color: AppColors.blue, width: 2),
              ),
            ),

            // Office Center Pin Marker
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                Container(
                  width: 4,
                  height: 6,
                  color: AppColors.blue,
                ),
              ],
            ),

            // Top-left label badge
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.statusRed),
                    const SizedBox(width: 4),
                    Text(
                      'Peta Lokasi Kantor',
                      style: AppTypography.itemTitle.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right tap hint badge
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new, size: 12, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Ketuk untuk rute',
                      style: AppTypography.itemTitle.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackVectorMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE5E7EB),
      child: CustomPaint(
        painter: _GridMapPainter(),
      ),
    );
  }
}

class _GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.0;

    // Grid lines
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Road lines
    final roadPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
