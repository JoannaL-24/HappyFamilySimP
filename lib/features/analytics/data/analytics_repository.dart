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
      // Statuses: 'COMP' (Completed), 'REJC' (Rejected), 'PEND' (Pending Approval), 'NOTD' (Not Done)
      // MISSED: 'NOTD' and due_date < now
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
}
