import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/features/tasks/model/task_category.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/task_scheduler.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;

  Future<List<TaskCategory>> fetchTaskCategories(String parentId) async {
    if (parentId.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('task_category')
        .select('id, name, color')
        .eq('parent_id', parentId)
        .order('name', ascending: true);

    return (response as List)
        .map((row) => TaskCategory.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<TaskCategory> addTaskCategory({
    required String parentId,
    required String name,
    required String color,
  }) async {
    try {
      final response = await _supabase
          .from('task_category')
          .insert({
            'name': name,
            'color': color,
            'parent_id': parentId,
          })
          .select('id, name, color')
          .single();

      return TaskCategory.fromJson(response);
    } on PostgrestException catch (e) {
      if (_isDuplicateCategoryNameError(e)) {
        throw Exception('A category named "$name" already exists.');
      }
      rethrow;
    }
  }

  Future<TaskCategory> updateTaskCategory({
    required int id,
    required String parentId,
    required String name,
    required String color,
  }) async {
    if (parentId.isEmpty) {
      throw Exception('Cannot update category before the parent profile loads.');
    }

    try {
      final response = await _supabase
          .from('task_category')
          .update({
            'name': name,
            'color': color,
          })
          .eq('id', id)
          .eq('parent_id', parentId)
          .select('id, name, color');

      final rows = response as List;
      if (rows.isEmpty) {
        throw Exception(
          'Category was not updated. The row was not found for this parent, or the task_category UPDATE policy blocked it.',
        );
      }

      return TaskCategory.fromJson(Map<String, dynamic>.from(rows.first));
    } on PostgrestException catch (e) {
      if (_isDuplicateCategoryNameError(e)) {
        throw Exception('A category named "$name" already exists.');
      }
      rethrow;
    }
  }

  bool _isDuplicateCategoryNameError(PostgrestException error) {
    return error.code == '23505' ||
        error.message.toLowerCase().contains('duplicate key');
  }

  Future<void> deleteTaskCategory({
    required int id,
    required String parentId,
  }) async {

    await _supabase
        .from('task_category')
        .delete()
        .eq('id', id)
        .eq('parent_id', parentId);
  }

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
        .or('status.eq.NOTD,status.eq.MISS, status.eq.COMP')
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

  // Fetch occurrences for analytics within a date range
  Future<List<TaskOccurrence>> fetchParentTaskHistory(String parentId) async {
    if (parentId.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('task_occurrence')
        .select('''
          *,
          child:profiles!inner(id, name, avatar_path),
          task_template!inner(
            *,
            task_recurrence(*)
          )
        ''')
        .eq('task_template.parent_id', parentId)
        .inFilter('status', ['COMP', 'MISS', 'REJC'])
        .order('due_date', ascending: false);

    return (response as List).map((json) {
      final childData = json['child'] as Map<String, dynamic>?;
      final String path = childData?['avatar_path'] ?? Constants.defaultAvatarPath;

      String publicUrl = '';
      if (path.isNotEmpty) {
        publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      }

      return TaskOccurrence.fromJson(json, publicUrl);
    }).toList();
  }

  // Fetch occurrences for analytics within a date range
  Future<List<TaskOccurrence>> fetchAnalyticsData({
    required String parentId,
    String? childId,
    required DateTime start,
    required DateTime end,
  }) async {
    final adjustedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    var query = _supabase
        .from('task_occurrence')
        .select('''
          *,
          child:profiles!inner(id, name, avatar_path),
          task_template!inner(
            *,
            task_recurrence(*)
          )
        ''')
        .eq('task_template.parent_id', parentId)
        .gte('due_date', start.toIso8601String())
        .lte('due_date', adjustedEnd.toIso8601String());

    if (childId != null && childId != 'All Children') {
      query = query.eq('child_id', childId);
    }

    final response = await query.order('due_date', ascending: true);

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
    int? categoryId,
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
            'category_id': categoryId,
          })
          .eq('id', templateId)
          .select('id')
          .single();
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
          .eq('id', occurrenceId)
          .select('id')
          .single();
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
    int? categoryId,
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
          'category_id': categoryId,
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
    int? categoryId,

    required String childId,
    required DateTime dueDate,

    required String pattern, // 'Daily', 'Weekly', 'Monthly'
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
    DateTime? endDate,
  }) async {
    final normalizedPattern = _normalizePattern(pattern);
    if (!_isRecurringPattern(normalizedPattern)) {
      throw ArgumentError('Invalid recurring pattern: $pattern');
    }

    // 1. Create the Recurrence Pattern first
    final recurrenceData = await _supabase
        .from('task_recurrence')
        .insert({
          'pattern': normalizedPattern,
          'interval': interval,
          'day_of_week': dayOfWeek,
          'day_of_month': dayOfMonth,
        })
        .select()
        .single();

    final int recurrenceId = recurrenceData['id'];

    // 2. Create the Template with the link to the recurrence
    // set last_generated_until to null for now
    endDate = _endOfDay(endDate);
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
          'category_id': categoryId,
        })
        .select()
        .single();

    final int templateId = templateData['id'];

    // 3. Generate the first 14 days of occurrences using Scheduler
    final List<DateTime> dates = TaskScheduler.generateDates(
      startDate: dueDate.copyWith(
        hour: dueDate.hour,
        minute: dueDate.minute,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      ),
      endDate: endDate,
      pattern: normalizedPattern,
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
    int? categoryId,
    required String childId,
    required DateTime startDate,
    required DateTime oldDueDate,
    required String pattern,
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
    DateTime? endDate,
    DateTime? oldEndDate,
    required String updateScope,
    bool updateChildAssignments = false,
    bool syncGeneratedOccurrences = false,
  }) async {
    final normalizedPattern = _normalizePattern(pattern);
    final normalizedEndDate = _endOfDay(endDate);
    final targetTime = _formatTimeForDate(startDate);

    if (updateScope == 'bounds') {
      await _updateSeriesMetadataAndBounds(
        templateId: templateId,
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: resource,
        resourceAmount: resourceAmount,
        categoryId: categoryId,
        childId: childId,
        updateChildAssignments: updateChildAssignments,
        endDate: normalizedEndDate,
        startDate: startDate,
        pattern: normalizedPattern,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
        syncGeneratedOccurrences: syncGeneratedOccurrences,
      );
      return;
    }

    if (updateScope == 'template') {
      await _updateTemplateMetadata(
        templateId: templateId,
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: resource,
        resourceAmount: resourceAmount,
        categoryId: categoryId,
        childId: childId,
        updateChildAssignments: updateChildAssignments,
      );
      return;
    }

    if (normalizedPattern != 'Never' && !_isRecurringPattern(normalizedPattern)) {
      throw ArgumentError('Invalid recurring pattern: $pattern');
    }

    if (normalizedPattern == 'Never') {
      final newTemplateId = await _insertTaskTemplate(
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: resource,
        resourceAmount: resourceAmount,
        categoryId: categoryId,
      );

      await _supabase.from('task_occurrence').insert({
        'task_template_id': newTemplateId,
        'child_id': childId,
        'due_date': startDate.toIso8601String(),
        'status': 'NOTD',
      });

      await _capTemplateBefore(templateId, oldDueDate);
      await _deletePendingFutureOccurrences(templateId, oldDueDate);
      await _deleteTemplateAndRecurrenceIfUnused(
        templateId: templateId,
        recurrenceId: recurrenceId,
      );
      return;
    }

    if (updateScope == 'rewriteAll') {
      await _rewriteEntirePendingSeries(
        templateId: templateId,
        recurrenceId: recurrenceId,
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: resource,
        resourceAmount: resourceAmount,
        categoryId: categoryId,
        childId: childId,
        startDate: startDate,
        endDate: normalizedEndDate,
        targetTime: targetTime,
        pattern: normalizedPattern,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
      return;
    }

    final newRecurrenceId = await _insertTaskRecurrence(
      pattern: normalizedPattern,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
    );
    final newTemplateId = await _insertTaskTemplate(
      title: title,
      description: description,
      proofRequired: proofRequired,
      resource: resource,
      resourceAmount: resourceAmount,
      categoryId: categoryId,
      recurrenceId: newRecurrenceId,
      endDate: normalizedEndDate,
      targetTime: targetTime,
    );

    if (updateScope == 'modify') {
      await _movePendingFutureOccurrences(
        oldTemplateId: templateId,
        newTemplateId: newTemplateId,
        childId: childId,
        oldDueDate: oldDueDate,
        startDate: startDate,
        endDate: normalizedEndDate,
      );
      await _fillMissingGeneratedOccurrences(
        templateId: newTemplateId,
        childId: childId,
        anchorDate: startDate,
        endDate: normalizedEndDate,
        pattern: normalizedPattern,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
      await _capTemplateBefore(templateId, oldDueDate);
      await _deleteTemplateAndRecurrenceIfUnused(
        templateId: templateId,
        recurrenceId: recurrenceId,
      );
      return;
    }

    if (updateScope == 'rewrite') {
      await _insertGeneratedOccurrences(
        templateId: newTemplateId,
        childId: childId,
        startDate: startDate,
        endDate: normalizedEndDate,
        pattern: normalizedPattern,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
      await _deletePendingFutureOccurrences(templateId, oldDueDate);
      await _capTemplateBefore(templateId, oldDueDate);
      await _deleteTemplateAndRecurrenceIfUnused(
        templateId: templateId,
        recurrenceId: recurrenceId,
      );
      return;
    }

    throw ArgumentError('Unknown recurring update scope: $updateScope');
  }

  Future<void> _updateSeriesMetadataAndBounds({
    required int templateId,
    required String title,
    required String description,
    required bool proofRequired,
    required String resource,
    required int resourceAmount,
    int? categoryId,
    required String childId,
    required bool updateChildAssignments,
    required DateTime? endDate,
    required DateTime startDate,
    required String pattern,
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
    required bool syncGeneratedOccurrences,
  }) async {
    await _supabase
        .from('task_template')
        .update({
          'parent_id': _supabase.auth.currentUser!.id,
          'title': title,
          'description': description,
          'proof_required': proofRequired,
          'resource': resource.toLowerCase(),
          'resource_amount': resourceAmount,
          'category_id': categoryId,
          'end_date': endDate?.toIso8601String(),
          'target_time': _formatTimeForDate(startDate),
        })
        .eq('id', templateId)
        .select('id')
        .single();

    if (updateChildAssignments) {
      await _supabase
          .from('task_occurrence')
          .update({'child_id': childId})
          .eq('task_template_id', templateId)
          .eq('status', 'NOTD');
    }

    await _updatePendingOccurrenceTimes(
      templateId: templateId,
      timeSource: startDate,
      endDate: endDate,
    );

    if (!syncGeneratedOccurrences) {
      return;
    }

    if (endDate != null) {
      await _supabase
          .from('task_occurrence')
          .delete()
          .eq('task_template_id', templateId)
          .eq('status', 'NOTD')
          .gt('due_date', endDate.toIso8601String());
    }

    await _fillMissingGeneratedOccurrences(
      templateId: templateId,
      childId: childId,
      anchorDate: startDate,
      endDate: endDate,
      pattern: pattern,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
    );
  }

  Future<void> _updateTemplateMetadata({
    required int templateId,
    required String title,
    required String description,
    required bool proofRequired,
    required String resource,
    required int resourceAmount,
    int? categoryId,
    required String childId,
    required bool updateChildAssignments,
  }) async {
    await _supabase
        .from('task_template')
        .update({
          'parent_id': _supabase.auth.currentUser!.id,
          'title': title,
          'description': description,
          'proof_required': proofRequired,
          'resource': resource.toLowerCase(),
          'resource_amount': resourceAmount,
          'category_id': categoryId,
        })
        .eq('id', templateId)
        .select('id')
        .single();

    if (updateChildAssignments) {
      await _supabase
          .from('task_occurrence')
          .update({'child_id': childId})
          .eq('task_template_id', templateId)
          .eq('status', 'NOTD');
    }
  }

  Future<void> _rewriteEntirePendingSeries({
    required int templateId,
    required int? recurrenceId,
    required String title,
    required String description,
    required bool proofRequired,
    required String resource,
    required int resourceAmount,
    int? categoryId,
    required String childId,
    required DateTime startDate,
    required DateTime? endDate,
    required String targetTime,
    required String pattern,
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
  }) async {
    int currentRecurrenceId;
    if (recurrenceId == null) {
      currentRecurrenceId = await _insertTaskRecurrence(
        pattern: pattern,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
    } 
    else {
      currentRecurrenceId = recurrenceId;
      // await _supabase
      //     .from('task_recurrence')
      //     .update({
      //       'pattern': pattern,
      //       'interval': interval,
      //       'day_of_week': dayOfWeek,
      //       'day_of_month': dayOfMonth,
      //     })
      //     .eq('id', recurrenceId);
    }

    await _supabase
        .from('task_template')
        .update({
          'parent_id': _supabase.auth.currentUser!.id,
          'title': title,
          'description': description,
          'proof_required': proofRequired,
          'resource': resource.toLowerCase(),
          'resource_amount': resourceAmount,
          'category_id': categoryId,
          'task_recurrence_id': currentRecurrenceId,
          'target_time': targetTime,
          'end_date': endDate?.toIso8601String(),
          'last_generated_until': null,
        })
        .eq('id', templateId)
        .select('id')
        .single();

    await _supabase
        .from('task_occurrence')
        .delete()
        .eq('task_template_id', templateId)
        .eq('status', 'NOTD');

    await _insertGeneratedOccurrences(
      templateId: templateId,
      childId: childId,
      startDate: startDate,
      endDate: endDate,
      pattern: pattern,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
    );
  }

  String _formatTimeForDate(DateTime date) {
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes:00';
  }

  String _normalizePattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'never':
        return 'Never';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return pattern;
    }
  }


  // TODO: embed
  bool _isRecurringPattern(String pattern) {
    return pattern == 'Daily' || pattern == 'Weekly' || pattern == 'Monthly';
  }

  DateTime? _endOfDay(DateTime? date) {
    return date?.copyWith(
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
      microsecond: 999,
    );
  }

  DateTime _before(DateTime date) {
    return date.subtract(const Duration(microseconds: 1));
  }

  DateTime _withTime(DateTime date, DateTime timeSource) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeSource.hour,
      timeSource.minute,
    );
  }

  Future<void> _capTemplateBefore(int templateId, DateTime boundary) async {
    final capDate = await _lastOccurrenceBefore(templateId, boundary);
    final endDate = capDate == null ? _before(boundary) : _endOfDay(capDate)!;
    final lastGeneratedUntil = capDate ?? _before(boundary);

    await _supabase
        .from('task_template')
        .update({
          'end_date': endDate.toIso8601String(),
          'last_generated_until': lastGeneratedUntil.toIso8601String(),
        })
        .eq('id', templateId)
        .select('id')
        .single();
  }

  Future<DateTime?> _lastOccurrenceBefore(
    int templateId,
    DateTime boundary,
  ) async {
    final response = await _supabase
        .from('task_occurrence')
        .select('due_date')
        .eq('task_template_id', templateId)
        .lt('due_date', boundary.toIso8601String())
        .order('due_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return DateTime.parse(response['due_date']);
  }

  Future<void> _deleteTemplateAndRecurrenceIfUnused({
    required int templateId,
    required int? recurrenceId,
  }) async {
    final remainingOccurrences = await _supabase
        .from('task_occurrence')
        .select('id')
        .eq('task_template_id', templateId)
        .limit(1);

    if ((remainingOccurrences as List).isNotEmpty) {
      return;
    }

    await _supabase
        .from('task_template')
        .delete()
        .eq('id', templateId);

    if (recurrenceId == null) {
      return;
    }

    final remainingTemplates = await _supabase
        .from('task_template')
        .select('id')
        .eq('task_recurrence_id', recurrenceId)
        .limit(1);

    if ((remainingTemplates as List).isNotEmpty) {
      return;
    }

    await _supabase
        .from('task_recurrence')
        .delete()
        .eq('id', recurrenceId);
  }

  Future<int> _insertTaskRecurrence({
    required String pattern,
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
  }) async {
    if (!_isRecurringPattern(pattern)) {
      throw ArgumentError('Invalid recurring pattern: $pattern');
    }

    final response = await _supabase
        .from('task_recurrence')
        .insert({
          'pattern': pattern,
          'interval': interval,
          'day_of_week': dayOfWeek,
          'day_of_month': dayOfMonth,
        })
        .select('id')
        .single();

    return response['id'];
  }

  Future<int> _insertTaskTemplate({
    required String title,
    required String description,
    required bool proofRequired,
    required String resource,
    required int resourceAmount,
    int? categoryId,
    int? recurrenceId,
    DateTime? endDate,
    String? targetTime,
  }) async {
    final response = await _supabase
        .from('task_template')
        .insert({
          'parent_id': _supabase.auth.currentUser!.id,
          'title': title,
          'description': description,
          'proof_required': proofRequired,
          'task_recurrence_id': recurrenceId,
          'end_date': endDate?.toIso8601String(),
          'target_time': targetTime,
          'resource': resource.toLowerCase(),
          'resource_amount': resourceAmount,
          'category_id': categoryId,
        })
        .select('id')
        .single();

    return response['id'];
  }

  Future<void> _deletePendingFutureOccurrences(
    int templateId,
    DateTime oldDueDate,
  ) async {
    await _supabase
        .from('task_occurrence')
        .delete()
        .eq('task_template_id', templateId)
        .eq('status', 'NOTD')
        .gte('due_date', oldDueDate.toIso8601String());
  }

  Future<void> _movePendingFutureOccurrences({
    required int oldTemplateId,
    required int newTemplateId,
    required String childId,
    required DateTime oldDueDate,
    required DateTime startDate,
    required DateTime? endDate,
  }) async {
    final futureTasks = await _supabase
        .from('task_occurrence')
        .select('id, due_date')
        .eq('task_template_id', oldTemplateId)
        .eq('status', 'NOTD')
        .gte('due_date', oldDueDate.toIso8601String());

    DateTime? lastMovedDate;

    for (final task in futureTasks) {
      final occurrenceDate = DateTime.parse(task['due_date']);
      final movedDate = DateTime(
        occurrenceDate.year,
        occurrenceDate.month,
        occurrenceDate.day,
        startDate.hour,
        startDate.minute,
      );

      if (endDate != null && movedDate.isAfter(endDate)) {
        await _supabase
            .from('task_occurrence')
            .delete()
            .eq('id', task['id']);
        continue;
      }

      await _supabase
          .from('task_occurrence')
          .update({
            'task_template_id': newTemplateId,
            'child_id': childId,
            'due_date': movedDate.toIso8601String(),
          })
          .eq('id', task['id']);

      if (lastMovedDate == null || movedDate.isAfter(lastMovedDate)) {
        lastMovedDate = movedDate;
      }
    }

    if (lastMovedDate != null) {
      await _supabase
          .from('task_template')
          .update({'last_generated_until': lastMovedDate.toIso8601String()})
          .eq('id', newTemplateId);
    }
  }

  Future<void> _updatePendingOccurrenceTimes({
    required int templateId,
    required DateTime timeSource,
    required DateTime? endDate,
  }) async {
    final pendingTasks = await _supabase
        .from('task_occurrence')
        .select('id, due_date')
        .eq('task_template_id', templateId)
        .eq('status', 'NOTD');

    for (final task in pendingTasks) {
      final occurrenceDate = DateTime.parse(task['due_date']);
      if (endDate != null && occurrenceDate.isAfter(endDate)) {
        continue;
      }

      final movedDate = DateTime(
        occurrenceDate.year,
        occurrenceDate.month,
        occurrenceDate.day,
        timeSource.hour,
        timeSource.minute,
      );

      await _supabase
          .from('task_occurrence')
          .update({'due_date': movedDate.toIso8601String()})
          .eq('id', task['id']);
    }
  }

  Future<void> _fillMissingGeneratedOccurrences({
    required int templateId,
    required String childId,
    required DateTime anchorDate,
    required DateTime? endDate,
    required String pattern,
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
  }) async {
    final existingRows = await _supabase
        .from('task_occurrence')
        .select('due_date')
        .eq('task_template_id', templateId)
        .order('due_date', ascending: true);

    final existingDates = (existingRows as List)
        .map((row) => DateTime.parse(row['due_date']))
        .where((date) => endDate == null || !date.isAfter(endDate))
        .toList();
    final existingKeys = existingDates.map(_occurrenceKey).toSet();
    final latestExisting = existingDates.isEmpty ? null : existingDates.last;

    final generatedDates = TaskScheduler.generateDates(
      startDate: anchorDate,
      endDate: endDate,
      pattern: pattern,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      daysToPrepopulate: 365,
    );

    final datesToInsert = generatedDates.where((date) {
      if (latestExisting != null && !date.isAfter(latestExisting)) {
        return false;
      }

      return !existingKeys.contains(_occurrenceKey(date));
    }).toList();

    if (datesToInsert.isNotEmpty) {
      await _supabase.from('task_occurrence').insert(
            datesToInsert
                .map(
                  (date) => {
                    'child_id': childId,
                    'task_template_id': templateId,
                    'due_date': date.toIso8601String(),
                    'status': 'NOTD',
                  },
                )
                .toList(),
          );
    }

    final lastGeneratedUntil = datesToInsert.isNotEmpty
        ? datesToInsert.last
        : latestExisting;

    await _supabase
        .from('task_template')
        .update({
          'last_generated_until': lastGeneratedUntil?.toIso8601String(),
        })
        .eq('id', templateId)
        .select('id')
        .single();
  }

  String _occurrenceKey(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
      date.hour.toString().padLeft(2, '0'),
      date.minute.toString().padLeft(2, '0'),
    ].join('-');
  }

  Future<void> _insertGeneratedOccurrences({
    required int templateId,
    required String childId,
    required DateTime startDate,
    required DateTime? endDate,
    required String pattern,
    required int interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
  }) async {
    final dates = TaskScheduler.generateDates(
      startDate: startDate,
      endDate: endDate,
      pattern: pattern,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      daysToPrepopulate: 14,
    );

    if (dates.isEmpty) {
      return;
    }

    await _supabase.from('task_occurrence').insert(
          dates
              .map(
                (date) => {
                  'child_id': childId,
                  'task_template_id': templateId,
                  'due_date': date.toIso8601String(),
                  'status': 'NOTD',
                },
              )
              .toList(),
        );

    await _supabase
        .from('task_template')
        .update({'last_generated_until': dates.last.toIso8601String()})
        .eq('id', templateId);
  }
}
