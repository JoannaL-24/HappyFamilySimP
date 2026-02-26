class TaskTemplate {
  final int id;
  final String title;
  final String description;
  final bool proofRequired;

  TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.proofRequired,

  });

  // fetching supporting method
  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      proofRequired: json['proof_required'] ?? false,
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
    );
  }

  // storing supporting for updating Supabase
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'proof_required': proofRequired,
  };
}