import 'package:happy_family_sim/features/tasks/model/task_template.dart';

class TaskOccurrence {
  final int id;
  final String childId;
  final String childName;
  final String childAvatar;
  final DateTime dueDate;
  final String status;
  final int templateId;
  final TaskTemplate? template; 
  final String? feedback;
  final String? proofUrl;
  final DateTime? approvalDate;

  TaskOccurrence({
    required this.id,
    required this.childId,
    required this.childName,
    this.childAvatar = '',
    required this.dueDate,
    required this.status,
    required this.templateId,
    required this.template,
    this.feedback,
    this.proofUrl,
    this.approvalDate,
  });

  // fetching supporting method
  factory TaskOccurrence.fromJson(Map<String, dynamic> json, [String? avatarUrl]) {
    final childData = json['child'] as Map<String, dynamic>?;

    return TaskOccurrence(
      id: json['id'],
      childId: childData?['id']?.toString() ?? json['child_id']?.toString() ?? '',
      childName: childData?['name'] ?? 'Unknown',
      childAvatar: avatarUrl ?? '',
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      templateId: json['task_template_id'],
      template: json['task_template'] != null
          ? TaskTemplate.fromJson(json['task_template'])
          : null,
      feedback: json['feedback'],
      proofUrl: json['proof_url'],
      approvalDate: json['approval_date'] != null
          ? DateTime.parse(json['approval_date'])
          : null,
    );
  }

  // copy supporting for editing feature
  TaskOccurrence copyWith({
    DateTime? dueDate,
    String? status,
    String? childId,
    String? childName,
    String? childAvatar,
    TaskTemplate? template,
    String? feedback,
    String? proofUrl,
    DateTime? approvalDate,
  }) {
    return TaskOccurrence(
      id: id,
      templateId: templateId,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      childAvatar: childAvatar ?? this.childAvatar,
      template: template ?? this.template,
      feedback: feedback ?? this.feedback,
      proofUrl: proofUrl ?? this.proofUrl,
      approvalDate: approvalDate ?? this.approvalDate,
    );
  }

  // storing supporting for updating Supabase
  Map<String, dynamic> toJson() => {
    'due_date': dueDate.toIso8601String(),
    'status': status,
  };
}
