import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:happy_family_sim/features/tasks/data/task_repository.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';

class ParentTasksScreen extends StatefulWidget {
  final AuthRepository authRepository;
  const ParentTasksScreen({super.key, required this.authRepository});

  @override
  State<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends State<ParentTasksScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  // future as state to enable
  late Future<List<TaskOccurrence>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      final userId = widget.authRepository.currentUser?.id;
      _tasksFuture = _taskRepository.fetchChildTasks(userId ?? '');
    });
  }
  // late List<TaskOccurrence> _tasks;
  // @override
  // void initState() {
  //   super.initState();
  //   _tasks = [
  //     TaskOccurrence(
  //       id: 1,
  //       templateId: 101,
  //       dueDate: DateTime.now().add(const Duration(days: 1)),
  //       status: 'NOTD',
  //       template: TaskTemplate(
  //         id: 101,
  //         title: "Clean Bedroom",
  //         description: "Pick up toys, vacuum the rug, and make the bed.",
  //         proofRequired: true,
  //         startDate: DateTime.now(),
  //         endDate: DateTime.now().add(const Duration(days: 7)),
  //       ),
  //     ),
  //     TaskOccurrence(
  //       id: 2,
  //       templateId: 102,
  //       dueDate: DateTime.now().subtract(const Duration(hours: 2)),
  //       status: 'DONE',
  //       template: TaskTemplate(
  //         id: 102,
  //         title: "Brush Teeth",
  //         description: "Brush for 2 minutes and use mouthwash.",
  //         proofRequired: false,
  //         startDate: DateTime.now(),
  //         endDate: DateTime.now().add(const Duration(days: 30)),
  //       ),
  //     ),
  //   ];
  // }

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
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 1,
      ),

      body: FutureBuilder<List<TaskOccurrence>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No tasks found."));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final occurrence = tasks[index];
              final template = occurrence.template!;
              final isDone = occurrence.status == 'DONE';

              return Opacity(
                opacity: isDone ? 0.6 : 1.0,
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 14),
                  color: isDone
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    // side: BorderSide(color: isDone ? colorScheme.outlineVariant.withAlpha(125): colorScheme.outlineVariant, width: 0.7),
                    side: BorderSide(
                      color: isDone
                          ? Colors.transparent
                          : colorScheme.primary.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showEditSheet(occurrence),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // 1. Left aligned: indicator
                          Stack(
                            children: [
                              _buildChildIndicator(
                                occurrence
                                    .childAvatar, // Using the URL we generated earlier
                                colorScheme,
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
                                    child: Icon(
                                      Icons.check,
                                      size: 10,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // 2. Left aligned: Task Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDone
                                        ? colorScheme.outline
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  occurrence.childName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 3. Right aligned: Due Date + Chevron
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildDueChip(
                                occurrence.dueDate,
                                colorScheme,
                                isDone,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: colorScheme.outline,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper UI Components ---
  // TODO: to adjust
  Widget _buildChildIndicator(String avatarUrl, ColorScheme colorScheme) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.surfaceDim,
      backgroundImage: NetworkImage(avatarUrl),
      // default icon
      // final bool isDone = status == 'DONE';
      // return Container(
      //   width: 48,
      //   height: 48,
      //   decoration: BoxDecoration(
      //     shape: BoxShape.circle,
      //     color: colorScheme.surfaceDim,
      //     // color: isDone ? colorScheme.surfaceDim : colorScheme.surfaceDim,
      //     // border: Border.all(
      //     //   color: isDone ? colorScheme.primary : colorScheme.outlineVariant,
      //     //   width: 2,
      //     // ),
      //   ),
      //   child: Icon(
      //     Icons.person,
      //     // isDone ? Icons.check : Icons.person,
      //     color: colorScheme.primary,
      //   ),
    );
  }

  Widget _buildDueChip(DateTime date, ColorScheme colors, bool isDone) {
    final color = isDone ? colors.outline : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(
          0x1A,
        ), // 0.1 opacity in alpha channel (0x1A = 26 out of 255)
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('MMM d').format(date), // Use intl package
        style: TextStyle(
          color: color,
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
