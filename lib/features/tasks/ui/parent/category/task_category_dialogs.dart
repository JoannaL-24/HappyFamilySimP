import 'package:flutter/material.dart';
import 'package:happy_family_sim/features/tasks/model/task_category.dart';

// Dialog helpers for creating, editing, and deleting task categories.
enum TaskCategoryAction {
  edit,
  delete,
}

Future<TaskCategory?> showTaskCategoryEditorDialog(
  BuildContext context, {
  TaskCategory? category,
}) {
  final nameController = TextEditingController(text: category?.name ?? '');
  final colors = [
    const Color(0xFFE98B50),
    const Color(0xFF4E9F78),
    const Color(0xFF5B8CCB),
    const Color(0xFFB66BCB),
    const Color(0xFFE0B84D),
  ];
  Color selectedColor = category?.color ?? colors.first;
  String? nameError;

  return showDialog<TaskCategory>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              onChanged: (_) {
                if (nameError != null) {
                  setDialogState(() => nameError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: nameError,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: colors
                  .map(
                    (color) => InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          setDialogState(() => selectedColor = color),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: color,
                        child: selectedColor == color
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                setDialogState(() {
                  nameError = 'Category name is required';
                });
                return;
              }

              Navigator.pop(
                context,
                TaskCategory(
                  id: category?.id ?? -1,
                  name: name,
                  color: selectedColor,
                ),
              );
            },
            child: Text(category == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    ),
  );
}

Future<TaskCategoryAction?> showTaskCategoryActions(
  BuildContext context,
  TaskCategory category,
) {
  return showModalBottomSheet<TaskCategoryAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit category'),
            onTap: () => Navigator.pop(context, TaskCategoryAction.edit),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Delete category'),
            onTap: () => Navigator.pop(context, TaskCategoryAction.delete),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmDeleteTaskCategory(
  BuildContext context,
  TaskCategory category,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete ${category.name}?'),
          content: const Text(
            'Tasks using this category will keep their task data, but the category will be cleared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
