part of '../ui/parent/tasks_view.dart';

// Small private value objects used by the edit flow. They live in a part file
// so the main screen can focus on behavior instead of helper shapes.
class _RecurrenceFields {
  const _RecurrenceFields({
    required this.pattern,
    required this.interval,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  final String pattern;
  final int interval;
  final List<int>? dayOfWeek;
  final List<int>? dayOfMonth;
}

class _SeriesUpdatePlan {
  const _SeriesUpdatePlan({required this.scope, this.updateScope});

  factory _SeriesUpdatePlan.single() {
    return const _SeriesUpdatePlan(scope: 'single');
  }

  factory _SeriesUpdatePlan.future(String updateScope) {
    return _SeriesUpdatePlan(scope: 'future', updateScope: updateScope);
  }

  final String scope;
  final String? updateScope;
}
