import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme is the single source of truth for all visual tokens in Seri-Helper V2.
/// Colours, typography, spacing, shadows, and glassmorphism helpers all live here.
class AppTheme {
  AppTheme._();

  // ── COLOUR PALETTE ─────────────────────────────────────────────────────────
  static const Color forestGreen   = Color(0xFF1B3A20); // Primary dark green
  static const Color leafAccent    = Color(0xFF4CAF76); // Bright leaf green CTA
  static const Color earthBrown    = Color(0xFFDE7E4B); // Vibrant terracotta/clay accent
  static const Color offWhite      = Color(0xFFF4F7F4); // Background (reduces glare)
  static const Color darkSurface   = Color(0xFF0F1E12); // Darkest surface
  static const Color cardSurface   = Color(0xFF1A2E1C); // Card background
  static const Color glassWhite    = Color(0x18FFFFFF); // Glassmorphism fill
  static const Color glassBorder   = Color(0x30FFFFFF); // Glassmorphism border

  // Status colours
  static const Color optimal       = Color(0xFF2E7D32); // Green — all good
  static const Color optimalLight  = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFF9A825); // Amber — borderline
  static const Color critical      = Color(0xFFC62828); // Red — action needed
  static const Color criticalLight = Color(0xFFEF5350);
  static const Color troublePurple  = Color(0xFFCE93D8); // Premium lavender/purple for troubleshooting

  // Text colours
  static const Color textPrimary   = Color(0xFFF0F4F0);
  static const Color textSecondary = Color(0xFFAFC9B4);
  static const Color textMuted     = Color(0xFF6B8F71);

  // ── GRADIENTS ──────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F1E12), Color(0xFF1B3A20)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient leafGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF76)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient soilGradient = LinearGradient(
    colors: [Color(0xFF8D4F2A), Color(0xFFDE7E4B)], // High-contrast fertile soil to warm terracotta
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yieldGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── BORDER RADIUS ──────────────────────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 14.0;
  static const double radiusLg  = 20.0;
  static const double radiusXl  = 28.0;

  // ── SHADOWS ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
    BoxShadow(color: leafAccent.withOpacity(0.06), blurRadius: 40, spreadRadius: 2),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(color: leafAccent.withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
  ];

  static List<BoxShadow> get criticalGlowShadow => [
    BoxShadow(color: critical.withOpacity(0.3), blurRadius: 16, spreadRadius: 1),
  ];

  // ── TYPOGRAPHY ─────────────────────────────────────────────────────────────
  static TextStyle headline1(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5);

  static TextStyle headline2(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3);

  static TextStyle headline3(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary);

  static TextStyle numericHero(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 52, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.5);

  static TextStyle numericMed(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary);

  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, color: textPrimary, height: 1.6);

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, color: textSecondary, height: 1.5);

  static TextStyle labelSmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted,
          letterSpacing: 0.8, height: 1.2);

  static TextStyle labelCaps(BuildContext context) =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: textMuted,
          letterSpacing: 1.4);

  // ── THEME DATA ─────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkSurface,
    colorScheme: const ColorScheme.dark(
      primary: leafAccent,
      secondary: earthBrown,
      surface: cardSurface,
      error: criticalLight,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: leafAccent.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: leafAccent, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: textMuted, fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: leafAccent);
        }
        return const IconThemeData(color: textMuted);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: leafAccent,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardSurface,
      selectedColor: leafAccent.withOpacity(0.2),
      side: const BorderSide(color: glassBorder),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: leafAccent,
      inactiveTrackColor: glassWhite,
      thumbColor: leafAccent,
      overlayColor: leafAccent.withOpacity(0.15),
    ),
  );

  // ── STATUS COLOR HELPERS ────────────────────────────────────────────────────
  /// Returns a status colour based on a normalized score (0.0–1.0).
  static Color scoreColor(double score) {
    if (score >= 0.70) return optimalLight;
    if (score >= 0.45) return warning;
    return criticalLight;
  }

  /// Returns a colour for a percentage gauge (0–100).
  static Color gaugeColor(double pct) => scoreColor(pct / 100.0);
}
