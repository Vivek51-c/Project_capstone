class SavedJob {
  final String id;
  final String userId;
  final String title;
  final String? company;
  final String? location;
  final String? source;
  final String? jobUrl;
  final String? salary;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedJob({
    required this.id,
    required this.userId,
    required this.title,
    this.company,
    this.location,
    this.source,
    this.jobUrl,
    this.salary,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      company: json['company'] as String?,
      location: json['location'] as String?,
      source: json['source'] as String?,
      jobUrl: json['job_url'] as String?,
      salary: json['salary'] as String?,
      notes: json['notes'] as String?,
      status: (json['status'] as String?) ?? 'saved',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        if (company != null) 'company': company,
        if (location != null) 'location': location,
        if (source != null) 'source': source,
        if (jobUrl != null) 'job_url': jobUrl,
        if (salary != null) 'salary': salary,
        if (notes != null) 'notes': notes,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
