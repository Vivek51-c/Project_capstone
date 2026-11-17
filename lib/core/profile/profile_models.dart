/// Mirrors backend `app.schemas.profile.EducationItem`.
class EducationItem {
  final String school;
  final String degree;
  final String? fieldOfStudy;
  final int? startYear;
  final int? endYear;

  const EducationItem({
    required this.school,
    required this.degree,
    this.fieldOfStudy,
    this.startYear,
    this.endYear,
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) => EducationItem(
        school: json['school'] as String,
        degree: json['degree'] as String,
        fieldOfStudy: json['field_of_study'] as String?,
        startYear: json['start_year'] as int?,
        endYear: json['end_year'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'school': school,
        'degree': degree,
        if (fieldOfStudy != null && fieldOfStudy!.isNotEmpty) 'field_of_study': fieldOfStudy,
        if (startYear != null) 'start_year': startYear,
        if (endYear != null) 'end_year': endYear,
      };

  EducationItem copyWith({
    String? school,
    String? degree,
    String? fieldOfStudy,
    int? startYear,
    int? endYear,
  }) =>
      EducationItem(
        school: school ?? this.school,
        degree: degree ?? this.degree,
        fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
        startYear: startYear ?? this.startYear,
        endYear: endYear ?? this.endYear,
      );
}

/// Mirrors backend `app.schemas.profile.ExperienceItem`.
class ExperienceItem {
  final String title;
  final String company;
  final String? startDate;
  final String? endDate;
  final bool currentlyWorking;
  final String? description;

  const ExperienceItem({
    required this.title,
    required this.company,
    this.startDate,
    this.endDate,
    this.currentlyWorking = false,
    this.description,
  });

  factory ExperienceItem.fromJson(Map<String, dynamic> json) => ExperienceItem(
        title: json['title'] as String,
        company: json['company'] as String,
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        currentlyWorking: json['currently_working'] as bool? ?? false,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'company': company,
        if (startDate != null && startDate!.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate!.isNotEmpty) 'end_date': endDate,
        'currently_working': currentlyWorking,
        if (description != null && description!.isNotEmpty) 'description': description,
      };

  ExperienceItem copyWith({
    String? title,
    String? company,
    String? startDate,
    String? endDate,
    bool? currentlyWorking,
    String? description,
  }) =>
      ExperienceItem(
        title: title ?? this.title,
        company: company ?? this.company,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        currentlyWorking: currentlyWorking ?? this.currentlyWorking,
        description: description ?? this.description,
      );
}

/// Mirrors backend `app.schemas.profile.ProfileOut`. `fullName`/`email`
/// come from the User row; everything else from the Profile row -- the
/// backend joins these for us so the client doesn't need to know that.
class ProfileData {
  final String userId;
  final String fullName;
  final String email;
  final List<EducationItem> education;
  final List<String> skills;
  final List<ExperienceItem> experience;
  final List<String> careerInterests;
  final DateTime updatedAt;

  const ProfileData({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.education,
    required this.skills,
    required this.experience,
    required this.careerInterests,
    required this.updatedAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        education: (json['education'] as List)
            .map((e) => EducationItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: List<String>.from(json['skills'] as List),
        experience: (json['experience'] as List)
            .map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        careerInterests: List<String>.from(json['career_interests'] as List),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Roughly how "complete" this profile looks, for a simple progress
  /// indicator -- purely a frontend presentation choice, not a backend field.
  double get completionRatio {
    final checks = <bool>[
      fullName.trim().isNotEmpty,
      education.isNotEmpty,
      skills.isNotEmpty,
      experience.isNotEmpty,
      careerInterests.isNotEmpty,
    ];
    return checks.where((c) => c).length / checks.length;
  }
}

/// Mirrors backend `app.schemas.profile.ProfileUpdateRequest`. This is a
/// PARTIAL update: a field left null here is omitted from the JSON body
/// entirely, so the backend leaves that section untouched. Pass an empty
/// list (not null) to explicitly clear a section.
class ProfileUpdate {
  final String? fullName;
  final List<EducationItem>? education;
  final List<String>? skills;
  final List<ExperienceItem>? experience;
  final List<String>? careerInterests;

  const ProfileUpdate({
    this.fullName,
    this.education,
    this.skills,
    this.experience,
    this.careerInterests,
  });

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full_name': fullName,
        if (education != null) 'education': education!.map((e) => e.toJson()).toList(),
        if (skills != null) 'skills': skills,
        if (experience != null) 'experience': experience!.map((e) => e.toJson()).toList(),
        if (careerInterests != null) 'career_interests': careerInterests,
      };
}
