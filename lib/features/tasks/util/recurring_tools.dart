import 'package:flutter/material.dart';

class TaskUtils {
  static String getCustomSummary(Map<String, dynamic>? customRecurrence) {
    if (customRecurrence == null) return "Custom";

    final String pattern = customRecurrence['pattern'] ?? 'daily';
    final int interval = customRecurrence['interval'] ?? 1;
    final List<int> selectedDays = List<int>.from(
      customRecurrence['selectedDays'] ?? [],
    );

    // Helper for pluralization
    String plural(int val, String unit) => val > 1 ? '${unit}s' : unit;

    if (pattern == 'daily') {
      return "Custom: Every $interval ${plural(interval, 'day')}";
    }

    if (pattern == 'weekly') {
      final weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      selectedDays.sort();

      final dayNames = selectedDays.isEmpty
          ? "days"
          : selectedDays.map((d) => weekdayLabels[d - 1]).join(', ');

      return "Custom: $dayNames for every $interval ${plural(interval, 'week')}";
    }

    if (pattern == 'monthly') {
      selectedDays.sort();

      String datesPart;
      if (selectedDays.isEmpty) {
        datesPart = "dates";
      } else {
        // Take only the first 5 dates
        final firstFive = selectedDays.take(5).join(', ');

        // If there are more than 5, append the ellipsis
        datesPart = selectedDays.length > 5 ? '$firstFive...' : firstFive;
      }

      return "Custom: Every date $datesPart every $interval ${plural(interval, 'month')}";
    }

    return "Custom";
  }
}
