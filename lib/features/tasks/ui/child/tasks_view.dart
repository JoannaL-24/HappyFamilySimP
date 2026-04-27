import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/tasks/data/child/tasks_repository.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

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

  final ImagePicker _picker = ImagePicker();

  Future<void> _handleProofSubmission(TaskOccurrence task) async {
    File? selectedImage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              selectedImage == null ? 'Take a Photo' : 'Look Good?',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedImage == null) ...[
                  const Icon(
                    Icons.camera_enhance,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Take a photo of your hard work!',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(selectedImage!.path),
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (selectedImage == null) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 50,
                    );
                    if (photo != null) {
                      final File file = File(photo.path);
                      final int size = await file.length();
                      logger.i(
                        'Path: ${photo.path} | Size: ${(size / 1024).toStringAsFixed(2)} KB',
                      );

                      setDialogState(() => selectedImage = file);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {
                    setDialogState(() => selectedImage = null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _markTaskAsDone(task.id, selectedImage);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check),
                  label: const Text('Submit'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

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

  Future<void> _markTaskAsDone(int taskId, File? selectedImage) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    try {
      await _taskRepository.markTaskAsDone(taskId, 'PEND', selectedImage);
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
    if (task.template?.proofRequired == false) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
        await _markTaskAsDone(task.id, null);
      }
    } else {
      await _handleProofSubmission(task);
    }
  }

  void _showZoomableImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.7,
              child: InteractiveViewer(
                clipBehavior: Clip.none,
                minScale: 1.0,
                maxScale: 5.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF5A3E36)),
            onPressed: () => context.go('/child/tasks/history'),
          ),
        ],
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
    final isPending = task.status == 'PEND';
    final template = task.template!;
    final proofRequired = template.proofRequired;
    final colorscheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isPending ? 1 : 2,
      color: isPending ? colorscheme.surfaceContainerLow.withAlpha(200) : colorscheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: isPending,
            onChanged: isPending ? null : (value) => _confirmMarkAsDone(task),
            activeColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        title: Text(
          template.title,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            decoration: isPending ? TextDecoration.lineThrough : null,
            color: isPending ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDueDate(task.dueDate),
                  style: GoogleFonts.quicksand(fontSize: 12),
                ),
                if (!isPending) ...[
                  Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                  TimeRemainingWidget(
                    dueDate: task.dueDate,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isPending)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pending Approval',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                if (proofRequired && !isPending) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt,
                            size: 10, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Photo Proof Needed',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => _onTaskTap(task),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildTaskDetailSheet(task),
    );
  }

  Widget _buildTaskDetailSheet(TaskOccurrence task) {
    final template = task.template!;
    final isPending = task.status == 'PEND';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              template.title,
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 8),
            // Due Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${_formatDueDate(task.dueDate)}',
                  style: GoogleFonts.quicksand(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Description Box
            Text(
              'What to do:',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: GoogleFonts.quicksand(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // photo Proof
            if (isPending && task.proofUrl != null && task.proofUrl!.isNotEmpty) ...[
              Text(
                'Your Photo Proof:',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showZoomableImage(context, task.proofUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    task.proofUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap photo to zoom',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // a badge to show if proof is needed
            if (template.proofRequired && !isPending)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt, size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This task needs a photo proof!',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Rewards Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Reward:',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        Text(
                          '${template.resourceAmount} ${template.resource} points!',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Action Button
            if (!isPending)
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
                  elevation: 2,
                ),
                child: Text(
                  template.proofRequired
                      ? 'Finish & Take Photo'
                      : 'I Finished It!',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Task already finished! Waiting for approval.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
