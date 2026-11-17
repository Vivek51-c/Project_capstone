import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 4pt spacing scale. Screens use these instead of magic numbers.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 44;

  /// Standard horizontal page padding.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardLarge = EdgeInsets.all(lg);

  // Common gap widgets, to avoid `SizedBox(height: 16)` everywhere.
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);

  static const Widget wGapXs = SizedBox(width: xs);
  static const Widget wGapSm = SizedBox(width: sm);
  static const Widget wGapMd = SizedBox(width: md);
}

class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brLg = BorderRadius.circular(lg);
  static final BorderRadius brXl = BorderRadius.circular(xl);
  static final BorderRadius brPill = BorderRadius.circular(pill);
}

class AppShadows {
  AppShadows._();

  /// Soft, low-contrast elevation. Deliberately subtle — the brief asks for
  /// premium, not heavy.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x050F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> tinted(Color color) => [
        BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 6)),
      ];
}

class AppDuration {
  AppDuration._();

  /// Fast + professional, per the brief. Nothing over ~600ms except score
  /// count-ups, which read as data rather than decoration.
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration score = Duration(milliseconds: 900);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasis = Curves.easeOutBack;
}

/// Responsive breakpoints (brief §24). Used with LayoutBuilder to decide
/// grid column counts and max content width.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 380;  // small phones
  static const double medium = 600;   // large phones / small tablets
  static const double expanded = 900; // tablets

  static bool isCompact(double w) => w < compact;
  static bool isTablet(double w) => w >= medium;

  /// Keeps content readable on tablets instead of stretching edge to edge.
  static double contentMaxWidth(double w) => w >= expanded ? 720 : double.infinity;

  static int gridColumns(double w) {
    if (w >= expanded) return 3;
    if (w >= medium) return 2;
    return 2;
  }
}

/// Feature identity — icon + accent, used by home tiles, screen headers and
/// section accents so each tool is recognisable across the app.
enum AppFeature { jobRadar, jobMatcher, careerMatch, skillBridge, resumeBuilder, atsTuneUp }

extension AppFeatureX on AppFeature {
  String get label => switch (this) {
        AppFeature.jobRadar => 'JobRadar',
        AppFeature.jobMatcher => 'JobMatcher',
        AppFeature.careerMatch => 'CareerMatch',
        AppFeature.skillBridge => 'SkillBridge',
        AppFeature.resumeBuilder => 'ResumeBuilder',
        AppFeature.atsTuneUp => 'ATS TuneUp',
      };

  String get tagline => switch (this) {
        AppFeature.jobRadar => 'Find relevant openings across 8 job platforms.',
        AppFeature.jobMatcher => 'See how closely your resume matches a specific job.',
        AppFeature.careerMatch => 'Discover roles that fit your profile.',
        AppFeature.skillBridge => 'Identify the skills your target role needs.',
        AppFeature.resumeBuilder => 'Create an ATS-friendly professional resume.',
        AppFeature.atsTuneUp => 'Check your resume before you apply.',
      };

  IconData get icon => switch (this) {
        AppFeature.jobRadar => Icons.travel_explore_rounded,
        AppFeature.jobMatcher => Icons.join_inner_rounded,
        AppFeature.careerMatch => Icons.auto_awesome_rounded,
        AppFeature.skillBridge => Icons.insights_rounded,
        AppFeature.resumeBuilder => Icons.edit_document,
        AppFeature.atsTuneUp => Icons.verified_rounded,
      };

  Color get accent => switch (this) {
        AppFeature.jobRadar => AppColors.jobRadar,
        AppFeature.jobMatcher => AppColors.jobMatcher,
        AppFeature.careerMatch => AppColors.careerMatch,
        AppFeature.skillBridge => AppColors.skillBridge,
        AppFeature.resumeBuilder => AppColors.resumeBuilder,
        AppFeature.atsTuneUp => AppColors.atsTuneUp,
      };

  Color get accentSurface => switch (this) {
        AppFeature.jobRadar => AppColors.jobRadarSurface,
        AppFeature.jobMatcher => AppColors.jobMatcherSurface,
        AppFeature.careerMatch => AppColors.careerMatchSurface,
        AppFeature.skillBridge => AppColors.skillBridgeSurface,
        AppFeature.resumeBuilder => AppColors.resumeBuilderSurface,
        AppFeature.atsTuneUp => AppColors.atsTuneUpSurface,
      };

  String get route => switch (this) {
        AppFeature.jobRadar => '/job-radar',
        AppFeature.jobMatcher => '/job-matcher',
        AppFeature.careerMatch => '/career-match',
        AppFeature.skillBridge => '/skill-bridge',
        AppFeature.resumeBuilder => '/resume-builder',
        AppFeature.atsTuneUp => '/ats-tuneup',
      };
}
