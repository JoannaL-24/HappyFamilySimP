part of 'tasks_view.dart';

// Private presentational widgets for the daily task list. They intentionally do
// not contain repository calls or recurrence rules.
class _EmptyWeekMessage extends StatelessWidget {
  const _EmptyWeekMessage({
    required this.hasTasks,
    required this.hasCategoryFilter,
    required this.selectedDate,
  });

  final bool hasTasks;
  final bool hasCategoryFilter;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final message = !hasTasks
        ? 'No tasks found.'
        : hasCategoryFilter
            ? 'No tasks in this category on ${DateFormat('MMM d').format(selectedDate)}.'
            : 'No tasks on ${DateFormat('MMM d').format(selectedDate)}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.occurrence,
    required this.categoryColor,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  final TaskOccurrence occurrence;
  final Color categoryColor;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final template = occurrence.template;
    final isDone = occurrence.status == 'COMP';

    if (template == null) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: _cardColor(colorScheme, isDone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _borderColor(colorScheme, isDone)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 7,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (isSelectionMode)
                          _SelectionIcon(isSelected: isSelected),
                        _ChildAvatarWithStatus(
                          avatarUrl: occurrence.childAvatar,
                          isDone: isDone,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TaskCardDetails(
                            occurrence: occurrence,
                            isDone: isDone,
                          ),
                        ),
                        _TaskCardTrailing(
                          dueDate: occurrence.dueDate,
                          isDone: isDone,
                          showChevron: !isSelectionMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _cardColor(ColorScheme colorScheme, bool isDone) {
    if (isSelected) {
      return colorScheme.primaryContainer;
    }

    return isDone ? colorScheme.surfaceContainerHigh : colorScheme.surface;
  }

  Color _borderColor(ColorScheme colorScheme, bool isDone) {
    if (isSelected) {
      return colorScheme.primary.withAlpha(100);
    }

    return isDone ? Colors.transparent : colorScheme.primary.withAlpha(50);
  }
}

class _SelectionIcon extends StatelessWidget {
  const _SelectionIcon({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.outline,
        size: 20,
      ),
    );
  }
}

class _ChildAvatarWithStatus extends StatelessWidget {
  const _ChildAvatarWithStatus({required this.avatarUrl, required this.isDone});

  final String avatarUrl;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.surfaceDim,
          backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
          child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        if (isDone)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 10, color: colorScheme.onPrimary),
            ),
          ),
      ],
    );
  }
}

class _TaskCardDetails extends StatelessWidget {
  const _TaskCardDetails({required this.occurrence, required this.isDone});

  final TaskOccurrence occurrence;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final template = occurrence.template!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          template.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? colorScheme.outline : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              occurrence.childName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // TODO: choose this icon from the task resource type.
                  const Icon(
                    Icons.stars_rounded,
                    size: 12,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${template.resourceAmount}",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaskCardTrailing extends StatelessWidget {
  const _TaskCardTrailing({
    required this.dueDate,
    required this.isDone,
    required this.showChevron,
  });

  final DateTime dueDate;
  final bool isDone;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _DueChip(date: dueDate, isDone: isDone),
        if (showChevron) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 20, color: colorScheme.outline),
        ],
      ],
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.date, required this.isDone});

  final DateTime date;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isOverdue =
        date.isBefore(DateTime(now.year, now.month, now.day)) && !isDone;

    final Color color = isDone
        ? colorScheme.outline
        : (isOverdue ? colorScheme.error : colorScheme.primary);

    final label = DateFormat('h:mm a').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: isOverdue ? Border.all(color: color.withAlpha(50)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
