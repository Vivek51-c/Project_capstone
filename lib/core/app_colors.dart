import 'package:flutter/material.dart';

/// Single source of truth for colour in the app.
///
/// Rule: screens never hardcode a Color. They use these tokens, or better,
/// pull from `Theme.of(context).colorScheme`.
class AppColors {
  AppColors._();

  // --- Brand ramp (evolved from the original 0xFF2F6FED, deeper + richer) ---
  static const Color primary = Color(0xFF1D4FD8);
  static const Color primaryDark = Color(0xFF163BA6);
  static const Color primaryLight = Color(0xFF4B7BF5);
  /// Tinted background for primary-flavoured surfaces (icon wells, banners).
  static const Color primarySurface = Color(0xFFEAF0FE);

  static const Color secondary = Color(0xFF6D4AFF);
  static const Color secondarySurface = Color(0xFFEFEBFF);

  // --- Neutrals ---
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  /// Slightly recessed surface, for wells inside cards.
  static const Color surfaceAlt = Color(0xFFF0F3F9);
  static const Color border = Color(0xFFE2E8F2);
  static const Color borderStrong = Color(0xFFCBD5E6);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF5B6B85);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Semantic ---
  static const Color success = Color(0xFF12A374);
  static const Color successSurface = Color(0xFFE3F7F0);
  static const Color warning = Color(0xFFD98A0B);
  static const Color warningSurface = Color(0xFFFDF3E2);
  static const Color error = Color(0xFFDC4A3D);
  static const Color errorSurface = Color(0xFFFCEBE9);
  static const Color info = Color(0xFF2B7FD4);
  static const Color infoSurface = Color(0xFFE7F2FC);

  // --- Per-feature accents -------------------------------------------------
  // Used ONLY as icon/accent tints so each tool is recognisable while the
  // product still reads as one thing. Never used for page backgrounds.
  static const Color jobRadar = Color(0xFF0E9AA7);
  static const Color jobRadarSurface = Color(0xFFE3F5F6);
  static const Color jobMatcher = Color(0xFF1D4FD8);
  static const Color jobMatcherSurface = Color(0xFFEAF0FE);
  static const Color careerMatch = Color(0xFF7C3AED);
  static const Color careerMatchSurface = Color(0xFFF1EAFE);
  static const Color skillBridge = Color(0xFFC2710C);
  static const Color skillBridgeSurface = Color(0xFFFCF2E3);
  static const Color resumeBuilder = Color(0xFF0E8A5F);
  static const Color resumeBuilderSurface = Color(0xFFE3F5EE);
  static const Color atsTuneUp = Color(0xFFD1447E);
  static const Color atsTuneUpSurface = Color(0xFFFCEAF2);

  // --- Gradients (used sparingly: hero header + score rings only) ---
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4FD8), Color(0xFF4B3FD4)],
  );

  /// Score colour ramp, shared by every gauge/bar so a "good" score is the
  /// same colour everywhere in the app.
  static Color forScore(num score) {
    if (score >= 80) return success;
    if (score >= 60) return warning;
    return error;
  }

  static Color surfaceForScore(num score) {
    if (score >= 80) return successSurface;
    if (score >= 60) return warningSurface;
    return errorSurface;
  }
}
