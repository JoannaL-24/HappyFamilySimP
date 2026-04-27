import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/approval/data/approval_repository.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentApprovalScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const ParentApprovalScreen({super.key, required this.authRepository});

  @override
  State<ParentApprovalScreen> createState() => _ParentApprovalScreenState();
}

class _ParentApprovalScreenState extends State<ParentApprovalScreen> {
  final ApprovalRepository _approvalRepository = ApprovalRepository();
  bool _isLoading = true;
  List<TaskOccurrence> _pendingTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingTasks();
  }

  Future<void> _onRefresh() async {
    await _fetchPendingTasks();
  }

  Future<void> _fetchPendingTasks() async {
    setState(() => _isLoading = true);
    try {
      final parentId = widget.authRepository.currentUser?.id;
      if (parentId == null) return;

      final tasks = await _approvalRepository.fetchPendingTasks(parentId);
      if (mounted) {
        setState(() {
          _pendingTasks = tasks;
        });
      }
    } catch (e) {
      Utils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveTask(TaskOccurrence task) async {
    try {
      // Pass the whole task object instead of just the ID
      await _approvalRepository.approveTask(task);

      if (mounted) {
        Utils.showSuccess(
          'Approved! ${task.childName} received ${task.template?.resourceAmount} ${task.template?.resource} points!',
        );
        _fetchPendingTasks();
      }
    } catch (e) {
      Utils.showError('Could not approve task. Please try again.');
    }
  }

  Future<void> _rejectTask(TaskOccurrence task, String feedback) async {
    try {
      await _approvalRepository.rejectTask(task.id, feedback);
      if (mounted) {
        Utils.showSuccess(
          'Task "${task.template?.title}" from "${task.childName}" rejected.',
        );
        _fetchPendingTasks();
      }
    } catch (e) {
      Utils.showError('Could not reject task. Please try again.');
    }
  }

  void _showApprovalDetails(TaskOccurrence task) {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.7,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildApprovalDetailSheet(task),
    );
  }

  Future<void> _showRejectionDialog(TaskOccurrence task) async {
    final theme = Theme.of(context);
    final feedbackController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide feedback on why this task is being rejected.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: feedbackController,
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Feedback is required to reject a task.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, feedbackController.text.trim());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != null && mounted) {
      // Close the bottom sheet as well
      Navigator.pop(context);
      await _rejectTask(task, confirmed);
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

  Widget _buildApprovalDetailSheet(TaskOccurrence task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final template = task.template!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Review Submission',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // child icon and name
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.surfaceDim,
                backgroundImage: task.childAvatar.isNotEmpty
                    ? NetworkImage(task.childAvatar)
                    : null,
                child: task.childAvatar.isEmpty
                    ? Text(task.childName[0].toUpperCase())
                    : null,
              ),
              title: Text(
                task.childName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Submitted for review'),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // title
            Text(
              template.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // description
            Text(template.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            // due date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${DateFormat('MMM d, h:mm a').format(task.dueDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            // photo proof
            if (task.proofUrl != null && task.proofUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showZoomableImage(context, task.proofUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    task.proofUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.red),
                          SizedBox(height: 4),
                          Text(
                            'Could not load image',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap photo to zoom',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectionDialog(task),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.error),
                      foregroundColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _approveTask(task);
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
                      'Approve',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
        title: Text(
          'Pending Approvals',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36), //soft dark brown
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffebdfcc),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingTasks.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingTasks.length,
                itemBuilder: (context, index) =>
                    _buildApprovalCard(context, _pendingTasks[index]),
              ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, TaskOccurrence task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final template = task.template!;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.primary.withAlpha(50), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showApprovalDetails(task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.surfaceDim,
                backgroundImage: task.childAvatar.isNotEmpty
                    ? NetworkImage(task.childAvatar)
                    : null,
                child: task.childAvatar.isEmpty
                    ? Text(task.childName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'from ${task.childName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d').format(task.dueDate),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: colorScheme.outline),
            ],
          ),
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
              Icon(Icons.done_all, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No tasks pending your approval.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
