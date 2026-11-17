import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralised type scale.
///
/// Screens must read styles via `Theme.of(context).textTheme.*` rather than
/// constructing TextStyle inline (the old code had ~40 ad-hoc styles).
///
/// Mapping from the design names in the brief to Material 3 slots:
///   Display     -> displaySmall
///   Headline    -> headlineMedium / headlineSmall
///   Title       -> titleLarge / titleMedium
///   Subtitle    -> titleSmall
///   Body        -> bodyLarge / bodyMedium
///   Body Small  -> bodySmall
///   Label       -> labelLarge / labelMedium
///   Caption     -> labelSmall
class AppTypography {
  AppTypography._();

  /// Using the platform default font keeps the bundle small and avoids a
  /// google_fonts dependency + network fetch. Swap `fontFamily` here if you
  /// later add a bundled typeface — it only needs changing in this one place.
  static const String? fontFamily = null;

  static const TextTheme textTheme = TextTheme(
    // Display — hero headline only
    displaySmall: TextStyle(
      fontSize: 32,
      height: 1.18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: AppColors.textPrimary,
    ),

    // Headline — screen titles, big numbers
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.textPrimary,
    ),

    // Title — card titles, section headers
    titleLarge: TextStyle(
      fontSize: 18,
      height: 1.33,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.375,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // Subtitle
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),

    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      height: 1.46,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),

    // Label — buttons, chips
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    // Caption / overline-ish
    labelSmall: TextStyle(
      fontSize: 11.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: AppColors.textTertiary,
    ),
  );
}

/// Convenience accessors so screens read naturally:
///   context.text.titleLarge
extension TextThemeX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
