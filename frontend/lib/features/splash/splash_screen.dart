import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _loopController;

  // Staggered Entrance Animations
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _descFade;
  late Animation<Offset> _descSlide;
  late Animation<double> _loaderFade;
  late Animation<double> _footerFade;
  late Animation<double> _footerScale;

  // Continuous Subtle Breathing / Loading Progress
  late Animation<double> _loopAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Choreography (1800ms total)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: 0ms -> 650ms
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.36, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Title: 400ms -> 1000ms
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline: 700ms -> 1250ms
    _descFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.38, 0.70, curve: Curves.easeOut),
      ),
    );
    _descSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.38, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Loading Indicator: 950ms -> 1450ms
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.52, 0.82, curve: Curves.easeOut),
      ),
    );

    // Footer: 1200ms -> 1800ms
    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.66, 0.95, curve: Curves.easeOut),
      ),
    );
    _footerScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Looping Controller for subtle ambient pulse & loading indicator progress
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loopAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF030710),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF030710),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final isCompact = height < 680 || width < 360;
            final isTablet = width >= 600;

            final logoSize = isTablet ? 180.0 : (isCompact ? 130.0 : 155.0);
            final titleFontSize = isTablet ? 38.0 : (isCompact ? 28.0 : 33.0);
            final descFontSize = isTablet ? 16.0 : (isCompact ? 13.5 : 14.5);
            final logoSpacing = isCompact ? 20.0 : 28.0;
            final titleSpacing = isCompact ? 8.0 : 12.0;
            final loaderSpacing = isCompact ? 24.0 : 32.0;

            return Stack(
              children: [
                // 1. Premium Dark Navy Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0C1829), // Rich midnight navy
                          Color(0xFF07111E), // Deep corporate navy
                          Color(0xFF030710), // Obsidian black-navy
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Subtle Radial Ambient Glow behind the emblem
                Positioned(
                  top: height * 0.22,
                  left: (width - 280) / 2,
                  child: AnimatedBuilder(
                    animation: _loopAnimation,
                    builder: (context, child) {
                      final pulse = _loopAnimation.value;
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12 + 0.05 * pulse),
                              blurRadius: 100 + 20 * pulse,
                              spreadRadius: 25 + 10 * pulse,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 3. Main Center Content + Footer
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),

                          // Logo Hero Element with Fade + Scale Entrance
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Image.asset(
                                'assets/fmp_emblem.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/FMP_icon.png',
                                  width: logoSize * 0.9,
                                  height: logoSize * 0.9,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: logoSpacing),

                          // Company Name with Smooth Fade + Slide-Up
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Text(
                                'FinanceMaster\nPro',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: titleSpacing),

                          // App Tagline
                          FadeTransition(
                            opacity: _descFade,
                            child: SlideTransition(
                              position: _descSlide,
                              child: Text(
                                'Smart financial management, made simple.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: descFontSize,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: loaderSpacing),

                          // Subtle Minimal Shimmer Loader Indicator
                          FadeTransition(
                            opacity: _loaderFade,
                            child: AnimatedBuilder(
                              animation: _loopController,
                              builder: (context, child) {
                                return _SubtleLoadingLine(
                                  progress: _loopController.value,
                                );
                              },
                            ),
                          ),

                          const Spacer(flex: 4),

                          // 4. Refined Powered by Media Wave Technologies Footer
                          FadeTransition(
                            opacity: _footerFade,
                            child: ScaleTransition(
                              scale: _footerScale,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildFooter(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'POWERED BY',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF64748B),
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMediaWaveLogoIcon(),
            const SizedBox(width: 8),
            Text(
              'Media Wave Technologies',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFCBD5E1),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaWaveLogoIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border.all(
          color: const Color(0xFF475569),
          width: 1.0,
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(13, 13),
          painter: _WaveIconPainter(),
        ),
      ),
    );
  }
}

/// Sleek indeterminate micro-progress shimmer line
class _SubtleLoadingLine extends StatelessWidget {
  final double progress;
  const _SubtleLoadingLine({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 2.5,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: CustomPaint(
          painter: _LoadingLinePainter(progress: progress),
        ),
      ),
    );
  }
}

class _LoadingLinePainter extends CustomPainter {
  final double progress;
  _LoadingLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final beamWidth = width * 0.45;
    final startX = (width + beamWidth) * progress - beamWidth;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.0),
          const Color(0xFF38BDF8),
          const Color(0xFF60A5FA),
          const Color(0xFF2563EB).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(startX, 0, beamWidth, size.height));

    canvas.drawRect(Rect.fromLTWH(startX, 0, beamWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _LoadingLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WaveIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.70);
    path.cubicTo(
      size.width * 0.20,
      size.height * 0.35,
      size.width * 0.60,
      size.height * 0.25,
      size.width * 0.75,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.85,
      size.height * 0.60,
      size.width * 0.65,
      size.height * 0.80,
      size.width * 0.45,
      size.height * 0.65,
    );
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.48), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
