import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';

class ExpirationReminder {
  static const Duration reminderLeadTime = Duration(hours: 1);
  static const Duration reminderWindow = Duration(minutes: 1);

  static bool shouldNotify(TaskOccurrence task, DateTime now) {
    if (task.status != 'NOTD') {
      return false;
    }

    final timeUntilDue = task.dueDate.difference(now);
    return !timeUntilDue.isNegative &&
        timeUntilDue <= reminderLeadTime &&
        timeUntilDue > reminderLeadTime - reminderWindow;
  }

  static TaskOccurrence? firstExpiringTask(
    List<TaskOccurrence> tasks,
    DateTime now,
    Set<int> alreadyNotifiedIds,
  ) {
    final eligibleTasks = tasks.where(
      (task) =>
          !alreadyNotifiedIds.contains(task.id) && shouldNotify(task, now),
    );

    if (eligibleTasks.isEmpty) {
      return null;
    }

    return eligibleTasks.reduce(
      (earliest, task) =>
          task.dueDate.isBefore(earliest.dueDate) ? task : earliest,
    );
  }
}
