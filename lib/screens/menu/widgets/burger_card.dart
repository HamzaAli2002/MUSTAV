import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/burger.dart';
import '../../../models/enums.dart';
import '../../../widgets/burger_illustration.dart';

/// Full-width menu card — matches the real site's menu layout exactly:
/// a large photo, a name + bun/patty info row with the price at top
/// right, and a full-width red "ADD TO CART" bar along the bottom.
class BurgerCard extends StatelessWidget {
  final Burger burger;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const BurgerCard(
      {super.key,
      required this.burger,
      required this.onTap,
      required this.onAddToCart});

  Color _spiceColor(SpiceLevel level) => switch (level) {
        SpiceLevel.mild => AppColors.success,
        SpiceLevel.medium => AppColors.warning,
        SpiceLevel.hot => AppColors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: BurgerPhoto(
                      burger: burger,
                      illustrationSize: 140,
                      memCacheWidth: 800),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _pill(burger.bunType.label, Icons.bakery_dining),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _pill(burger.prepTimeLabel, Icons.schedule),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(burger.name,
                            style: AppTheme.display(
                                size: 18, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 13,
                                color: _spiceColor(burger.spiceLevel)),
                            const SizedBox(width: 3),
                            Text(
                                '${burger.spiceLevel.label} · ${burger.pattyType.label} patty',
                                style: AppTheme.body(
                                    size: 11,
                                    color: AppColors.inkSoft,
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('Rs. ${burger.priceRs}',
                      style: AppTheme.display(size: 18, color: AppColors.red)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onAddToCart,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.red,
                alignment: Alignment.center,
                child: Text(
                  'ADD TO CART',
                  style: AppTheme.body(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800)
                      .copyWith(letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
