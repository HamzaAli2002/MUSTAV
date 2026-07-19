import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The site's yellow-screen loading animation between page navigations:
/// a burger assembles layer by layer (bottom bun → patty → cheese →
/// lettuce → top bun) while a caption cycles through short status lines.
/// Used as the app's splash screen and reusable as an inline loader.
class MustavLoader extends StatefulWidget {
  final bool compact;
  const MustavLoader({super.key, this.compact = false});

  @override
  State<MustavLoader> createState() => _MustavLoaderState();
}

class _MustavLoaderState extends State<MustavLoader> with SingleTickerProviderStateMixin {
  static const _captions = [
    'Firing up the grill...',
    'Adding fresh toppings...',
    'Ready to serve...',
  ];

  late final AnimationController _controller;
  int _captionIndex = 0;
  Timer? _captionTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _captionTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _captionIndex = (_captionIndex + 1) % _captions.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _captionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.yellow,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(painter: _BurgerPainter(_controller.value)),
            ),
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _captions[_captionIndex],
              key: ValueKey(_captionIndex),
              style: AppTheme.body(size: 13, color: AppColors.ink, weight: FontWeight.w700).copyWith(letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a simple layered burger; each layer fades/slides in on its own
/// phase of the loop, then the whole stack does a gentle bounce.
class _BurgerPainter extends CustomPainter {
  final double t; // 0..1 looping progress
  _BurgerPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.72;
    final bounce = (t < 0.5 ? t : 1 - t) * 10;

    // Layer reveal phases across the loop: bun-bottom, patty, cheese,
    // lettuce, bun-top each "pop in" in sequence.
    double layerOpacity(double phaseStart) {
      const fadeIn = 0.15;
      if (t < phaseStart) return 0;
      if (t < phaseStart + fadeIn) return (t - phaseStart) / fadeIn;
      return 1;
    }

    void drawLayer(double dy, double w, double h, Color color, double phaseStart, {double radius = 100}) {
      final opacity = layerOpacity(phaseStart);
      if (opacity <= 0) return;
      final paint = Paint()..color = color.withOpacity(opacity);
      final rect = Rect.fromCenter(center: Offset(cx, baseY - dy - bounce), width: w, height: h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    }

    // Bottom bun
    drawLayer(0, 100, 26, const Color(0xFFC97A32), 0.0, radius: 14);
    // Patty
    drawLayer(20, 92, 20, const Color(0xFF6B4A2F), 0.15);
    // Cheese (slightly wider, subtle drape look via yellow-orange)
    drawLayer(34, 98, 12, const Color(0xFFF2B705), 0.32);
    // Lettuce
    drawLayer(44, 104, 14, const Color(0xFF7EA32A), 0.5);
    // Top bun (domed)
    final topOpacity = layerOpacity(0.68);
    if (topOpacity > 0) {
      final paint = Paint()..color = const Color(0xFFE79A3F).withOpacity(topOpacity);
      final domeRect = Rect.fromCenter(center: Offset(cx, baseY - 66 - bounce), width: 108, height: 46);
      canvas.drawArc(domeRect, 3.14, 3.14, false, paint..style = PaintingStyle.fill);
      final sesamePaint = Paint()..color = Colors.white.withOpacity(topOpacity * 0.9);
      for (final dx in [-28.0, -8.0, 12.0, 30.0]) {
        canvas.drawCircle(Offset(cx + dx, baseY - 78 - bounce), 2.4, sesamePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurgerPainter oldDelegate) => oldDelegate.t != t;
}
