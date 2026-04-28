import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ApprovalRepository {
  final _supabase = Supabase.instance.client;

  Future<List<TaskOccurrence>> fetchPendingTasks(String parentId) async {
    try {
      final response = await _supabase
          .from('task_occurrence')
          .select('''*,
            task_template!inner(*),
            child:profiles!inner(id, name, avatar_path)
          ''')
          .eq('task_template.parent_id', parentId)
          .eq('status', 'PEND')
          .order('due_date', ascending: true);

      return (response as List).map((json) {
        final childData = json['child'] as Map<String, dynamic>?;
        final String path =
            childData?['avatar_path'] ?? Constants.defaultAvatarPath;

        String publicUrl = '';
        if (path.isNotEmpty) {
          publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
        }
        return TaskOccurrence.fromJson(json, publicUrl);
      }).toList();
    } catch (e) {
      logger.e('Error fetching pending tasks: $e');
      throw Exception('Failed to fetch pending tasks.');
    }
  }

  Future<void> approveTask(TaskOccurrence task) async {
    final template = task.template;
    if (template == null) throw Exception('Task template data is missing.');

    try {
      // 1. Update the task status to COMP (Completed)
      await _supabase
          .from('task_occurrence')
          .update({
            'status': 'COMP',
            'approval_date': DateTime.now().toIso8601String(),
          })
          .eq('id', task.id);

      // 2. Fetch the current resource balance for the child
      final resourceData = await _supabase
          .from('resources')
          .select()
          .eq('child_id', task.childId)
          .single();

      // 3. Calculate new balance
      // template.resource is 'food', 'play', or 'clean' matching your table columns
      final String resourceType = template.resource;
      final int currentAmount = resourceData[resourceType] ?? 0;
      final int newAmount = currentAmount + template.resourceAmount;

      // 4. Update the resources table
      await _supabase
          .from('resources')
          .update({resourceType: newAmount})
          .eq('child_id', task.childId);
    } catch (e) {
      logger.e('Error during task approval and resource increment: $e');
      throw Exception('Failed to approve task and reward resources.');
    }
  }

  Future<void> rejectTask(int occurrenceId, String? feedback) async {
    try {
      await _supabase
          .from('task_occurrence')
          .update({
            'status': 'REJC',
            'feedback': feedback,
            'approval_date': DateTime.now().toIso8601String(),
          })
          .eq('id', occurrenceId);
    } catch (e) {
      logger.e('Error rejecting task: $e');
      throw Exception('Failed to reject task.');
    }
  }
}
