import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ChildTaskRepository {
  final _supabase = Supabase.instance.client;

  Future<List<TaskOccurrence>> fetchTasksByChildId(String childId) async {
    try {
      final response = await _supabase
          .from('task_occurrence')
          .select('''*,
            task_template!inner(*)
          ''')
          .eq('child_id', childId)
          .inFilter('status', ['NOTD', 'PEND'])
          .order('status', ascending: true)
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => TaskOccurrence.fromJson(json))
          .toList();
    } catch (e) {
      logger.e('Error fetching tasks for child: $e');
      throw Exception('Failed to fetch tasks for child.');
    }
  }

  // Update a task status (e.g., mark as NOTD, PEND, MISS, REJC, COMP)
  Future<void> updateTaskStatus(int occurrenceId, String status) async {
    try {
      final data = await _supabase
          .from('task_occurrence')
          .update({'status': status})
          .eq('id', occurrenceId)
          .select();

      if ((data as List).isEmpty) {
        // if data is empty, the ID didn't exist OR RLS blocked you
        throw Exception('No task found to update.');
      }
    } catch (e) {
      logger.e('Error updating task status: $e');
      throw Exception('Failed to update task status.');
    }
  }

  Future<void> markTaskAsMissed(int occurrenceId) async {
    try {
      await _supabase
          .from('task_occurrence')
          .update({'status': 'MISS'})
          .eq('id', occurrenceId)
          .eq('status', 'NOTD'); // Safety: only update if still 'Not Done'
    } catch (e) {
      logger.e('Error marking task as missed: $e');
      throw Exception('Failed to update missed task status.');
    }
  }
}
