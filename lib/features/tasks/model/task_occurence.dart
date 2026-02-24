import 'package:happy_family_sim/features/tasks/model/task_template.dart';


class TaskOccurrence {
  final int id;
  final DateTime dueDate;
  final String status;
  final int templateId;
  final TaskTemplate? template; 

  TaskOccurrence({
    required this.id,
    required this.dueDate,
    required this.status,
    required this.templateId,
    required this.template,
  });

  // fetching supporting method
  factory TaskOccurrence.fromJson(Map<String, dynamic> json) {
    return TaskOccurrence(
      id: json['id'],
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      templateId: json['template_id'],
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