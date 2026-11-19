import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/office.dart';
import '../providers/office_provider.dart';

class OfficeScreen extends ConsumerWidget {
  const OfficeScreen({super.key});

  static const String googleMapsUrl =
      'https://www.google.com/maps/search/?api=1&query=${LocationService.officeLatitude},${LocationService.officeLongitude}';

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
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: officeAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(officeProvider),
          ),
          data: (office) {
            if (!office.isActive) {
              return ErrorView(
                message: 'Lokasi kantor aktif tidak tersedia.',
                onRetry: () => ref.refresh(officeProvider),
              );
            }
            return RefreshIndicator(
              color: AppColors.sidebarBg,
              backgroundColor: AppColors.white,
              onRefresh: () async => ref.refresh(officeProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFORMASI LOKASI',
                          style: AppTypography.monoSecondary.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kantor Anda',
                          style: AppTypography.greeting.copyWith(
                            color: AppColors.sidebarBg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lokasi dan detail titik absensimu.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _OfficeMapPreview(office: office, onTap: _openMaps),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
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
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.cardBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.sidebarBg,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  office.name,
                                  style: AppTypography.itemTitle.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.gray100,
                            ),
                          ),
                          _OfficeDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Alamat',
                            value: office.address,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.gray100,
                            ),
                          ),
                          _OfficeDetailRow(
                            icon: Icons.my_location_rounded,
                            label: 'Titik koordinat',
                            value: office.formattedCoordinates,
                            isMonospace: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.gray100,
                            ),
                          ),
                          _OfficeDetailRow(
                            icon: Icons.radar_rounded,
                            label: 'Radius absensi',
                            value: '${office.radiusMeters} m',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _openMaps,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sidebarBg,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Buka di Google Maps',
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
            );
          },
        ),
      ),
    );
  }
}

class _OfficeDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;

  const _OfficeDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style:
                    (isMonospace
                            ? AppTypography.monoMedium
                            : AppTypography.bodyLarge)
                        .copyWith(
                          color: AppColors.textDark,
                          fontSize: 14,
                          height: 1.45,
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfficeMapPreview extends StatelessWidget {
  final Office office;
  final VoidCallback onTap;

  const _OfficeMapPreview({required this.office, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final location = LatLng(office.latitude, office.longitude);

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
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
                              color: AppColors.sidebarBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sidebarBg.withValues(
                                    alpha: 0.3,
                                  ),
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
                            painter: _TrianglePainter(
                              color: AppColors.sidebarBg,
                            ),
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
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.primaryGold,
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sidebarBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: AppColors.primaryGold,
                    ),
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
