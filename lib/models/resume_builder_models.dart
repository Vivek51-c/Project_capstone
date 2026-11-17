enum EnhancementTone { professional, executive, technical, creative }

extension EnhancementToneX on EnhancementTone {
  String get apiValue {
    switch (this) {
      case EnhancementTone.professional:
        return 'Professional';
      case EnhancementTone.executive:
        return 'Executive';
      case EnhancementTone.technical:
        return 'Technical';
      case EnhancementTone.creative:
        return 'Creative';
    }
  }
}

/// Fresher or Experienced resume flow.
enum ResumeType { fresher, experienced }

extension ResumeTypeX on ResumeType {
  String get apiValue => name; // 'fresher' | 'experienced'
  String get label => name == 'fresher' ? 'Fresher' : 'Experienced';
}

/// Education type: school / class10 / class12 / university
enum EducationType { school, class10, class12, university }

extension EducationTypeX on EducationType {
  String get apiValue => name;
  String get label {
    switch (this) {
      case EducationType.school:
        return 'School';
      case EducationType.class10:
        return 'Class 10th';
      case EducationType.class12:
        return 'Class 12th';
      case EducationType.university:
        return 'University / College';
    }
  }
}

class PersonalInfo {
  String name;
  String email;
  String phone;
  String location;
  String linkedin;
  String github;
  String website;
  String title;

