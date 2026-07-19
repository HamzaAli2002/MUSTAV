import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A friendly retro-diner chef mascot — evokes the bobblehead figurine
/// illustration used on mustav.vercel.app, without depending on any
/// network image (so it can never fail to load or go blank). Built
/// entirely from shapes/icons.
class ChefMascot extends StatelessWidget {
  final double size;
  const ChefMascot({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Chef hat
          Positioned(
            top: 0,
            child: Container(
              width: size * 0.62,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.3),
                border: Border.all(color: AppColors.ink.withOpacity(0.15), width: 1.5),
              ),
            ),
          ),
          Positioned(
            top: size * 0.32,
            child: Container(
              width: size * 0.7,
              height: size * 0.1,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            ),
          ),
          // Face
          Positioned(
            top: size * 0.4,
            child: Container(
              width: size * 0.5,
              height: size * 0.42,
              decoration: const BoxDecoration(color: Color(0xFFE8B084), shape: BoxShape.circle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: size * 0.16,
                    child: Container(width: size * 0.28, height: size * 0.05,
                        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(4))),
                  ),
                  Positioned(
                    left: size * 0.09,
                    top: size * 0.1,
                    child: Container(width: size * 0.05, height: size * 0.05,
                        decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle)),
                  ),
                  Positioned(
                    right: size * 0.09,
                    top: size * 0.1,
                    child: Container(width: size * 0.05, height: size * 0.05,
                        decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ),
          ),
          // Apron / body
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.78,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(size * 0.14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.lunch_dining, color: Colors.white, size: size * 0.3),
            ),
          ),
        ],
      ),
    );
  }
}