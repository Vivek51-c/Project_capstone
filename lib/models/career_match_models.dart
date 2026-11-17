class ExtractedInfo {
  final String? name;
  final String? email;
  final String? phone;
  final String? degree;
  final String? specialization;
  final String? university;
  final String? graduationYear;
  final List<String> skills;

  ExtractedInfo({
    this.name,
    this.email,
    this.phone,
    this.degree,
    this.specialization,
    this.university,
    this.graduationYear,
    required this.skills,
  });

  factory ExtractedInfo.fromJson(Map<String, dynamic> json) => ExtractedInfo(
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        degree: json['degree'] as String?,
        specialization: json['specialization'] as String?,
        university: json['university'] as String?,
        graduationYear: json['graduation_year'] as String?,
        skills: List<String>.from(json['skills'] ?? const []),
      );
}

class JobDescriptionPart {
  final String title;
  final String description;

  JobDescriptionPart({required this.title, required this.description});

  factory JobDescriptionPart.fromJson(Map<String, dynamic> json) =>
      JobDescriptionPart(title: json['title'] as String, description: json['description'] as String);
}

class RecommendedJob {
  final String title;
  final int matchCount;
  final List<String> matchedSkills;
  final List<JobDescriptionPart> descriptions;

  RecommendedJob({
    required this.title,
    required this.matchCount,
    required this.matchedSkills,
    required this.descriptions,
  });

  factory RecommendedJob.fromJson(Map<String, dynamic> json) => RecommendedJob(
        title: json['title'] as String,
        matchCount: json['match_count'] as int,
        matchedSkills: List<String>.from(json['matched_skills'] ?? const []),
        descriptions: (json['descriptions'] as List? ?? const [])
            .map((e) => JobDescriptionPart.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CareerMatchResult {
  final ExtractedInfo extractedInfo;
  final List<RecommendedJob> recommendedJobs;

  CareerMatchResult({required this.extractedInfo, required this.recommendedJobs});

  factory CareerMatchResult.fromJson(Map<String, dynamic> json) => CareerMatchResult(
        extractedInfo: ExtractedInfo.fromJson(json['extracted_info']),
        recommendedJobs: (json['recommended_jobs'] as List? ?? const [])
            .map((e) => RecommendedJob.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
