class TaskRecurrence {
  final int id;
  final String pattern;
  final int interval;
  final List<int>? dayOfWeek;
  final List<int>? dayOfMonth;

  TaskRecurrence({
    required this.id,
    required this.pattern,
    this.interval = 1,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  factory TaskRecurrence.fromJson(Map<String, dynamic> json) {
    return TaskRecurrence(
      id: json['id'],
      pattern: json['pattern'],
      interval: json['interval'] ?? 1,
      dayOfWeek: json['day_of_week'] != null
          ? List<int>.from(json['day_of_week'])
          : null,
      dayOfMonth: json['day_of_month'] != null
          ? List<int>.from(json['day_of_month'])
          : null, //
    );
  }

  TaskRecurrence copyWith({
    String? pattern,
    int? interval,
    List<int>? dayOfWeek,
    List<int>? dayOfMonth,
  }) {
    return TaskRecurrence(
      id: id,
      pattern: pattern ?? this.pattern,
      interval: interval ?? this.interval,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    );
  }
}
