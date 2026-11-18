import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
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

  static const String googleMapsUrl = 'https://maps.app.goo.gl/YEE5ggerC5V17GUs7';

  Future<void> _openMaps() async {
    final uri = Uri.parse(googleMapsUrl);
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
                    // 1. Gambaran Peta Presisi / Precise Interactive Map
                    _OfficeMapPreview(
                      office: office,
                      onTap: _openMaps,
                    ),
                    const SizedBox(height: 24),

                    // 2. Info Card (Clean Minimalist Coinbase Style, no radius badge)
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
                          Text(
                            office.name,
                            style: AppTypography.itemTitle.copyWith(fontSize: 18),
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

                    // 3. Action Button -> Google Maps Intent
                    AppButton(
                      text: 'Buka di Google Maps',
                      onPressed: _openMaps,
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
    final location = LatLng(office.latitude, office.longitude);

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray100, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Real OpenStreetMap view centered exactly at the office coordinate
          FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 18.0,
              minZoom: 12.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ethestech.attendance',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 48,
                    height: 54,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Column(
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.business,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(10, 8),
                            painter: _TrianglePainter(color: AppColors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
            child: GestureDetector(
              onTap: onTap,
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
                      'Buka Google Maps',
                      style: AppTypography.itemTitle.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
