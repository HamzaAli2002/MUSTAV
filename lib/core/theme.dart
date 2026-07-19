import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors sampled directly from the real mustav.vercel.app site (screen
/// recording, pixel-sampled) — NOT a dark theme. The site runs on a warm
/// cream background with deep-maroon banded sections, a bright red CTA/
/// accent color, and a yellow highlight used for the loading screen and
/// small badges.
class AppColors {
  static const Color cream = Color(0xFFF4E0CC); // main page background
  static const Color maroon = Color(0xFF4E0018); // footer / alternating section bands / dark nav
  static const Color red = Color(0xFFF71B16); // primary CTA, "Add to Cart" bars, price accents
  static const Color yellow = Color(0xFFFED600); // loading screen bg, small badges
  static const Color orange = Color(0xFFED6F2F); // icon badges (flame/muscle/sparkle)
  static const Color ink = Color(0xFF1A1A1A); // near-black body text
  static const Color inkSoft = Color(0xFF6B5E55); // muted brown-grey secondary text
  static const Color cardWhite = Color(0xFFFDFDFD);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF2A93B);

  // Back-compat aliases so existing screens keep working unchanged.
  static const Color background = cream;
  static const Color surface = cardWhite;
  static const Color surfaceAlt = Color(0xFFEFE0CB);
  static const Color accent = red;
  static const Color accentDark = maroon;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;
  static const Color danger = Color(0xFFD32F2F);
}

class AppTheme {
  /// Bold, rounded, slightly playful display font — matches the chunky
  /// "MUSTAV" / "THE BURGER" wordmark styling on the site.
  static TextStyle display({double size = 28, Color? color, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink, height: 1.0);

  static TextStyle body({double size = 14, Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.red,
        secondary: AppColors.orange,
        surface: AppColors.cardWhite,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: display(size: 20, color: AppColors.red),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.cardWhite,
        selectedColor: AppColors.red,
        labelStyle: GoogleFonts.poppins(color: AppColors.ink, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        shape: StadiumBorder(side: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: GoogleFonts.poppins(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w700),
      ),
      dividerColor: Colors.black.withOpacity(0.08),
    );
  }
}
