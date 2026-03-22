import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/finshe_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FinShe — Premium Splash Screen
// Aurora waves · pulsing halo rings · metallic wordmark · floating orbs
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    super.key,
    required this.onFinished,
    this.assetPath = 'assets/branding/finshe_logo.png',
  });

  final VoidCallback onFinished;
  final String assetPath;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  // ── controllers ─────────────────────────────────────────────────────────
  late final AnimationController _master;   // 4.6 s total timeline
  late final AnimationController _aurora;   // looping aurora wave
  late final AnimationController _rings;    // looping halo-ring pulse
  late final AnimationController _orbs;     // looping floating orbs
  late final AnimationController _shimmer;  // looping logo shimmer

  // ── master-pinned animations ─────────────────────────────────────────────
  late final Animation<double> _bgReveal;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;
  late final Animation<double> _barProgress;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    _master  = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));
    _aurora  = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))..repeat();
    _rings   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _orbs    = AnimationController(vsync: this, duration: const Duration(milliseconds: 7000))..repeat();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    CurvedAnimation _cv(double s, double e, [Curve c = Curves.easeOutCubic]) =>
        CurvedAnimation(parent: _master, curve: Interval(s, e, curve: c));

    _bgReveal    = Tween<double>(begin: 0, end: 1).animate(_cv(0.00, 0.22));
    _logoScale   = Tween<double>(begin: 0.0, end: 1.0).animate(_cv(0.06, 0.42, Curves.elasticOut));
    _logoFade    = Tween<double>(begin: 0, end: 1).animate(_cv(0.06, 0.30));
    _nameFade    = Tween<double>(begin: 0, end: 1).animate(_cv(0.36, 0.54));
    _nameSlide   = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_cv(0.36, 0.54));
    _tagFade     = Tween<double>(begin: 0, end: 1).animate(_cv(0.50, 0.66));
    _tagSlide    = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_cv(0.50, 0.66));
    _barProgress = Tween<double>(begin: 0, end: 1).animate(_cv(0.22, 0.88));
    _exitFade    = Tween<double>(begin: 1, end: 0).animate(_cv(0.84, 1.00, Curves.easeInExpo));

    _master.forward().whenComplete(() {
      if (mounted) {
        _aurora.stop(); _rings.stop(); _orbs.stop(); _shimmer.stop();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _master.dispose(); _aurora.dispose(); _rings.dispose();
    _orbs.dispose(); _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_master, _aurora, _rings, _orbs, _shimmer]),
      builder: (context, _) {
        return FadeTransition(
          opacity: _exitFade,
          child: Scaffold(
            backgroundColor: const Color(0xFF060410),
            body: Stack(
              fit: StackFit.expand,
              children: [

                // ── 1. Aurora background ────────────────────────────────
                Opacity(
                  opacity: _bgReveal.value,
                  child: _AuroraBackground(t: _aurora.value),
                ),

                // ── 2. Floating orbs ───────────────────────────────────
                Opacity(
                  opacity: (_bgReveal.value).clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: _OrbPainter(t: _orbs.value),
                    size: Size.infinite,
                  ),
                ),

                // ── 3. Pulsing halo rings (behind logo) ────────────────
                Center(
                  child: Opacity(
                    opacity: _logoFade.value,
                    child: CustomPaint(
                      painter: _HaloRingsPainter(pulse: _rings.value),
                      size: const Size(340, 340),
                    ),
                  ),
                ),

                // ── 4. Logo card ───────────────────────────────────────
                Center(
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: _LogoCard(
                        assetPath: widget.assetPath,
                        shimmer: _shimmer.value,
                      ),
                    ),
                  ),
                ),

                // ── 5. App name + tagline (below logo) ─────────────────
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 200), // push below logo
                      FadeTransition(
                        opacity: _nameFade,
                        child: SlideTransition(
                          position: _nameSlide,
                          child: _MetallicText(
                            text: 'FinShe',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              height: 1.0,
                            ),
                            colors: const [
                              Color(0xFFE9D5FF),
                              Color(0xFFFFFFFF),
                              Color(0xFFA377FF),
                              Color(0xFFF03E97),
                              Color(0xFFE9D5FF),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _tagFade,
                        child: SlideTransition(
                          position: _tagSlide,
                          child: Text(
                            'Scholarships  ·  Loans  ·  Your Future',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFB8AEDD),
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 6. Bottom progress bar ─────────────────────────────
                Positioned(
                  left: 40,
                  right: 40,
                  bottom: MediaQuery.paddingOf(context).bottom + 44,
                  child: Opacity(
                    opacity: _tagFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Powered by FinShe AI',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.30),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GlowProgressBar(
                          progress: _barProgress.value,
                          width: sz.width - 80,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aurora Background — deep purple/blue/pink animated waves
// ─────────────────────────────────────────────────────────────────────────────
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final a = t * math.pi * 2;
    return Stack(fit: StackFit.expand, children: [
      // Deep base
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C0820), Color(0xFF060410)],
          ),
        ),
      ),
      // Aurora wave 1 — purple top-left
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              -0.6 + math.sin(a * 0.7) * 0.25,
              -0.8 + math.cos(a * 0.5) * 0.20,
            ),
            radius: 1.10,
            colors: [
              const Color(0xFF6D28D9).withValues(alpha: 0.55),
              const Color(0xFF4C1D95).withValues(alpha: 0.20),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
      // Aurora wave 2 — pink bottom-right
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              0.55 + math.cos(a * 0.6) * 0.22,
              0.65 + math.sin(a * 0.4) * 0.18,
            ),
            radius: 0.90,
            colors: [
              const Color(0xFFF03E97).withValues(alpha: 0.38),
              const Color(0xFF9D174D).withValues(alpha: 0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.50, 1.0],
          ),
        ),
      ),
      // Aurora wave 3 — indigo centre bloom
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              math.sin(a * 0.3) * 0.18,
              -0.15 + math.cos(a * 0.45) * 0.14,
            ),
            radius: 0.70,
            colors: [
              const Color(0xFF7C3AED).withValues(alpha: 0.32),
              Colors.transparent,
            ],
          ),
        ),
      ),
      // Aurora wave 4 — teal accent (bottom)
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              math.cos(a * 0.55) * 0.30,
              1.0 + math.sin(a * 0.35) * 0.10,
            ),
            radius: 0.75,
            colors: [
              const Color(0xFF0D9488).withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ),
        ),
      ),
      // Strong vignette
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              const Color(0xFF060410).withValues(alpha: 0.75),
            ],
            stops: const [0.45, 1.0],
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating orbs — large soft bokeh blobs drifting slowly
// ─────────────────────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.t});
  final double t;

  static const _orbs = [
    _OrbSeed(rx: 0.18, ry: 0.22, r: 55, speed: 0.12, phase: 0.0,  hue: 0.0),
    _OrbSeed(rx: 0.78, ry: 0.18, r: 45, speed: 0.09, phase: 0.33, hue: 1.0),
    _OrbSeed(rx: 0.88, ry: 0.62, r: 60, speed: 0.11, phase: 0.55, hue: 0.5),
    _OrbSeed(rx: 0.12, ry: 0.75, r: 40, speed: 0.14, phase: 0.78, hue: 0.2),
    _OrbSeed(rx: 0.50, ry: 0.90, r: 50, speed: 0.08, phase: 0.15, hue: 0.8),
    _OrbSeed(rx: 0.60, ry: 0.40, r: 32, speed: 0.16, phase: 0.62, hue: 0.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final o in _orbs) {
      final angle = (t + o.phase) * math.pi * 2 * o.speed * 8;
      final dx = math.cos(angle) * 28;
      final dy = math.sin(angle * 0.73) * 22;
      final cx = o.rx * size.width + dx;
      final cy = o.ry * size.height + dy;
      final color = Color.lerp(
        const Color(0xFF7C3AED),
        const Color(0xFFF03E97),
        o.hue,
      )!.withValues(alpha: 0.18);
      canvas.drawCircle(
        Offset(cx, cy),
        o.r.toDouble(),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, o.r * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t;
}

class _OrbSeed {
  const _OrbSeed({required this.rx, required this.ry, required this.r,
      required this.speed, required this.phase, required this.hue});
  final double rx, ry, speed, phase, hue;
  final int r;
}

// ─────────────────────────────────────────────────────────────────────────────
// Halo rings — three concentric rings that pulse outward from center
// ─────────────────────────────────────────────────────────────────────────────
class _HaloRingsPainter extends CustomPainter {
  const _HaloRingsPainter({required this.pulse});
  final double pulse; // 0→1 repeating

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    void drawRing(double baseR, double phase, Color col, double strokeW) {
      final t = ((pulse + phase) % 1.0);
      final r = baseR + t * 38;
      final opacity = (1.0 - t) * (1.0 - t) * 0.60;
      if (opacity < 0.01) return;
      canvas.drawCircle(
        c, r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..color = col.withValues(alpha: opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    drawRing(78, 0.00, FinsheColors.accentPurple, 3.0);
    drawRing(78, 0.33, FinsheColors.accentPink,   2.0);
    drawRing(78, 0.66, FinsheColors.accentLavender, 1.5);

    // Static glow ring tight around logo
    canvas.drawCircle(
      c, 80,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _HaloRingsPainter old) => old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo card — circular glass disc with border gradient + deep glow
// ─────────────────────────────────────────────────────────────────────────────
class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.assetPath, required this.shimmer});
  final String assetPath;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final sweep = (shimmer - 0.5) * 2.5;

    return Container(
      width: 154,
      height: 154,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            FinsheColors.accentPurple.withValues(alpha: 0.9),
            FinsheColors.accentPink.withValues(alpha: 0.85),
            FinsheColors.accentLavender.withValues(alpha: 0.7),
            FinsheColors.accentPurple.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
          transform: GradientRotation(shimmer * math.pi * 2),
        ),
        boxShadow: [
          // Main colour glow
          BoxShadow(
            color: FinsheColors.accentPurple.withValues(alpha: 0.60),
            blurRadius: 50,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: FinsheColors.accentPink.withValues(alpha: 0.35),
            blurRadius: 80,
            spreadRadius: -4,
            offset: const Offset(0, 20),
          ),
          // White core specular
          const BoxShadow(
            color: Color(0x22FFFFFF),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5),  // border thickness
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 1.1,
              colors: [
                const Color(0xFF1E1130),
                const Color(0xFF0D0820),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Logo image
              Padding(
                padding: const EdgeInsets.all(22),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.account_balance_rounded,
                    size: 60,
                    color: FinsheColors.accentLavender,
                  ),
                ),
              ),
              // Shimmer sweep
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(builder: (_, c) {
                    return Transform.translate(
                      offset: Offset(sweep * c.maxWidth * 0.85, 0),
                      child: Container(
                        width: c.maxWidth * 0.35,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.22),
                              Colors.white.withValues(alpha: 0.0),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metallic gradient text — 5-stop rainbow highlight shimmer
// ─────────────────────────────────────────────────────────────────────────────
class _MetallicText extends StatelessWidget {
  const _MetallicText({
    required this.text,
    required this.style,
    required this.colors,
  });
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glow progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _GlowProgressBar extends StatelessWidget {
  const _GlowProgressBar({required this.progress, required this.width});
  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 4,
      child: Stack(children: [
        // Track
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Filled portion
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFF03E97), Color(0xFFFFB347)],
              ),
              boxShadow: [
                BoxShadow(
                  color: FinsheColors.accentPurple.withValues(alpha: 0.80),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: FinsheColors.accentPink.withValues(alpha: 0.50),
                  blurRadius: 20,
                  spreadRadius: -1,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
