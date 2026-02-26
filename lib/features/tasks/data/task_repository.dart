import 'package:flutter/widgets.dart';
import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;

  // Fetch occurrences for a specific child, including template details
  Future<List<TaskOccurrence>> fetchChildTasks(String parentId) async {
    final response = await _supabase
        .from('task_occurrence')
        .select('''*,
           task_template!inner(*),
          child:profiles!inner(id, name, avatar_path)   
        ''')
        .eq('task_template.parent_id', parentId)
        .order('status', ascending: false)
        .order('due_date', ascending: true);
    return (response as List).map((json) {
      // Extract the nested child data
      final childData = json['child'] as Map<String, dynamic>?;
      final String path =
          childData?['avatar_path'] ?? Constants.defaultAvatarPath;
      // Generate the Public URL (matching your Profile page logic)
      String publicUrl = '';
      if (path.isNotEmpty) {
        publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      }
      return TaskOccurrence.fromJson(json, publicUrl);
    }).toList();
  }

  // --- UPDATE TASK TEMPLATE ---
  // Use this when changing the title, description, or global dates
  Future<void> updateTemplate({
    required int templateId,
    required String title,
    required String description,
    required bool proofRequired,
  }) async {
    try {
      await _supabase
          .from('task_template')
          .update({
            'title': title,
            'description': description,
            'proof_required': proofRequired,
          })
          .eq('id', templateId);
    } catch (e) {
      debugPrint('Error updating task template: $e');
      throw Exception('Failed to save changes.');
    }
  }

  // --- UPDATE TASK OCCURRENCE ---
  // Use this when changing status (NOTD -> DONE) or a specific due date
  Future<void> updateOccurrence({
    required int occurrenceId,
    required DateTime dueDate,
    required String status,
    required String childId,
  }) async {
    try {
      await _supabase
          .from('task_occurrence')
          .update({
            'due_date': dueDate.toIso8601String(),
            'status': status,
            'child_id': childId,
          })
          .eq('id', occurrenceId);
    } catch (e) {
      debugPrint('Error updating task occurrence: $e');
      throw Exception('Failed to update task occurrence.');
    }
  }
}
