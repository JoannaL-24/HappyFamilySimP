class TaskScheduler {
  static List<DateTime> generateDates({
    required DateTime startDate,
    DateTime? endDate,
    required String pattern,
    required int interval,
    List<int>? dayOfWeek, 
    List<int>? dayOfMonth,
    int daysToPrepopulate = 14,
  }) {
    List<DateTime> dates = [];
    DateTime current = startDate;

    DateTime horizon = DateTime.now().add(Duration(days: daysToPrepopulate));
    DateTime finalLimit = (endDate != null && endDate.isBefore(horizon)) ? endDate : horizon;

    // Safety check for interval
    if (interval <= 0) return dates;

    while (current.isBefore(finalLimit) || current.isAtSameMomentAs(finalLimit)) {
      
      if (pattern == 'Daily') {
        dates.add(current);
        current = current.add(Duration(days: interval));
      } 
      
      else if (pattern == 'Weekly') {
        if (dayOfWeek != null && dayOfWeek.contains(current.weekday)) {
          dates.add(current);
        }
        
        if (current.weekday == 7) {
          current = current.add(Duration(days: (7 * (interval - 1)) + 1));
        } else {
          current = current.add(const Duration(days: 1));
        }
      } 
      
      else if (pattern == 'Monthly') {
        // 1. Determine which days we are looking for this month
        // If the list is null/empty, we default to the day of the startDate
        final targetDays = (dayOfMonth != null && dayOfMonth.isNotEmpty) 
            ? dayOfMonth 
            : [startDate.day];

        // 2. Check each target day for the current month
        for (int day in targetDays) {
          DateTime candidate = _safeDateTime(current.year, current.month, day, startDate);
          
          // Only add if it's within our [startDate, finalLimit] window
          if ((candidate.isAtSameMomentAs(startDate) || candidate.isAfter(startDate)) &&
              (candidate.isBefore(finalLimit) || candidate.isAtSameMomentAs(finalLimit))) {
            dates.add(candidate);
          }
        }
        
        // 3. Move to the 1st of the next month + interval to keep logic clean
        current = DateTime(current.year, current.month + interval, 1);
      }
    }
    
    // Monthly candidates might be added out of order if day list isn't sorted
    dates.sort();
    return dates;
  }

  /// Helper ensures time is preserved and handles shorter months (e.g. Feb 30 -> Feb 28)
  static DateTime _safeDateTime(int year, int month, int day, DateTime original) {
    int lastDay = DateTime(year, month + 1, 0).day;
    int actualDay = day > lastDay ? lastDay : day;
    return DateTime(
      year, 
      month, 
      actualDay, 
      original.hour, 
      original.minute, 
      original.second
    );
  }
}