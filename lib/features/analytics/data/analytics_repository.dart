import 'package:flutter/material.dart';
import 'package:happy_family_sim/features/tasks/data/task_repository.dart';


class TaskReportData {
  final int totalTasks;
  final int completed;
  final int rejected;
  final int missed;
  final int pending;
  final int notDoneYet;

  TaskReportData({
    required this.totalTasks,
    required this.completed,
    required this.rejected,
    required this.missed,
    required this.pending,
    required this.notDoneYet,
  });

  double get completionRate => totalTasks == 0 ? 0 : (completed / totalTasks) * 100;
  double get rejectionRate => totalTasks == 0 ? 0 : (rejected / totalTasks) * 100;
  double get missedRate => totalTasks == 0 ? 0 : (missed / totalTasks) * 100;
  double get pendingRate => totalTasks == 0 ? 0 : (pending / totalTasks) * 100;
  double get notDoneRate => totalTasks == 0 ? 0 : (notDoneYet / totalTasks) * 100;
}

class CategoryStatistic {
  final int? categoryId;
  final String categoryName;
  final Color color;
  final int completed;
  final int total;

  CategoryStatistic({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.completed,
    required this.total,
  });

  double get completionRate => total == 0 ? 0 : (completed / total) * 100;
}

class TemplateStatistic {
  final int templateId;
  final String title;
  final int completed;
  final int rejected;
  final int missed;
  final int total;

  TemplateStatistic({
    required this.templateId,
    required this.title,
    required this.completed,
    required this.rejected,
    required this.missed,
    required this.total,
  });

  double get completionRate => total == 0 ? 0 : (completed / total) * 100;
  double get rejectionRate => total == 0 ? 0 : (rejected / total) * 100;
  double get missedRate => total == 0 ? 0 : (missed / total) * 100;
}

class DetailedTaskReportData {
  final List<CategoryStatistic> categoryStats;
  final TemplateStatistic? mostCompleted;
  final TemplateStatistic? mostRejected;
  final TemplateStatistic? mostMissed;

  DetailedTaskReportData({
    required this.categoryStats,
    this.mostCompleted,
    this.mostRejected,
    this.mostMissed,
  });
}

class AnalyticsRepository {
  final TaskRepository _taskRepository;

  AnalyticsRepository(this._taskRepository);

  Future<TaskReportData> getTaskReport({
    required String parentId,
    String? childId,
    required DateTime start,
    required DateTime end,
  }) async {
    final occurrences = await _taskRepository.fetchAnalyticsData(
      parentId: parentId,
      childId: childId,
      start: start,
      end: end,
    );

    int completed = 0;
    int rejected = 0;
    int missed = 0;
    int pending = 0;
    int notDoneYet = 0;

    final now = DateTime.now();

    for (var occ in occurrences) {
      if (occ.status == 'COMP') {
        completed++;
      } else if (occ.status == 'REJC') {
        rejected++;
      } else if (occ.status == 'PEND') {
        pending++;
      } else if (occ.status == 'NOTD') {
        if (occ.dueDate.isBefore(now)) {
          missed++;
        } else {
          notDoneYet++;
        }
      } else if (occ.status == "MISS") {
        missed++;
      }
    }

    return TaskReportData(
      totalTasks: occurrences.length,
      completed: completed,
      rejected: rejected,
      missed: missed,
      pending: pending,
      notDoneYet: notDoneYet,
    );
  }

  Future<DetailedTaskReportData> getDetailedTaskReport({
    required String parentId,
    String? childId,
    required DateTime start,
    required DateTime end,
  }) async {
    final occurrences = await _taskRepository.fetchAnalyticsData(
      parentId: parentId,
      childId: childId,
      start: start,
      end: end,
    );

    final categories = await _taskRepository.fetchTaskCategories(parentId);
    final categoryMap = {for (var cat in categories) cat.id: cat};

    // Category Stats
    final Map<int?, Map<String, int>> categoryCounts = {}; // categoryId -> {completed, total}
    
    // Template Stats
    final Map<int, Map<String, dynamic>> templateCounts = {}; // templateId -> {title, completed, rejected, missed, total}

    final now = DateTime.now();

    for (var occ in occurrences) {
      final template = occ.template;
      if (template == null) continue;

      final categoryId = template.categoryId;
      
      // Update Category Stats
      categoryCounts.putIfAbsent(categoryId, () => {'completed': 0, 'total': 0});
      categoryCounts[categoryId]!['total'] = categoryCounts[categoryId]!['total']! + 1;
      if (occ.status == 'COMP') {
        categoryCounts[categoryId]!['completed'] = categoryCounts[categoryId]!['completed']! + 1;
      }

      // Update Template Stats
      templateCounts.putIfAbsent(template.id, () => {
        'title': template.title,
        'completed': 0,
        'rejected': 0,
        'missed': 0,
        'total': 0,
      });
      
      templateCounts[template.id]!['total'] = templateCounts[template.id]!['total'] + 1;
      if (occ.status == 'COMP') {
        templateCounts[template.id]!['completed'] = templateCounts[template.id]!['completed'] + 1;
      } else if (occ.status == 'REJC') {
        templateCounts[template.id]!['rejected'] = templateCounts[template.id]!['rejected'] + 1;
      } else if (occ.status == 'NOTD' && occ.dueDate.isBefore(now)) {
        templateCounts[template.id]!['missed'] = templateCounts[template.id]!['missed'] + 1;
      } else if (occ.status == 'MISS') {
        templateCounts[template.id]!['missed'] = templateCounts[template.id]!['missed'] + 1;
      }
    }

    final List<CategoryStatistic> categoryStats = [];
    categoryCounts.forEach((id, counts) {
      final category = categoryMap[id];
      categoryStats.add(CategoryStatistic(
        categoryId: id,
        categoryName: category?.name ?? 'Uncategorized',
        color: category?.color ?? Colors.grey,
        completed: counts['completed']!,
        total: counts['total']!,
      ));
    });

    final List<TemplateStatistic> templateStats = templateCounts.entries.map((e) {
      return TemplateStatistic(
        templateId: e.key,
        title: e.value['title'],
        completed: e.value['completed'],
        rejected: e.value['rejected'],
        missed: e.value['missed'],
        total: e.value['total'],
      );
    }).toList();

    TemplateStatistic? mostCompleted;
    TemplateStatistic? mostRejected;
    TemplateStatistic? mostMissed;

    if (templateStats.isNotEmpty) {
      mostCompleted = templateStats.reduce((a, b) => a.completionRate > b.completionRate ? a : b);
      mostRejected = templateStats.reduce((a, b) => a.rejectionRate > b.rejectionRate ? a : b);
      mostMissed = templateStats.reduce((a, b) => a.missedRate > b.missedRate ? a : b);
      
      // If all are 0, maybe set to null or keep as is. 
      // The requirement asks for "Most Completed", "Most Rejected", "Most Missed".
      if (mostCompleted.completionRate == 0) mostCompleted = null;
      if (mostRejected.rejectionRate == 0) mostRejected = null;
      if (mostMissed.missedRate == 0) mostMissed = null;
    }

    return DetailedTaskReportData(
      categoryStats: categoryStats,
      mostCompleted: mostCompleted,
      mostRejected: mostRejected,
      mostMissed: mostMissed,
    );
  }
}
