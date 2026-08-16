import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _rippleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    // Drop impact and entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Continuous outward water ripple wave controller
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Water droplet impact bounce effect
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.08).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
    ]).animate(_entranceController);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _entranceController.forward();

    // Navigate to Home
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Water Drop Ripple Wave Container
              SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom Water Ripple Wave Painter
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(320, 320),
                          painter: WaterDropRipplePainter(
                            animationValue: _rippleController.value,
                            rippleColor: const Color(0xFF22C55E),
                            baseRadius: 60.0,
                          ),
                        );
                      },
                    ),

                    // Central Logo with Droplet Impact Physics
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.45),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/paatufy.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.music_note_rounded,
                              size: 72,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Brand Name styled with Poppins
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Paatu',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                    TextSpan(
                      text: 'fy',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tagline styled with Poppins
              Text(
                'Music for everyone',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter that simulates concentric water drop ripples expanding outward
class WaterDropRipplePainter extends CustomPainter {
  final double animationValue;
  final Color rippleColor;
  final double baseRadius;
  final int waveCount;

  WaterDropRipplePainter({
    required this.animationValue,
    required this.rippleColor,
    required this.baseRadius,
    this.waveCount = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < waveCount; i++) {
      // Stagger each wave ring
      final double waveProgress = (animationValue + (i / waveCount)) % 1.0;

      // Realistic water surface deceleration curve
      final double curvedProgress = Curves.easeOutCubic.transform(waveProgress);

      // Expansion from logo edge outward
      final double radius = baseRadius + (maxRadius - baseRadius) * curvedProgress;

      // Natural water ripple opacity dissipation (starts visible, dissolves at outer edges)
      final double opacity = math.sin(waveProgress * math.pi) * (1.0 - waveProgress);

      // Stroke thins out as the ripple propagates away
      final double strokeWidth = (3.5 * (1.0 - waveProgress)).clamp(0.8, 3.5);

      final paint = Paint()
        ..color = rippleColor.withOpacity((opacity * 0.7).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      // Subtle soft glow edge for each water wavefront
      final glowPaint = Paint()
        ..color = rippleColor.withOpacity((opacity * 0.35).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(center, radius, glowPaint);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterDropRipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}