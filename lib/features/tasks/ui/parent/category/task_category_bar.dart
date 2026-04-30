import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_family_sim/features/tasks/model/task_category.dart';

// Horizontal category selector used by the parent task screen.
class TaskCategoryBar extends StatelessWidget {
  const TaskCategoryBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.onAdd,
    required this.onCategoryLongPress,
  });

  final List<TaskCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<TaskCategory> onCategoryLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryChip(
                label: 'All',
                color: Theme.of(context).colorScheme.primary,
                isSelected: selectedCategoryId == null,
                onTap: () => onSelected(null),
              ),
              ...categories.map(
                (category) => _CategoryChip(
                  label: category.name,
                  color: category.color,
                  isSelected: selectedCategoryId == category.id,
                  onTap: () => onSelected(
                    selectedCategoryId == category.id ? null : category.id,
                  ),
                  onLongPress: () => onCategoryLongPress(category),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Add category',
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(42) : colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? color : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
