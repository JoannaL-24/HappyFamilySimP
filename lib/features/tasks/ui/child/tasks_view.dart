import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/tasks/data/child/tasks_repository.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:happy_family_sim/features/tasks/util/expiration_reminder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Set<int> _expirationReminderIds = {};
  final Set<int> _reviewNotificationIds = {};
  Timer? _expirationReminderTimer;
  Timer? _reviewPollTimer;
  RealtimeChannel? _reviewChannel;
  bool _isCheckingReviewStatuses = false;
  int? _visibleExpirationReminderId;
  DateTime _selectedDate = DateTime.now();

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
    _expirationReminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _showExpirationReminderIfNeeded();
    });
  }

  @override
  void dispose() {
    _expirationReminderTimer?.cancel();
    _reviewPollTimer?.cancel();
    final channel = _reviewChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
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

      _startReviewNotificationSubscription(userId);
      _startReviewPolling(userId);

      final result = await _taskRepository.fetchTasksByChildId(userId);

      // NOTE: Supabase Cron job has implemented to mark missed tasks, but
      // keeping this here as a backup in case the cron job fails or the app
      // is open for a long time without refreshing
      await _handleMissedTasks(result);

      final previousPendingIds = _tasks
          .where((task) => task.status == 'PEND')
          .map((task) => task.id)
          .toSet();
      final updatedResult = await _taskRepository.fetchTasksByChildId(userId);
      await _notifyForReviewedTasksNoLongerActive(
        previousPendingIds: previousPendingIds,
        activeTasks: updatedResult,
        childId: userId,
      );

      if (mounted) {
        setState(() {
          _tasks = updatedResult;
        });
        _showExpirationReminderIfNeeded();
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

  void _showExpirationReminderIfNeeded() {
    if (!mounted) return;

    final expiringTask = ExpirationReminder.firstExpiringTask(
      _tasks,
      DateTime.now(),
      _expirationReminderIds,
    );

    if (expiringTask == null) {
      if (_visibleExpirationReminderId != null &&
          !_tasks.any(
            (task) =>
                task.id == _visibleExpirationReminderId &&
                ExpirationReminder.shouldNotify(task, DateTime.now()),
          )) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        _visibleExpirationReminderId = null;
      }
      return;
    }

    _expirationReminderIds.add(expiringTask.id);
    _visibleExpirationReminderId = expiringTask.id;

    final title = expiringTask.template?.title ?? 'Task';
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFFFF0CC),
          leading: const Icon(
            Icons.notifications_active,
            color: Color(0xFFB06000),
          ),
          content: InkWell(
            onTap: () => _openExpirationReminderTask(expiringTask),
            child: Text(
              '$title is due in 1 hour.',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5A3E36),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _visibleExpirationReminderId = null;
              },
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () => _openExpirationReminderTask(expiringTask),
              child: const Text('View'),
            ),
          ],
        ),
      );
  }

  void _startReviewNotificationSubscription(String childId) {
    if (_reviewChannel != null) {
      return;
    }

    _reviewChannel = Supabase.instance.client
        .channel('reviewed-tasks-$childId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'task_occurrence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'child_id',
            value: childId,
          ),
          callback: (payload) {
            unawaited(_handleReviewedTaskChange(payload, childId));
          },
        )
        .subscribe();
  }

  void _startReviewPolling(String childId) {
    if (_reviewPollTimer != null) {
      return;
    }

    _reviewPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_checkPendingReviewStatuses(childId));
    });
  }

  Future<void> _checkPendingReviewStatuses(String childId) async {
    if (_isCheckingReviewStatuses) {
      return;
    }

    final pendingTaskIds = _tasks
        .where((task) => task.status == 'PEND')
        .map((task) => task.id)
        .toList();

    if (pendingTaskIds.isEmpty) {
      return;
    }

    _isCheckingReviewStatuses = true;
    try {
      for (final taskId in pendingTaskIds) {
        await _notifyIfTaskWasReviewed(occurrenceId: taskId, childId: childId);
      }
    } finally {
      _isCheckingReviewStatuses = false;
    }
  }

  Future<void> _notifyForReviewedTasksNoLongerActive({
    required Set<int> previousPendingIds,
    required List<TaskOccurrence> activeTasks,
    required String childId,
  }) async {
    if (previousPendingIds.isEmpty) {
      return;
    }

    final activeTaskIds = activeTasks.map((task) => task.id).toSet();
    final removedPendingIds = previousPendingIds.difference(activeTaskIds);

    for (final taskId in removedPendingIds) {
      await _notifyIfTaskWasReviewed(occurrenceId: taskId, childId: childId);
    }
  }

  Future<void> _handleReviewedTaskChange(
    PostgresChangePayload payload,
    String childId,
  ) async {
    final record = payload.newRecord;
    final status = record['status'];
    if (status != 'COMP' && status != 'REJC') {
      return;
    }

    final occurrenceId = record['id'];
    if (occurrenceId is! int || _reviewNotificationIds.contains(occurrenceId)) {
      return;
    }

    await _notifyIfTaskWasReviewed(
      occurrenceId: occurrenceId,
      childId: childId,
    );
  }

  Future<void> _notifyIfTaskWasReviewed({
    required int occurrenceId,
    required String childId,
  }) async {
    if (_reviewNotificationIds.contains(occurrenceId)) {
      return;
    }

    try {
      final reviewedTask = await _taskRepository.fetchTaskById(
        occurrenceId: occurrenceId,
        childId: childId,
      );

      if (!mounted ||
          reviewedTask == null ||
          (reviewedTask.status != 'COMP' && reviewedTask.status != 'REJC')) {
        return;
      }

      _reviewNotificationIds.add(occurrenceId);

      setState(() {
        _tasks.removeWhere((task) => task.id == reviewedTask.id);
      });
      _showReviewNotification(reviewedTask);
    } catch (e) {
      logger.e('Error showing review notification: $e');
    }
  }

  void _showReviewNotification(TaskOccurrence task) {
    final title = task.template?.title ?? 'Your task';
    final isRejected = task.status == 'REJC';
    final feedback = task.feedback?.trim();
    final hasFeedback = feedback != null && feedback.isNotEmpty;

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: isRejected
              ? const Color(0xFFFFEAEA)
              : const Color(0xFFEAF8EA),
          leading: Icon(
            isRejected ? Icons.cancel : Icons.verified,
            color: isRejected ? Colors.red : Colors.green,
          ),
          content: InkWell(
            onTap: () => _openReviewedTask(task),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRejected ? '$title was rejected.' : '$title was approved!',
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: isRejected
                        ? const Color(0xFF7A1E1E)
                        : const Color(0xFF245B2A),
                  ),
                ),
                if (isRejected && hasFeedback) ...[
                  const SizedBox(height: 2),
                  Text(
                    feedback,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF7A1E1E),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () => _openReviewedTask(task),
              child: const Text('View'),
            ),
          ],
        ),
      );
  }

  void _openReviewedTask(TaskOccurrence task) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    _onTaskTap(task);
  }

  void _openExpirationReminderTask(TaskOccurrence task) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    _visibleExpirationReminderId = null;
    _onTaskTap(task);
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
    final selectedTasks = _tasksForSelectedDate;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildQuestHeader(),
                    const SizedBox(height: 16),
                    _buildDateNavigator(),
                    const SizedBox(height: 18),
                    _buildProgressPanel(selectedTasks),
                    const SizedBox(height: 18),
                    if (selectedTasks.isEmpty)
                      _buildEmptyState()
                    else ..._buildQuestSections(selectedTasks),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuestHeader() {
    return Row(
      children: [
        const SizedBox(width: 44),
        Expanded(
          child: Text(
            'My Quests',
            textAlign: TextAlign.center,
            style: GoogleFonts.pixelifySans(
              fontWeight: FontWeight.w500,
              fontSize: 28,
              color: const Color(0xFF5A3E36),
            ),
          ),
        ),
        _PixelIconButton(
          tooltip: 'Quest history',
          icon: Icons.history_edu,
          onPressed: () => context.go('/child/tasks/history'),
        ),
      ],
    );
  }

  Widget _buildDateNavigator() {
    return _PixelPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: () => _changeSelectedDate(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _pickQuestDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _selectedDateLabel(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A3E36),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: () => _changeSelectedDate(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel(List<TaskOccurrence> tasks) {
    final finishedCount = tasks.where((task) => task.status == 'PEND').length;
    final totalCount = tasks.length;
    final progress = totalCount == 0 ? 0.0 : finishedCount / totalCount;

    return Column(
      children: [
        Text(
          '$finishedCount of $totalCount quests done!',
          style: GoogleFonts.pixelifySans(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: const Color(0xFF5A3E36),
          ),
        ),
        const SizedBox(height: 12),
        _PixelProgressBar(value: progress),
      ],
    );
  }

  List<Widget> _buildQuestSections(List<TaskOccurrence> tasks) {
    final pending = tasks.where((task) => task.status == 'PEND').toList();
    final notDone = tasks.where((task) => task.status == 'NOTD').toList();
    final sections = <Widget>[];

    void addSection(String title, List<TaskOccurrence> sectionTasks) {
      if (sectionTasks.isEmpty) return;

      sections.add(_QuestSectionTitle(title: title));
      sections.addAll(sectionTasks.map((task) => _buildQuestCard(context, task)));
      sections.add(const SizedBox(height: 10));
    }

    addSection(
      'Morning',
      notDone.where((task) => task.dueDate.hour < 12).toList(),
    );
    addSection(
      'Afternoon',
      notDone
          .where((task) => task.dueDate.hour >= 12 && task.dueDate.hour < 18)
          .toList(),
    );
    addSection(
      'Night',
      notDone.where((task) => task.dueDate.hour >= 18).toList(),
    );
    addSection('Waiting for Approval', pending);

    return sections;
  }

  Widget _buildQuestCard(BuildContext context, TaskOccurrence task) {
    final isPending = task.status == 'PEND';
    final template = task.template!;
    final proofRequired = template.proofRequired;
    final resourceColor = _resourceColor(template.resource);

    return Opacity(
      opacity: isPending ? 0.72 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _onTaskTap(task),
            child: _PixelPanel(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      decoration: BoxDecoration(
                        color: resourceColor.withAlpha(36),
                        border: Border(
                          right: BorderSide(
                            color: const Color(0xFF5A3E36).withAlpha(80),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _resourceIcon(template.resource),
                          size: 34,
                          color: resourceColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration:
                                    isPending ? TextDecoration.lineThrough : null,
                                color: isPending
                                    ? Colors.grey.shade600
                                    : const Color(0xFF3E2D28),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDueDate(task.dueDate),
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6E5A50),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _RewardChip(
                                  icon: _resourceIcon(template.resource),
                                  label:
                                      '${template.resourceAmount} ${template.resource}',
                                  color: resourceColor,
                                ),
                                if (!isPending)
                                  _CountdownChip(dueDate: task.dueDate),
                                if (isPending)
                                  _StatusChip(
                                    label: 'Waiting Approval',
                                    color: Colors.orange,
                                    icon: Icons.hourglass_top,
                                  ),
                                if (proofRequired && !isPending)
                                  _StatusChip(
                                    label: 'Photo Proof',
                                    color: Colors.blue,
                                    icon: Icons.camera_alt,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuestActionButton(
                        isPending: isPending,
                        proofRequired: proofRequired,
                        onPressed:
                            isPending ? null : () => _confirmMarkAsDone(task),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.brown.shade300,
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
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
      color: isPending
          ? colorscheme.surfaceContainerLow.withAlpha(200)
          : colorscheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: isPending,
            onChanged: isPending ? null : (value) => _confirmMarkAsDone(task),
            activeColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 10,
                          color: Colors.blue,
                        ),
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

  List<TaskOccurrence> get _tasksForSelectedDate {
    final tasks = _tasks
        .where((task) => _isSameDate(task.dueDate, _selectedDate))
        .toList();
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _changeSelectedDate(int dayOffset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: dayOffset));
    });
  }

  Future<void> _pickQuestDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _selectedDateLabel() {
    final now = DateTime.now();
    if (_isSameDate(_selectedDate, now)) {
      return 'Today';
    }

    final tomorrow = now.add(const Duration(days: 1));
    if (_isSameDate(_selectedDate, tomorrow)) {
      return DateFormat('EEE, MMM d').format(_selectedDate);
    }

    return DateFormat('EEE, MMM d').format(_selectedDate);
  }

  IconData _resourceIcon(String resource) {
    switch (resource.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'play':
        return Icons.sports_esports_rounded;
      case 'clean':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  Color _resourceColor(String resource) {
    switch (resource.toLowerCase()) {
      case 'food':
        return const Color(0xFFE8873D);
      case 'play':
        return const Color(0xFF4F83CC);
      case 'clean':
        return const Color(0xFF48A06D);
      default:
        return const Color(0xFFB274C8);
    }
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
      backgroundColor: const Color(0xFFFFF6E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _buildTaskDetailSheet(task),
    );
  }

  Widget _buildTaskDetailSheet(TaskOccurrence task) {
    final template = task.template!;
    final isPending = task.status == 'PEND';
    final isCompleted = task.status == 'COMP';
    final isRejected = task.status == 'REJC';
    final resourceColor = _resourceColor(template.resource);
    final titleColor = const Color(0xFF5A3E36);

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: titleColor.withAlpha(90),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Text(
            //   'Quest Detail',
            //   textAlign: TextAlign.center,
            //   style: GoogleFonts.pixelifySans(
            //     fontSize: 24,
            //     fontWeight: FontWeight.w500,
            //     color: titleColor,
            //   ),
            // ),
            const SizedBox(height: 18),
            Text(
              template.title,
              style: GoogleFonts.quicksand(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniChip(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDueDate(task.dueDate),
                  color: const Color(0xFF6E5A50),
                ),
                if (!isPending && !isCompleted && !isRejected)
                  _MiniChip(
                    icon: Icons.timer_outlined,
                    label: 'Time left',
                    color: Colors.purple.shade500,
                  ),
                if ((isCompleted || isRejected) && task.approvalDate != null)
                  _MiniChip(
                    icon: isRejected
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    label:
                        '${isRejected ? 'Rejected' : 'Approved'} ${DateFormat('MMM d, h:mm a').format(task.approvalDate!)}',
                    color: isRejected ? Colors.red.shade700 : Colors.green.shade700,
                  ),
              ],
            ),
            if (!isPending && !isCompleted && !isRejected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.hourglass_bottom, size: 15, color: Colors.purple.shade500),
                  const SizedBox(width: 6),
                  TimeRemainingWidget(
                    dueDate: task.dueDate,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.purple.shade500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _PixelPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, color: titleColor),
                      const SizedBox(width: 8),
                      Text(
                        'What to do',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description.trim().isEmpty
                        ? 'No description provided.'
                        : template.description,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      height: 1.3,
                      color: const Color(0xFF3E2D28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if ((isPending || isCompleted || isRejected) &&
                task.proofUrl != null &&
                task.proofUrl!.isNotEmpty) ...[
              _PixelPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Your Photo Proof',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showZoomableImage(context, task.proofUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (template.proofRequired &&
                !isPending &&
                !isCompleted &&
                !isRejected)
              _PixelPanel(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 22, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This quest needs photo proof.',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (template.proofRequired &&
                !isPending &&
                !isCompleted &&
                !isRejected)
              const SizedBox(height: 16),

            if (isRejected &&
                task.feedback != null &&
                task.feedback!.trim().isNotEmpty) ...[
              _PixelPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.feedback_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Parent Feedback',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.feedback!.trim(),
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        height: 1.3,
                        color: const Color(0xFF3E2D28),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!isRejected)
              _PixelPanel(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: resourceColor.withAlpha(32),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: resourceColor, width: 2),
                      ),
                      child: Icon(
                        _resourceIcon(template.resource),
                        color: resourceColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reward',
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: resourceColor,
                            ),
                          ),
                          Text(
                            '${template.resourceAmount} ${template.resource} points!',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3E2D28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            if (task.status == 'NOTD')
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.pop(context);
                  _confirmMarkAsDone(task);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF58A96B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: titleColor, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF5A3E36),
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        template.proofRequired
                            ? Icons.camera_alt_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          template.proofRequired
                              ? 'Quest Done! Take Photo'
                              : 'Quest Done!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isPending)
              _PixelPanel(
                padding: const EdgeInsets.all(12),
                child: _QuestMessage(
                  icon: Icons.hourglass_top_rounded,
                  message: 'Quest finished! Waiting for approval.',
                  color: Colors.orange.shade800,
                ),
              )
            else if (isCompleted)
              _PixelPanel(
                padding: const EdgeInsets.all(12),
                child: _QuestMessage(
                  icon: Icons.check_circle_rounded,
                  message: 'Quest approved! Your reward has been added.',
                  color: Colors.green.shade800,
                ),
              )
            else if (isRejected)
              _PixelPanel(
                padding: const EdgeInsets.all(12),
                child: _QuestMessage(
                  icon: Icons.cancel_rounded,
                  message: 'Quest rejected. Check the feedback and try again next time.',
                  color: Colors.red.shade800,
                ),
              ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w900,
                  color: titleColor,
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
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: _PixelPanel(
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 54,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 14),
            Text(
              'No quests for this day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5A3E36),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use the arrows to check another day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelPanel extends StatelessWidget {
  const _PixelPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF5A3E36), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF5A3E36),
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PixelIconButton extends StatelessWidget {
  const _PixelIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0C2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5A3E36), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF5A3E36),
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF5A3E36)),
        ),
      ),
    );
  }
}

class _PixelProgressBar extends StatelessWidget {
  const _PixelProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5A3E36), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: const Color(0xFFE6D8C8),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF58A96B)),
          minHeight: 18,
        ),
      ),
    );
  }
}

class _QuestSectionTitle extends StatelessWidget {
  const _QuestSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
      child: Text(
        title,
        style: GoogleFonts.pixelifySans(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5A3E36),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _MiniChip(icon: icon, label: label, color: color);
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 13, color: Colors.purple.shade500),
        const SizedBox(width: 3),
        TimeRemainingWidget(
          dueDate: dueDate,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.purple.shade500,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _MiniChip(icon: icon, label: label, color: color);
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 72;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(120.0, 420.0).toDouble(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestActionButton extends StatelessWidget {
  const _QuestActionButton({
    required this.isPending,
    required this.proofRequired,
    required this.onPressed,
  });

  final bool isPending;
  final bool proofRequired;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isPending ? Colors.grey : const Color(0xFF58A96B);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 44,
        decoration: BoxDecoration(
          color: color.withAlpha(isPending ? 45 : 38),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(
          isPending
              ? Icons.hourglass_top
              : proofRequired
                  ? Icons.camera_alt
                  : Icons.check_circle,
          color: color,
        ),
      ),
    );
  }
}

class _QuestMessage extends StatelessWidget {
  const _QuestMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              color: color,
              fontWeight: FontWeight.w900,
            ),
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
