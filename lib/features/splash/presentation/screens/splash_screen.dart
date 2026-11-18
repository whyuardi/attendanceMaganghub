import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 3);

  late final AnimationController _entranceController;
  late final AnimationController _exitController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _lineWidth;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  bool _isExiting = false;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _lineWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeInOutCubic),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    try {
      await _entranceController.forward();
      if (!mounted || _isExiting) return;

      await Future.delayed(_holdDuration);
      if (!mounted || _isExiting) return;

      await _finishSplash();
    } on TickerCanceled {
      // The entrance animation is canceled when the user skips the splash.
    }
  }

  Future<void> _finishSplash() async {
    if (_isExiting || _completionSent) return;
    _isExiting = true;
    _entranceController.stop();

    try {
      await _exitController.forward();
    } on TickerCanceled {
      return;
    }
    if (!mounted || _completionSent) return;

    _completionSent = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _exitController]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitOpacity,
            child: ScaleTransition(
              scale: _exitScale,
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, top: 8),
                        child: TextButton(
                          onPressed: _finishSplash,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryGold,
                          ),
                          child: const Text('Lewati'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxLogoSize =
                                MediaQuery.sizeOf(context).width * 0.84;
                            final logoSize = constraints.maxHeight < maxLogoSize
                                ? constraints.maxHeight
                                : maxLogoSize;

                            return FadeTransition(
                              opacity: _logoOpacity,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Image.asset(
                                  'assets/images/app-logo.png',
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Ethes Tech',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: const BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SlideTransition(
                              position: _titleSlide,
                              child: Text(
                                'Workforce Attendance',
                                textAlign: TextAlign.center,
                                style: AppTypography.appTitle.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 26,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _subtitleOpacity,
                              child: SlideTransition(
                                position: _subtitleSlide,
                                child: Text(
                                  'Kelola kehadiran magang dengan lebih mudah.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_available_rounded,
                                    color: AppColors.sidebarBg,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Presensi praktis dan tercatat',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 3,
                              width: 72,
                              child: Align(
                                alignment: Alignment.center,
                                child: FractionallySizedBox(
                                  widthFactor: _lineWidth.value,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
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
          );
        },
      ),
    );
  }
}
