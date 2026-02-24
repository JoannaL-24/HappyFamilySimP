import 'package:flutter/material.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';

class ParentTasksScreen extends StatefulWidget {
  const ParentTasksScreen({super.key});

  @override
  State<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends State<ParentTasksScreen> {
  // --- Logistics: Hardcoded Data using your Real Models ---
  late List<TaskOccurrence> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = [
      TaskOccurrence(
        id: 1,
        templateId: 101,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: 'NOTD',
        template: TaskTemplate(
          id: 101,
          title: "Clean Bedroom",
          description: "Pick up toys, vacuum the rug, and make the bed.",
          proofRequired: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      ),
      TaskOccurrence(
        id: 2,
        templateId: 102,
        dueDate: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'DONE',
        template: TaskTemplate(
          id: 102,
          title: "Brush Teeth",
          description: "Brush for 2 minutes and use mouthwash.",
          proofRequired: false,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final occurrence = _tasks[index];
          // Accessing the join template connected to occurrence
          // TODO: Handle null template case
          final template = occurrence.template!;
          final isDone = occurrence.status == 'DONE';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showEditSheet(occurrence),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 1. Left aligned: indicator
                    _buildStatusIndicator(occurrence.status, colorScheme),
                    const SizedBox(width: 16),
                    // 2. Left aligned: Task Details
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? colorScheme.outline
                            : colorScheme.onSurface,
                      ),
                    ),
                    // 3. Right aligned: Due Date + Chevron
                    const Spacer(),
                    _buildDueChip(occurrence.dueDate, colorScheme),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: colorScheme.outline),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper UI Components ---
  // TODO: to adjust
  Widget _buildStatusIndicator(String status, ColorScheme colorScheme) {
    final bool isDone = status == 'DONE';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDone ? colorScheme.primary : colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isDone ? Icons.check : Icons.timer_outlined,
        color: isDone ? colorScheme.onPrimary : colorScheme.primary,
      ),
    );
  }

  Widget _buildDueChip(DateTime date, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "Due: ${date.month}/${date.day}",
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Edit Logistics: Bottom Sheet ---
  // TODO: to adjust
  void _showEditSheet(TaskOccurrence occurrence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Edit Task Logistics",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Template Edit (The "What")
            TextField(
              decoration: const InputDecoration(
                labelText: "Task Title",
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: occurrence.template?.title,
              ),
            ),
            const SizedBox(height: 16),
            // Occurrence Edit (The "Status")
            Text("Task Status", style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'NOTD', label: Text('Pending')),
                ButtonSegment(value: 'DONE', label: Text('Completed')),
              ],
              selected: {occurrence.status},
              onSelectionChanged: (newVal) {
                // Update logic would go here
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
