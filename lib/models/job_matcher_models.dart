class SkillsBreakdown {
  final List<String> core;
  final List<String> important;
  final List<String> optional;

  SkillsBreakdown({required this.core, required this.important, required this.optional});

  factory SkillsBreakdown.fromJson(Map<String, dynamic> json) => SkillsBreakdown(
        core: List<String>.from(json['core'] ?? const []),
        important: List<String>.from(json['important'] ?? const []),
        optional: List<String>.from(json['optional'] ?? const []),
      );

  bool get isEmpty => core.isEmpty && important.isEmpty && optional.isEmpty;
}

class JobMatchResult {
  final int finalScore;
  final double hardPct;
  final double hardScoreContribution;
  final double softPct;
  final double softScoreContribution;
  final SkillsBreakdown matchedHardSkills;
  final SkillsBreakdown missingHardSkills;
  final List<String> matchedSoftSkills;
  final List<String> missingSoftSkills;
  final String verdict; // "excellent" | "good" | "needs_improvement"

  JobMatchResult({
    required this.finalScore,
    required this.hardPct,
    required this.hardScoreContribution,
    required this.softPct,
    required this.softScoreContribution,
    required this.matchedHardSkills,
    required this.missingHardSkills,
    required this.matchedSoftSkills,
    required this.missingSoftSkills,
    required this.verdict,
  });

  factory JobMatchResult.fromJson(Map<String, dynamic> json) => JobMatchResult(
        finalScore: json['final_score'] as int,
        hardPct: (json['hard_pct'] as num).toDouble(),
        hardScoreContribution: (json['hard_score_contribution'] as num).toDouble(),
        softPct: (json['soft_pct'] as num).toDouble(),
        softScoreContribution: (json['soft_score_contribution'] as num).toDouble(),
        matchedHardSkills: SkillsBreakdown.fromJson(json['matched_hard_skills']),
        missingHardSkills: SkillsBreakdown.fromJson(json['missing_hard_skills']),
        matchedSoftSkills: List<String>.from(json['matched_soft_skills'] ?? const []),
        missingSoftSkills: List<String>.from(json['missing_soft_skills'] ?? const []),
        verdict: json['verdict'] as String,
      );
}
