import 'package:flutter/material.dart';

/// A wavy horizontal divider used between sections — matches the organic
/// wave-shaped transitions on mustav.vercel.app (e.g. the red wave rising
/// into the "Food That Feels Good" section). Pure CustomPainter, no
/// network dependency, so it can never break or go blank.
class WaveDivider extends StatelessWidget {
  final Color color;
  final double height;
  final bool flip; // flip=true draws the wave opening downward instead of up

  const WaveDivider({super.key, required this.color, this.height = 48, this.flip = false});

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipY: flip,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(painter: _WavePainter(color)),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, size.height * 0.55);

    path.quadraticBezierTo(
      size.width * 0.25, size.height * 1.15,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * -0.15,
      size.width, size.height * 0.45,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.color != color;
}