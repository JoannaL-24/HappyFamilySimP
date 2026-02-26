import 'package:happy_family_sim/features/tasks/model/task_template.dart';


class TaskOccurrence {
  final int id;
  final String childName;
  final String childAvatar;
  final DateTime dueDate;
  final String status;
  final int templateId;
  final TaskTemplate? template; 

  TaskOccurrence({
    required this.id,
    required this.childName,
    this.childAvatar = '',
    required this.dueDate,
    required this.status,
    required this.templateId,
    required this.template,
  });

  // fetching supporting method
  factory TaskOccurrence.fromJson(Map<String, dynamic> json, String avatarUrl) {
    final childData = json['child'] as Map<String, dynamic>?;
    return TaskOccurrence(
      id: json['id'],
      childName: childData?['name'] ?? 'Unknown',
      childAvatar: avatarUrl,
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      templateId: json['task_template_id'],
      template: json['task_template'] != null 
          ? TaskTemplate.fromJson(json['task_template']) 
          : null,
    );
  }

  // copy supporting for editing feature
  TaskOccurrence copyWith({
    DateTime? dueDate,
    String? status,
  }) {
    return TaskOccurrence(
      id: id,
      childName: childName,
      childAvatar: childAvatar,
      templateId: templateId,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      template: template,
    );
  }

  // storing supporting for updating Supabase
  Map<String, dynamic> toJson() => {
    'due_date': dueDate.toIso8601String(),
    'status': status,
  };
}