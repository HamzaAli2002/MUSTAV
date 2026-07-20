import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/burger.dart';

/// A fully-drawn burger illustration — no network image involved at all.
/// Used everywhere a burger "photo" was previously loaded from the
/// network (menu cards, product detail, cart thumbnails, hero section).
/// After repeated unreliable results from three different network image
/// services (guessed Unsplash IDs, Picsum, LoremFlickr), this guarantees
/// every burger image renders correctly 100% of the time, regardless of
/// network conditions — matching the app's own brand illustration style
/// (same drawing technique as the loading animation).
class BurgerIllustration extends StatelessWidget {
  final double size;
  final Color backgroundColor;

  const BurgerIllustration(
      {super.key,
      this.size = 200,
      this.backgroundColor = const Color(0xFFF4E0CC)});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StaticBurgerPainter()),
      ),
    );
  }
}

class _StaticBurgerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.72;

    void drawLayer(double dy, double w, double h, Color color,
        {double radius = 100}) {
      final paint = Paint()..color = color;
      final rect =
          Rect.fromCenter(center: Offset(cx, baseY - dy), width: w, height: h);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    }

    // Shadow
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.08);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, baseY + size.height * 0.16),
          width: size.width * 0.6,
          height: size.height * 0.06),
      shadowPaint,
    );

    drawLayer(0, size.width * 0.5, size.height * 0.13, const Color(0xFFC97A32),
        radius: 14);
    drawLayer(size.height * 0.1, size.width * 0.46, size.height * 0.1,
        const Color(0xFF6B4A2F));
    drawLayer(size.height * 0.17, size.width * 0.49, size.height * 0.06,
        const Color(0xFFF2B705));
    drawLayer(size.height * 0.22, size.width * 0.52, size.height * 0.07,
        const Color(0xFF7EA32A));

    final domePaint = Paint()..color = const Color(0xFFE79A3F);
    final domeRect = Rect.fromCenter(
        center: Offset(cx, baseY - size.height * 0.33),
        width: size.width * 0.54,
        height: size.height * 0.23);
    canvas.drawArc(
        domeRect, 3.14, 3.14, false, domePaint..style = PaintingStyle.fill);

    final sesamePaint = Paint()..color = Colors.white;
    for (final dx in [-0.14, -0.05, 0.06, 0.15]) {
      canvas.drawCircle(
          Offset(cx + dx * size.width, baseY - size.height * 0.38),
          size.width * 0.012,
          sesamePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticBurgerPainter oldDelegate) => false;
}

/// Shows the burger's real Foodish photo if one has been resolved and
/// cached; otherwise (or on any load error) shows the guaranteed-reliable
/// drawn illustration instead. This is the single place that decides
/// "real photo vs illustration" so every screen behaves consistently.
class BurgerPhoto extends StatelessWidget {
  final Burger burger;
  final double illustrationSize;
  final Color backgroundColor;
  final int? memCacheWidth;

  const BurgerPhoto({
    super.key,
    required this.burger,
    this.illustrationSize = 140,
    this.backgroundColor = const Color(0xFFF4E0CC),
    this.memCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = burger.resolvedPhotoUrl;
    if (photoUrl == null) {
      return BurgerIllustration(
          size: illustrationSize, backgroundColor: backgroundColor);
    }
    return CachedNetworkImage(
      imageUrl: photoUrl,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      placeholder: (context, url) => BurgerIllustration(
          size: illustrationSize, backgroundColor: backgroundColor),
      errorWidget: (context, url, error) => BurgerIllustration(
          size: illustrationSize, backgroundColor: backgroundColor),
    );
  }
}

/// A small square tile used for ingredient/story-row thumbnails — an icon
/// on a colored background instead of a network photo, so these small
/// decorative images can never fail to load either.
class IngredientTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IngredientTile(
      {super.key, required this.icon, required this.color, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.4),
    );
  }
}

/// A city "photo" substitute for location cards — a colored tile with a
/// skyline-style icon, no network dependency.
class CityTile extends StatelessWidget {
  final Color color;
  const CityTile({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: const Icon(Icons.location_city, color: Colors.white, size: 40),
    );
  }
}
