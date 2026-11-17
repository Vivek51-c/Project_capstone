class Finding {
  final String level; // "success" | "warning"
  final String message;

  Finding({required this.level, required this.message});

  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
      level: json['level'] as String, message: json['message'] as String);

  bool get isSuccess => level == 'success';
}

class AtsStep {
  final int step;
  final String title;
  final List<Finding> findings;

  AtsStep({required this.step, required this.title, required this.findings});

  factory AtsStep.fromJson(Map<String, dynamic> json) => AtsStep(
        step: json['step'] as int,
        title: json['title'] as String,
        findings: (json['findings'] as List? ?? const [])
            .map((e) => Finding.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get warningCount => findings.where((f) => !f.isSuccess).length;
}

class LocalAtsResult {
  final List<AtsStep> steps;

  LocalAtsResult({required this.steps});

  factory LocalAtsResult.fromJson(Map<String, dynamic> json) => LocalAtsResult(
        steps: (json['steps'] as List? ?? const [])
            .map((e) => AtsStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get totalWarnings => steps.fold(0, (sum, s) => sum + s.warningCount);
}

class CategoryFeedback {
  final List<String> positives;
  final List<String> negatives;

  CategoryFeedback({required this.positives, required this.negatives});

  factory CategoryFeedback.fromJson(Map<String, dynamic> json) =>
      CategoryFeedback(
        positives: List<String>.from(json['positives'] ?? const []),
        negatives: List<String>.from(json['negatives'] ?? const []),
      );
}

class AiAtsResult {
  final int? atsScore;
  final Map<String, CategoryFeedback> categories;

  AiAtsResult({required this.atsScore, required this.categories});

  factory AiAtsResult.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as Map<String, dynamic>? ?? {});
    return AiAtsResult(
      atsScore: json['ats_score'] as int?,
      categories: rawCategories.map(
        (key, value) => MapEntry(
            key, CategoryFeedback.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}

class SavedAtsAnalysis {
  final String id;
  final String resumeVersionId;
  final String mode;
  final int? score;
  final Map<String, dynamic> analysis;
  final DateTime createdAt;

  const SavedAtsAnalysis({
    required this.id,
    required this.resumeVersionId,
    required this.mode,
    required this.score,
    required this.analysis,
    required this.createdAt,
  });

  factory SavedAtsAnalysis.fromJson(Map<String, dynamic> json) =>
      SavedAtsAnalysis(
        id: json['id'] as String,
        resumeVersionId: json['resume_version_id'] as String,
        mode: json['mode'] as String,
        score: json['score'] as int?,
        analysis: Map<String, dynamic>.from(json['analysis'] as Map),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
