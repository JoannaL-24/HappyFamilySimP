import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/task_scheduler.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;

  // Fetch occurrences for a specific child, including template details
  Future<List<TaskOccurrence>> fetchChildTasks(String parentId) async {
    final response = await _supabase
        .from('task_occurrence')
        .select('''
        *,
        child:profiles!inner(id, name, avatar_path),
        task_template!inner(
          *,
          task_recurrence(*)
        )
      ''') // Corrected closing parentheses
        .eq('task_template.parent_id', parentId)
        .or('status.eq.NOTD,status.eq.COMP')
        .order('status', ascending: true)
        .order('due_date', ascending: true);

    return (response as List).map((json) {
      final childData = json['child'] as Map<String, dynamic>?;
      final String path = childData?['avatar_path'] ?? "default_avatar.png";

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
    required String resource,
    required int resourceAmount,
  }) async {
    try {
      await _supabase
          .from('task_template')
          .update({
            'parent_id': _supabase.auth.currentUser!.id,
            'title': title,
            'description': description,
            'proof_required': proofRequired,
            'resource': resource.toLowerCase(),
            'resource_amount': resourceAmount,
          })
          .eq('id', templateId);
    } catch (e) {
      debugPrint('Error updating task template: $e');
      throw Exception('Failed to save changes.');
    }
  }

  // --- UPDATE TASK OCCURRENCE ---
  // Use this when changing status (NOTD -> COMP) or a specific due date
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

  // --- ADD TASK TEMPLATE ---
  // Use this when changing the title, description, or global dates
  Future<TaskTemplate> createTemplate({
    required String title,
    required String description,
    required bool proofRequired,
    required String resource,
    required int resourceAmount,
  }) async {
    final response = await _supabase
        .from('task_template')
        .insert({
          'parent_id': _supabase.auth.currentUser!.id,
          'title': title,
          'description': description,
          'proof_required': proofRequired,
          'resource': resource.toLowerCase(),
            'resource_amount': resourceAmount,
        })
        .select()
        .single();
    return TaskTemplate.fromJson(response);
  }

  // --- ADD TASK OCCURRENCE ---
  // Use this when changing status (NOTD -> COMP) or a specific due date
  Future<TaskOccurrence> createOccurrence({
    required String childId,
    required DateTime dueDate,
    required String status,
    required int templateId,
  }) async {
    // 1. Perform the insert and select with the !inner join syntax
    final response = await _supabase
        .from('task_occurrence')
        .insert({
          'child_id': childId,
          'due_date': dueDate.toIso8601String(),
          'status': 'NOTD',
          'task_template_id': templateId,
        })
        .select('''
        *,
        task_template!inner(*),
        child:profiles(id, name, avatar_path)
      ''')
        .single();
    // 2. Extract child data to generate the avatar URL
    final childData = response['child'] as Map<String, dynamic>?;
    final String path =
        childData?['avatar_path'] ?? Constants.defaultAvatarPath;

    String publicUrl = '';
    if (path.isNotEmpty) {
      publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    }
    // 3. Map to your model using the publicUrl parameter
    return TaskOccurrence.fromJson(response, publicUrl);
  }

  // Helper function to format TimeOfDay for Postgres
  String formatTimeForDb(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return "$hours:$minutes:00";
  }

  // --- RECURRING TASK CREATION ---
  Future<void> saveRecurringTask({
    required String title,
    required String description,
    required bool proofRequired,
    required String resource,
    required int resourceAmount,

    required String childId,
    required DateTime dueDate,

    required String pattern, // 'daily', 'weekly', 'monthly'
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
    DateTime? endDate,
  }) async {
    // 1. Create the Recurrence Pattern first
    final recurrenceData = await _supabase
        .from('task_recurrence')
        .insert({
          'pattern': pattern,
          'interval': interval,
          'day_of_week': dayOfWeek,
          'day_of_month': dayOfMonth,
        })
        .select()
        .single();

    final int recurrenceId = recurrenceData['id'];

    // 2. Create the Template with the link to the recurrence
    // set last_generated_until to null for now
    if (endDate != null) {
      endDate = endDate.copyWith(
        hour: 23,
        minute: 59,
        second: 0, // Optional: reset seconds/ms for a clean comparison
        millisecond: 0,
        microsecond: 0,
      );
    }
    final templateData = await _supabase
        .from('task_template')
        .insert({
          'parent_id': _supabase.auth.currentUser!.id,
          'title': title,
          'description': description,
          'proof_required': proofRequired,
          'task_recurrence_id': recurrenceId,
          'end_date': endDate?.toIso8601String(),
          'target_time': formatTimeForDb(TimeOfDay.fromDateTime(dueDate)),
          'resource': resource.toLowerCase(),
          'resource_amount': resourceAmount,
        })
        .select()
        .single();

    final int templateId = templateData['id'];

    // 3. Generate the first 14 days of occurrences using Scheduler
    final List<DateTime> dates = TaskScheduler.generateDates(
      startDate: DateTime.now().copyWith(
        hour: dueDate.hour,
        minute: dueDate.minute,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      ),
      endDate: endDate,
      pattern: pattern,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      daysToPrepopulate: 14,
    );

    // 4. Bulk Insert the Occurrences
    if (dates.isNotEmpty) {
      final List<Map<String, dynamic>> occurrences = dates
          .map(
            (date) => {
              'child_id': childId,
              'task_template_id': templateId,
              'due_date': date.toIso8601String(),
              'status': 'NOTD',
            },
          )
          .toList();

      await _supabase.from('task_occurrence').insert(occurrences);

      // 5. Update the Template's "last_generated_until" so the Cron job knows where to pick up
      await _supabase
          .from('task_template')
          .update({'last_generated_until': dates.last.toIso8601String()})
          .eq('id', templateId);
    }
  }

  Future<void> deleteTasksBulk(
    List<int> occurrenceIds,
    List<int> templateIds,
  ) async {
    // 1. Delete all occurrences whose IDs are in our list
    await _supabase
        .from('task_occurrence')
        .delete()
        .inFilter('id', occurrenceIds);

    // 2. Delete the corresponding templates
    // await _supabase.from('task_template').delete().inFilter('id', templateIds);
    return;
  }

  Future<void> updateRecurringSeries({
  required int templateId,
  required int? recurrenceId,
  required String title,
  required String description,
  required bool proofRequired,
  required String resource,
  required int resourceAmount,
  required String childId,
  required DateTime startDate,
  required DateTime oldDueDate,
  required String pattern,
  required int interval,
  List<int>? dayOfWeek,
  List<int>? dayOfMonth,
  DateTime? endDate,
  DateTime? oldEndDate,
  required String updateScope, // 'rewrite' or 'alter'
}) async {
  
  // 1. Handle "Recurring to Single" Breakaway
  if (pattern.toLowerCase() == 'never') {
    final int? oldRecurrenceId = recurrenceId;

    await _supabase.from('task_occurrence')
        .delete()
        .eq('task_template_id', templateId)
        .eq('status', 'NOTD')
        .gt('due_date', oldDueDate.toIso8601String());

    await _supabase.from('task_template').update({
      'title': title, 'description': description, 'proof_required': proofRequired, 'resource': resource.toLowerCase(), 'resource_amount': resourceAmount,
      'task_recurrence_id': null, 'end_date': null, 'last_generated_until': null, 'target_time': null,
    }).eq('id', templateId);

    if (oldRecurrenceId != null) {
      await _supabase.from('task_recurrence').delete().eq('id', oldRecurrenceId);
    }

    await _supabase.from('task_occurrence').insert({
      'task_template_id': templateId,
      'child_id': childId,
      'due_date': startDate.toIso8601String(),
      'status': 'NOTD',
    });
    return;
  }

  // 2. Prep data for updates
  final ruleData = {
    'pattern': pattern,
    'interval': interval,
    'day_of_week': dayOfWeek,
    'day_of_month': dayOfMonth,
  };
  final String targetTime = "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}:00";
  int currentRecId;

// 3. Mode: "ALTER" (Just update metadata and time, no row deletion)
  if (updateScope == 'alter') {
  final String targetTime = "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}:00";

  // 1. Update the Template metadata and bounds
  await _supabase.from('task_template').update({
    'title': title,
    'description': description,
    'proof_required': proofRequired,
    'resource': resource.toLowerCase(),
    'resource_amount': resourceAmount,
    'target_time': targetTime,
    'end_date': endDate?.toIso8601String(),
    // We nullify last_generated_until if the end_date moved earlier 
    // to ensure the scheduler stays in sync
    if (endDate != null) 'last_generated_until': null, 
  }).eq('id', templateId);

  // 2. DELETE occurrences that are now outside the new end_date
  // (Occurrence > New End Date)
  if (endDate != null) {
    await _supabase.from('task_occurrence')
        .delete()
        .eq('task_template_id', templateId)
        .eq('status', 'NOTD')
        .gt('due_date', endDate.toIso8601String());
  }

  // 3. UPDATE TIME for occurrences in the valid window
  // (Current Task Date <= Occurrence <= New End Date)
  final futureTasks = await _supabase.from('task_occurrence')
      .select('id, due_date')
      .eq('task_template_id', templateId)
      .eq('status', 'NOTD')
      .gte('due_date', startDate.toIso8601String());

  for (var task in futureTasks) {
    DateTime occDate = DateTime.parse(task['due_date']);
    
    // Only update if it falls within the new end_date (or if there is no end_date)
    if (endDate == null || !occDate.isAfter(endDate)) {
      DateTime mergedDate = DateTime(
        occDate.year, 
        occDate.month, 
        occDate.day, 
        startDate.hour, 
        startDate.minute, 
        0
      );
      
      await _supabase.from('task_occurrence')
          .update({'due_date': mergedDate.toIso8601String()})
          .eq('id', task['id']);
    }
  }

  return;
}

  // 4. Mode: "REWRITE" (Nuke future and Pave)
  if (updateScope == 'rewrite') {
    final oldestOccurrence = await _supabase
          .from('task_occurrence')
          .select('due_date')
          .eq('task_template_id', templateId)
          .order('due_date', ascending: true)
          .limit(1)
          .maybeSingle();

    await _supabase.from('task_occurrence')
        .delete()
        .eq('task_template_id', templateId)
        .eq('status', 'NOTD');

    if (recurrenceId == null) {
      final rec = await _supabase.from('task_recurrence').insert(ruleData).select().single();
      currentRecId = rec['id'];
    } else {
      await _supabase.from('task_recurrence').update(ruleData).eq('id', recurrenceId);
      currentRecId = recurrenceId;
    }

    await _supabase.from('task_template').update({
      'title': title, 'description': description, 'proof_required': proofRequired,
      'task_recurrence_id': currentRecId, 'target_time': targetTime, 'end_date': endDate?.toIso8601String(),
      'resource': resource.toLowerCase(), 'resource_amount': resourceAmount,
    }).eq('id', templateId);
  //TODO: alter end date, adding problem
    final List<DateTime> nextDates = TaskScheduler.generateDates(
      startDate: oldestOccurrence != null ? DateTime.parse(oldestOccurrence['due_date']) : startDate,
      endDate: endDate ?? startDate.add(const Duration(days: 365)),
      pattern: pattern, interval: interval, dayOfWeek: dayOfWeek, dayOfMonth: dayOfMonth, daysToPrepopulate: 14,
    );

    if (nextDates.isNotEmpty) {
      final occurrences = nextDates.map((date) => {
        'child_id': childId, 'task_template_id': templateId, 'due_date': date.toIso8601String(), 'status': 'NOTD',
      }).toList();
      await _supabase.from('task_occurrence').insert(occurrences);
      await _supabase.from('task_template')
          .update({'last_generated_until': nextDates.last.toIso8601String()})
          .eq('id', templateId);
    }
  }
}
}
