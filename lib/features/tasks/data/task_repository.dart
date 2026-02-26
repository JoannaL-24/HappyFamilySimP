import 'package:flutter/cupertino.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;

  // Fetch occurrences for a specific child, including template details
  Future<List<TaskOccurrence>> fetchChildTasks(String parentId) async {
    final response = await _supabase
        .from('task_occurrence')
        .select('*, task_template!inner(*)')
        .eq('task_template.parent_id', parentId)
        .order('due_date', ascending: true);
    debugPrint(response.toString());
    return (response as List)
        .map((json) => TaskOccurrence.fromJson(json))
        .toList();
  }

  // --- UPDATE TASK TEMPLATE ---
  // Use this when changing the title, description, or global dates
  Future<void> updateTemplate(TaskTemplate template) async {
    await _supabase
        .from('task_template')
        .update(template.toJson()) // Converts model to Map
        .eq('id', template.id);
  }

  // --- UPDATE TASK OCCURRENCE ---
  // Use this when changing status (NOTD -> DONE) or a specific due date
  Future<void> updateOccurrence(TaskOccurrence occurrence) async {
    await _supabase
        .from('task_occurence')
        .update({
          'status': occurrence.status,
          'due_date': occurrence.dueDate.toIso8601String(),
        })
        .eq('id', occurrence.id);
  }
}
