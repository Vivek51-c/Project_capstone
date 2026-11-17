class SkillBridgeResult {
  final String role;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final int requiredSkillCount;
  final int matchedSkillCount;

  SkillBridgeResult({
    required this.role,
    required this.matchedSkills,
    required this.missingSkills,
    required this.requiredSkillCount,
    required this.matchedSkillCount,
  });

  factory SkillBridgeResult.fromJson(Map<String, dynamic> json) => SkillBridgeResult(
        role: json['role'] as String,
        matchedSkills: List<String>.from(json['matched_skills'] ?? const []),
        missingSkills: List<String>.from(json['missing_skills'] ?? const []),
        requiredSkillCount: json['required_skill_count'] as int,
        matchedSkillCount: json['matched_skill_count'] as int,
      );

  double get matchRatio => requiredSkillCount == 0 ? 0 : matchedSkillCount / requiredSkillCount;
}

class LearningResourceLinks {
  final String skill;
  final String youtube;
  final String udemy;
  final String coursera;
  final String edx;

  LearningResourceLinks({
    required this.skill,
    required this.youtube,
    required this.udemy,
    required this.coursera,
    required this.edx,
  });

  factory LearningResourceLinks.fromJson(Map<String, dynamic> json) => LearningResourceLinks(
        skill: json['skill'] as String,
        youtube: json['youtube'] as String,
        udemy: json['udemy'] as String,
        coursera: json['coursera'] as String,
        edx: json['edx'] as String,
      );
}
