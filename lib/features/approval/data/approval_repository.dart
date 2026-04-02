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
        final String path = childData?['avatar_path'] ?? Constants.defaultAvatarPath;
        
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

  Future<void> approveTask(int occurrenceId) async {
    try {
      await _supabase
          .from('task_occurrence')
          .update({'status': 'COMP'})
          .eq('id', occurrenceId);

    // TODO: increment reward for child
    } catch (e) {
      logger.e('Error approving task: $e');
      throw Exception('Failed to approve task.');
    }
  }

  Future<void> rejectTask(int occurrenceId, String? feedback) async {
    try {
      await _supabase
          .from('task_occurrence')
          .update({
            'status': 'REJC',
            'feedback': feedback,
          })
          .eq('id', occurrenceId);

    } catch (e) {
      logger.e('Error rejecting task: $e');
      throw Exception('Failed to reject task.');
    }
  }
}
