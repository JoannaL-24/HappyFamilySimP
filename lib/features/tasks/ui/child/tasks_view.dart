import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/tasks/data/child/tasks_repository.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';

var logger = Logger();

class ChildTasksScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const ChildTasksScreen({super.key, required this.authRepository});

  @override
  State<ChildTasksScreen> createState() => _ChildTasksScreenState();
}

class _ChildTasksScreenState extends State<ChildTasksScreen> {
  final ChildTaskRepository _taskRepository = ChildTaskRepository();
  bool _isLoading = true;
  List<TaskOccurrence> _tasks = [];

  // TODO: fake rewards data
  final Map<int, int> _taskRewards = {1: 50, 2: 150, 3: 30};

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _tasks = [];
    });
    await _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.authRepository.currentUser?.id;
      if (userId == null) return;

      final result = await _taskRepository.fetchTasksByChildId(userId);

      await _handleMissedTasks(result);

      final updatedResult = await _taskRepository.fetchTasksByChildId(userId);

      if (mounted) {
        setState(() {
          _tasks = updatedResult;
        });
      }
    } catch (e) {
      Utils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMissedTasks(List<TaskOccurrence> fetchedTasks) async {
    final now = DateTime.now();

    for (var task in fetchedTasks) {
      if (task.status == 'NOTD' && task.dueDate.isBefore(now)) {
        try {
          await _taskRepository.markTaskAsMissed(task.id);
        } catch (e) {
          logger.e('Error updating task ${task.id}: $e');
        }
      }
    }
  }

  Future<void> _markTaskAsDone(int taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    try {
      await _taskRepository.updateTaskStatus(taskId, 'PEND');
      await _fetchTasks();
    } catch (e) {
      if (mounted) {
        Utils.showError('Could not update task. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmMarkAsDone(TaskOccurrence task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Finish Task?'),
        content: Text('Are you sure you finished "${task.template?.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes!'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _markTaskAsDone(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E8),
      appBar: AppBar(
        backgroundColor: const Color(0xffebdfcc),
        title: Text(
          'My Tasks',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36), //soft dark brown
          ),
        ),
        centerTitle: true,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) =>
                    _buildTaskCard(context, _tasks[index]),
              ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskOccurrence task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPending = task.status == 'PEND';
    final template = task.template!;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isPending
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isPending
              ? Colors.transparent
              : colorScheme.primary.withAlpha(50),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: isPending ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            // Checkbox for marking as done
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: isPending,
                onChanged: isPending
                    ? null
                    : (value) => _confirmMarkAsDone(task),
                activeColor: Colors.green,
              ),
            ),
            // The rest of the card is clickable for details
            Expanded(
              child: InkWell(
                onTap: () => _onTaskTap(task),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        template.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isPending
                              ? TextDecoration.lineThrough
                              : null,
                          color: isPending
                              ? colorScheme.outline
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // The Date
                          Flexible(
                            child: Text(
                              _formatDueDate(task.dueDate),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          if (!isPending) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            // The Timer
                            Flexible(
                              child: TimeRemainingWidget(
                                dueDate: task.dueDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else ...[
                            // pending label
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            Text(
                              'Pending Approval',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: colorScheme.outline),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    if (taskDate == today) return 'Today at ${DateFormat.jm().format(date)}';
    if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${DateFormat.jm().format(date)}';
    }
    return DateFormat('MMM d, h:mm a').format(date);
  }

  void _onTaskTap(TaskOccurrence task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildTaskDetailSheet(task),
    );
  }

  Widget _buildTaskDetailSheet(TaskOccurrence task) {
    final theme = Theme.of(context);
    final template = task.template!;
    final reward = _taskRewards[task.id] ?? 0;
    final isDone = task.status == 'PEND';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              template.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Due Date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${_formatDueDate(task.dueDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What to do:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(template.description, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rewards Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Reward:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$reward Stars to grow your pet!',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            if (!isDone)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmMarkAsDone(task);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Finished It!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Center(
                child: Text(
                  'Task already finished! Waiting for approval.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.task_alt, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No tasks for you now.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TimeRemainingWidget extends StatefulWidget {
  final DateTime dueDate;
  final TextStyle? style;
  final Color urgentColor;

  const TimeRemainingWidget({
    super.key,
    required this.dueDate,
    this.style,
    this.urgentColor = Colors.red,
  });

  @override
  State<TimeRemainingWidget> createState() => _TimeRemainingWidgetState();
}

class _TimeRemainingWidgetState extends State<TimeRemainingWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute to keep the countdown accurate
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = widget.dueDate.difference(now);

    if (diff.isNegative) {
      return const SizedBox.shrink();
    }

    String text;
    bool isUrgent = diff.inHours < 24;

    if (diff.inDays > 0) {
      text = '${diff.inDays}d ${diff.inHours % 24}h left';
    } else if (diff.inHours > 0) {
      text = '${diff.inHours}h ${diff.inMinutes % 60}m left';
    } else {
      text = '${diff.inMinutes}m left';
    }

    return Text(
      text,
      style: widget.style?.copyWith(
        color: isUrgent ? widget.urgentColor : null,
      ),
    );
  }
}
