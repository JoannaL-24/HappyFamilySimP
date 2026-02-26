class TaskTemplate {
  final int id;
  final String title;
  final String description;
  final bool proofRequired;
  final DateTime startDate;
  final DateTime endDate;

  TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.proofRequired,
    required this.startDate,
    required this.endDate,
  });

  // fetching supporting method
  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      proofRequired: json['proof_required'] ?? false,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  // copy supporting for editing feature
  TaskTemplate copyWith({
    String? title,
    String? description,
    bool? proofRequired,
  }) {
    return TaskTemplate(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      proofRequired: proofRequired ?? this.proofRequired,
      startDate: startDate,
      endDate: endDate
    );
  }

  // storing supporting for updating Supabase
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'proof_required': proofRequired,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
}