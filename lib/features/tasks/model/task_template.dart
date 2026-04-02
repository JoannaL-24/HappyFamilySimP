import 'package:flutter/material.dart';
import 'task_recurrence.dart';

class TaskTemplate {
  final int id;
  final String title;
  final String description;
  final bool proofRequired;
  final int? recurrenceId;
  final DateTime? endDate;
  final String? targetTime; // Format: "HH:mm:ss"
  final TaskRecurrence? recurrence;

  final String resource; // 'food','play', 'clean'
  final int resourceAmount;

  TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.proofRequired,
    this.recurrenceId,
    this.endDate,
    this.targetTime,
    this.recurrence,
    required this.resource,
    required this.resourceAmount,
  });

  // fetching supporting method
  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      proofRequired: json['proof_required'] ?? false,
      recurrenceId: json['task_recurrence_id'],
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      targetTime: json['target_time'],
      recurrence: json['task_recurrence'] != null
          ? TaskRecurrence.fromJson(json['task_recurrence'])
          : null,
      resource: json['resource'] ?? 'food',
      resourceAmount: json['resource_amount'] ?? 1,
    );
  }

TaskTemplate copyWith({
  String? title,
  String? description,
  bool? proofRequired,
  int? recurrenceId,
  DateTime? endDate,
  String? targetTime,
  TaskRecurrence? recurrence,
  String? resource,
  int? resourceAmount,
}) {
  return TaskTemplate(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    proofRequired: proofRequired ?? this.proofRequired,
    recurrenceId: recurrenceId ?? this.recurrenceId,
    endDate: endDate ?? this.endDate,
    targetTime: targetTime ?? this.targetTime,
    recurrence: recurrence ?? this.recurrence,
    resource: resource ?? this.resource,
    resourceAmount: resourceAmount ?? this.resourceAmount,
  );
}

  // Helper to convert targetTime string to TimeOfDay to show in the UI
  TimeOfDay? get timeOfDay {
    try {
      if (targetTime == null || !targetTime!.contains(':')) return null;
      final parts = targetTime!.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null; // Gracefully handle malformed strings
    }
  }

  // storing supporting for updating Supabase
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'proof_required': proofRequired,
    'target_time': targetTime,
    'end_date': endDate?.toIso8601String(),
    'task_recurrence_id': recurrenceId,
    'resource': resource,
    'resource_amount': resourceAmount,
  };
}