  PersonalInfo({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.github = '',
    this.website = '',
    this.title = '',
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        linkedin: json['linkedin'] as String? ?? '',
        github: json['github'] as String? ?? '',
        website: json['website'] as String? ?? '',
        title: json['title'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin': linkedin,
        'github': github,
        'website': website,
        'title': title,
      };
}

class EducationEntry {
  EducationType educationType;
  // --- School / 10th / 12th ---
  String schoolName;
  String board;
  String passingYear;
  String percentage;
  // --- University / College ---
  String university;
  String degree;
  String fieldOfStudy;
  String location;
  String startDate;
  String endDate;
  String gpa; // CGPA
  String coursework;

  EducationEntry({
    this.educationType = EducationType.university,
    this.schoolName = '',
    this.board = '',
    this.passingYear = '',
    this.percentage = '',
    this.university = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.gpa = '',
    this.coursework = '',
  });

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    final rawType = json['education_type'] as String? ?? 'university';
    final eduType = EducationType.values.firstWhere(
      (t) => t.apiValue == rawType,
      orElse: () => EducationType.university,
    );
    return EducationEntry(
      educationType: eduType,
      schoolName: json['school_name'] as String? ?? '',
      board: json['board'] as String? ?? '',
      passingYear: json['passing_year'] as String? ?? '',
      percentage: json['percentage'] as String? ?? '',
      university: json['university'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      fieldOfStudy: json['field_of_study'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      gpa: json['gpa'] as String? ?? '',
      coursework: json['coursework'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'education_type': educationType.apiValue,
        'school_name': schoolName,
        'board': board,
        'passing_year': passingYear,
        'percentage': percentage,
        'university': university,
        'degree': degree,
        'field_of_study': fieldOfStudy,
        'location': location,
        'start_date': startDate,
        'end_date': endDate,
        'gpa': gpa,
        'coursework': coursework,
      };
}

class ExperienceEntry {
  String jobTitle;
  String company;
  String location;
  String startDate;
  String endDate;
  List<String> responsibilities;

  ExperienceEntry({
    this.jobTitle = '',
    this.company = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    List<String>? responsibilities,
  }) : responsibilities = responsibilities ?? [];

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) =>
      ExperienceEntry(
        jobTitle: json['job_title'] as String? ?? '',
        company: json['company'] as String? ?? '',
        location: json['location'] as String? ?? '',
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        responsibilities:
            List<String>.from(json['responsibilities'] ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'job_title': jobTitle,
        'company': company,
        'location': location,
        'start_date': startDate,
        'end_date': endDate,
        'responsibilities': responsibilities,
      };
}

class ProjectEntry {
  String title;
  String techStack;
  String deployment;
  String link;
  String description; // raw multi-line text, split server-side

  ProjectEntry({
    this.title = '',
    this.techStack = '',
    this.deployment = '',
    this.link = '',
    this.description = '',
  });

  factory ProjectEntry.fromJson(Map<String, dynamic> json) => ProjectEntry(
        title: json['title'] as String? ?? '',
        techStack: json['tech_stack'] as String? ?? '',
        deployment: json['deployment'] as String? ?? '',
        link: json['link'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'tech_stack': techStack,
        'deployment': deployment,
        'link': link,
        'description': description,
      };
}

class Skills {
  List<String> technical;
  List<String> soft;

  Skills({List<String>? technical, List<String>? soft})
      : technical = technical ?? [],
        soft = soft ?? [];

  factory Skills.fromJson(Map<String, dynamic> json) => Skills(
        technical: List<String>.from(json['technical'] ?? const []),
        soft: List<String>.from(json['soft'] ?? const []),
      );

  Map<String, dynamic> toJson() => {'technical': technical, 'soft': soft};
}

class CertificationEntry {
  String title;
  String issuer;
  String link;

  CertificationEntry({this.title = '', this.issuer = '', this.link = ''});

  factory CertificationEntry.fromJson(Map<String, dynamic> json) =>
      CertificationEntry(
        title: json['title'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        link: json['link'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'title': title, 'issuer': issuer, 'link': link};
}

class AdditionalInfo {
  List<String> achievements;
  List<String> hobbies;

  AdditionalInfo({List<String>? achievements, List<String>? hobbies})
      : achievements = achievements ?? [],
        hobbies = hobbies ?? [];

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) => AdditionalInfo(
        achievements: List<String>.from(json['achievements'] ?? const []),
        hobbies: List<String>.from(json['hobbies'] ?? const []),
      );

  Map<String, dynamic> toJson() =>
      {'achievements': achievements, 'hobbies': hobbies};
}

/// Mutable, in-memory form state for the whole wizard. Mirrors
/// app.schemas.resume_builder.ResumeBuilderRequest on the backend field
/// for field.
class ResumeBuilderFormState {
  PersonalInfo personal = PersonalInfo();
  String summary = '';
  List<EducationEntry> education = [];
  List<ExperienceEntry> experience = [];
  List<ProjectEntry> projects = [];
  Skills skills = Skills();
  List<CertificationEntry> certifications = [];
  AdditionalInfo extras = AdditionalInfo();

  ResumeType resumeType = ResumeType.experienced;
  bool aiEnhance = false;
  EnhancementTone tone = EnhancementTone.professional;
  String? geminiApiKey;

  ResumeBuilderFormState();

  factory ResumeBuilderFormState.fromJson(Map<String, dynamic> json) {
    final form = ResumeBuilderFormState();
    form.personal = PersonalInfo.fromJson(
        json['personal'] as Map<String, dynamic>? ?? const {});
    form.summary = json['summary'] as String? ?? '';
    form.education = (json['education'] as List? ?? const [])
        .map((item) => EducationEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    form.experience = (json['experience'] as List? ?? const [])
        .map((item) => ExperienceEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    form.projects = (json['projects'] as List? ?? const [])
        .map((item) => ProjectEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    form.skills =
        Skills.fromJson(json['skills'] as Map<String, dynamic>? ?? const {});
    form.certifications = (json['certifications'] as List? ?? const [])
        .map(
            (item) => CertificationEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    form.extras = AdditionalInfo.fromJson(
        json['extras'] as Map<String, dynamic>? ?? const {});
    form.aiEnhance = json['ai_enhance'] as bool? ?? false;
    final rawResumeType = json['resume_type'] as String?;
    form.resumeType = ResumeType.values.firstWhere(
      (v) => v.apiValue == rawResumeType,
      orElse: () => ResumeType.experienced,
    );
    final tone = json['tone'] as String?;
    form.tone = EnhancementTone.values.firstWhere(
      (value) => value.apiValue == tone,
      orElse: () => EnhancementTone.professional,
    );
    return form;
  }

  Map<String, dynamic> toJson() => {
        'personal': personal.toJson(),
        'summary': summary,
        'education': education.map((e) => e.toJson()).toList(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'skills': skills.toJson(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'extras': extras.toJson(),
        'resume_type': resumeType.apiValue,
        'ai_enhance': aiEnhance,
        'tone': tone.apiValue,
        if (geminiApiKey != null && geminiApiKey!.isNotEmpty)
          'gemini_api_key': geminiApiKey,
      };
}

class ValidationResult {
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({required this.errors, required this.warnings});

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      ValidationResult(
        errors: List<String>.from(json['errors'] ?? const []),
        warnings: List<String>.from(json['warnings'] ?? const []),
      );

  bool get isValid => errors.isEmpty;
}

class SavedResumeVersion {
  final String id;
  final int version;
  final String filename;
  final DateTime createdAt;

  const SavedResumeVersion({
    required this.id,
    required this.version,
    required this.filename,
    required this.createdAt,
  });

  factory SavedResumeVersion.fromJson(Map<String, dynamic> json) =>
      SavedResumeVersion(
        id: json['id'] as String,
        version: json['version'] as int,
        filename: json['filename'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class SavedResumeDetails {
  final SavedResumeVersion version;
  final ResumeBuilderFormState form;

  const SavedResumeDetails({required this.version, required this.form});

  factory SavedResumeDetails.fromJson(Map<String, dynamic> json) =>
      SavedResumeDetails(
        version: SavedResumeVersion.fromJson(json),
        form: ResumeBuilderFormState.fromJson(
            json['resume_data'] as Map<String, dynamic>? ?? const {}),
      );
}
