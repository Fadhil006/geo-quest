import 'dart:ui';

/// GeoQuest Design Tokens — Color Palette
/// Premium dark theme with neon accent highlights
class AppColors {
  AppColors._();

  // ── Background Shades ──
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF111328);
  static const Color surfaceLight = Color(0xFF1A1F38);
  static const Color card = Color(0xFF161A2E);
  static const Color cardHover = Color(0xFF1E2340);

  // ── Neon Accents ──
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFFBB86FC);
  static const Color neonPink = Color(0xFFFF2D87);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color neonYellow = Color(0xFFFFE143);

  // ── Primary Gradient ──
  static const Color gradientStart = Color(0xFF6C63FF);
  static const Color gradientMid = Color(0xFF9D4EDD);
  static const Color gradientEnd = Color(0xFFFF2D87);

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C5);
  static const Color textMuted = Color(0xFF6B6F82);

  // ── Status Colors ──
  static const Color success = Color(0xFF39FF14);
  static const Color warning = Color(0xFFFFE143);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF00F5FF);

  // ── Glassmorphism ──
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassOverlay = Color(0x0DFFFFFF);

  // ── Difficulty Colors ──
  static const Color difficultyEasy = Color(0xFF39FF14);
  static const Color difficultyMedium = Color(0xFFFFE143);
  static const Color difficultyHard = Color(0xFFFF6B35);
  static const Color difficultyExpert = Color(0xFFFF2D87);

  // ── Map Colors ──
  static const Color geofenceActive = Color(0x3300F5FF);
  static const Color geofenceBorder = Color(0xFF00F5FF);
  static const Color markerLocked = Color(0xFF6B6F82);
  static const Color markerUnlocked = Color(0xFF39FF14);

  // ── Gradients ──
  static const List<Color> primaryGradient = [gradientStart, gradientEnd];
  static const List<Color> cyanGradient = [Color(0xFF00F5FF), Color(0xFF6C63FF)];
  static const List<Color> pinkGradient = [Color(0xFFFF2D87), Color(0xFF9D4EDD)];
  static const List<Color> greenGradient = [Color(0xFF39FF14), Color(0xFF00F5FF)];
  static const List<Color> backgroundGradient = [
    Color(0xFF0A0E21),
    Color(0xFF111328),
    Color(0xFF0D1117),
  ];
}

