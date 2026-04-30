import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/tasks/data/task_repository.dart';
import 'package:happy_family_sim/features/tasks/model/task_category.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:intl/intl.dart';

class ParentTaskHistoryScreen extends StatefulWidget {
  const ParentTaskHistoryScreen({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<ParentTaskHistoryScreen> createState() =>
      _ParentTaskHistoryScreenState();
}

class _ParentTaskHistoryScreenState extends State<ParentTaskHistoryScreen> {
  final TaskRepository _taskRepository = TaskRepository();

  bool _isLoading = true;
  List<TaskOccurrence> _history = [];
  List<TaskCategory> _categories = [];

  String _calendarUnit = 'Month';
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';
  final Set<int> _selectedCategoryIds = {};
  final Set<String> _selectedChildIds = {};

  String get _parentId => widget.authRepository.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _taskRepository.fetchParentTaskHistory(_parentId),
        _taskRepository.fetchTaskCategories(_parentId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _history = results[0] as List<TaskOccurrence>;
        _categories = results[1] as List<TaskCategory>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Utils.showError(e.toString());
    }
  }

  List<TaskOccurrence> get _filteredHistory {
    final filtered = _history.where((task) {
      if (!_statusMatches(task)) {
        return false;
      }

      if (!_dateMatches(task)) {
        return false;
      }

      if (_selectedCategoryIds.isNotEmpty &&
          !_selectedCategoryIds.contains(task.template?.categoryId)) {
        return false;
      }

      if (_selectedChildIds.isNotEmpty &&
          !_selectedChildIds.contains(task.childId)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort(
      (first, second) =>
          _historyTime(second).compareTo(_historyTime(first)),
    );

    return filtered;
  }

  bool _statusMatches(TaskOccurrence task) {
    return _statusFilter == 'All' ||
        (_statusFilter == 'Complete' && task.status == 'COMP') ||
        (_statusFilter == 'Rejected' && task.status == 'REJC') ||
        (_statusFilter == 'Missed' && task.status == 'MISS');
  }

  bool _dateMatches(TaskOccurrence task) {
    final date = _historyTime(task);

    if (_calendarUnit == 'Day') {
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
    }

    if (_calendarUnit == 'Month') {
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month;
    }

    return date.year == _selectedDate.year;
  }

  DateTime _historyTime(TaskOccurrence task) {
    if ((task.status == 'COMP' || task.status == 'REJC') &&
        task.approvalDate != null) {
      return task.approvalDate!;
    }

    return task.dueDate;
  }

  List<_ChildFilter> get _children {
    final childrenById = <String, _ChildFilter>{};
    for (final task in _history) {
      childrenById[task.childId] = _ChildFilter(
        id: task.childId,
        name: task.childName,
        avatarUrl: task.childAvatar,
      );
    }

    final children = childrenById.values.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return children;
  }

  void _changeDate(int offset) {
    setState(() {
      if (_calendarUnit == 'Day') {
        _selectedDate = _selectedDate.add(Duration(days: offset));
      } else if (_calendarUnit == 'Month') {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + offset,
          _selectedDate.day,
        );
      } else {
        _selectedDate = DateTime(
          _selectedDate.year + offset,
          _selectedDate.month,
          _selectedDate.day,
        );
      }
    });
  }

  Future<void> _pickDate() async {
    if (_calendarUnit == 'Day') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (picked != null) {
        setState(() => _selectedDate = picked);
      }
      return;
    }

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onDateChanged: (date) => Navigator.pop(context, date),
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E8),
      appBar: AppBar(
        backgroundColor: const Color(0xffebdfcc),
        centerTitle: true,
        elevation: 1,
        title: Text(
          'Task History',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _buildCalendarPanel(),
                  const SizedBox(height: 16),
                  _buildStatusFilters(),
                  const SizedBox(height: 14),
                  _buildCategoryFilters(),
                  const SizedBox(height: 14),
                  _buildChildFilters(),
                  const SizedBox(height: 18),
                  ..._buildHistoryList(),
                ],
              ),
      ),
    );
  }

  Widget _buildCalendarPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _calendarUnit,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.calendar_view_month),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const ['Day', 'Month', 'Year']
                .map(
                  (unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _calendarUnit = value);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: () => _changeDate(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _calendarLabel(),
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
                tooltip: 'Next',
                onPressed: () => _changeDate(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calendarLabel() {
    if (_calendarUnit == 'Day') {
      return DateFormat('MMM d, yyyy').format(_selectedDate);
    }

    if (_calendarUnit == 'Month') {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    }

    return DateFormat('yyyy').format(_selectedDate);
  }

  Widget _buildStatusFilters() {
    return _FilterSection(
      title: 'Status',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ['All', 'Complete', 'Rejected', 'Missed'].map((status) {
          final isSelected = _statusFilter == status;
          final color = _statusColor(status);

          return FilterChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (_) => setState(() => _statusFilter = status),
            selectedColor: color.withAlpha(42),
            checkmarkColor: color,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? color : Colors.brown.shade100),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return _FilterSection(
      title: 'Category',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SmallChoiceChip(
              label: 'All',
              color: Theme.of(context).colorScheme.primary,
              isSelected: _selectedCategoryIds.isEmpty,
              onTap: () => setState(() => _selectedCategoryIds.clear()),
            ),
            ..._categories.map(
              (category) => _SmallChoiceChip(
                label: category.name,
                color: category.color,
                isSelected: _selectedCategoryIds.contains(category.id),
                side: BorderSide(color: _selectedCategoryIds.contains(category.id) ? category.color : Colors.brown.shade100),
                onTap: () => setState(() {
                  if (!_selectedCategoryIds.remove(category.id)) {
                    _selectedCategoryIds.add(category.id);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildFilters() {
    return _FilterSection(
      title: 'Children',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChildChip(
              label: 'All',
              avatarUrl: '',
              isSelected: _selectedChildIds.isEmpty,
              icon: Icons.groups_rounded,
              onTap: () => setState(() => _selectedChildIds.clear()),
            ),
            ..._children.map(
              (child) => _ChildChip(
                label: child.name,
                avatarUrl: child.avatarUrl,
                isSelected: _selectedChildIds.contains(child.id),
                onTap: () => setState(() {
                  if (!_selectedChildIds.remove(child.id)) {
                    _selectedChildIds.add(child.id);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHistoryList() {
    final tasks = _filteredHistory;
    if (tasks.isEmpty) {
      return [
        _EmptyHistoryMessage(
          hasHistory: _history.isNotEmpty,
        ),
      ];
    }

    return tasks.map(_buildHistoryCard).toList();
  }

  Widget _buildHistoryCard(TaskOccurrence task) {
    final color = _taskStatusColor(task.status);
    final categoryColor = _categoryColor(task);
    final time = _historyTime(task);
    final isMissed = task.status == 'MISS';

    return Opacity(
      opacity: isMissed ? 0.62 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withAlpha(70)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showTaskDetails(task),
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
                        _HistoryAvatar(
                          avatarUrl: task.childAvatar,
                          status: task.status,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.template?.title ?? 'Untitled task',
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: const Color(0xFF5A3E36),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.childName,
                                style: GoogleFonts.quicksand(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_statusPastTense(task.status)}: ${DateFormat('MMM d, h:mm a').format(time)}',
                                style: GoogleFonts.quicksand(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(
                          label: _statusLabel(task.status),
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.outline,
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

  Color _categoryColor(TaskOccurrence task) {
    final categoryId = task.template?.categoryId;
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category.color;
      }
    }

    return Theme.of(context).colorScheme.outline;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Complete':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Missed':
        return Colors.grey;
      default:
        return const Color(0xFF5A3E36);
    }
  }

  Color _taskStatusColor(String status) {
    switch (status) {
      case 'COMP':
        return Colors.green;
      case 'REJC':
        return Colors.red;
      case 'MISS':
        return Colors.grey;
      default:
        return const Color(0xFF5A3E36);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMP':
        return 'Complete';
      case 'REJC':
        return 'Rejected';
      case 'MISS':
        return 'Missed';
      default:
        return status;
    }
  }

  String _statusPastTense(String status) {
    switch (status) {
      case 'COMP':
        return 'Completed';
      case 'REJC':
        return 'Rejected';
      case 'MISS':
        return 'Missed';
      default:
        return 'Updated';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'COMP':
        return Icons.check_circle;
      case 'REJC':
        return Icons.cancel;
      case 'MISS':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  void _showTaskDetails(TaskOccurrence task) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (context, scrollController) => _HistoryDetailSheet(
          task: task,
          statusColor: _taskStatusColor(task.status),
          statusLabel: _statusLabel(task.status),
          statusIcon: _statusIcon(task.status),
          historyTime: _historyTime(task),
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5A3E36),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SmallChoiceChip extends StatelessWidget {
  const _SmallChoiceChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.side,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final BorderSide? side;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: color.withAlpha(42),
        checkmarkColor: color,
        side: side ?? BorderSide(color: isSelected ? color : Colors.brown.shade100),
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({
    required this.label,
    required this.avatarUrl,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String avatarUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: isSelected ? color.withAlpha(45) : Colors.white,
            backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
            child: icon != null
                ? Icon(icon, color: color)
                : avatarUrl.isEmpty
                ? Text(label.isEmpty ? '?' : label[0].toUpperCase())
                : null,
          ),
        ),
      ),
    );
  }
}

class _HistoryAvatar extends StatelessWidget {
  const _HistoryAvatar({
    required this.avatarUrl,
    required this.status,
  });

  final String avatarUrl;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'REJC'
        ? Colors.red
        : status == 'COMP'
            ? Colors.green
            : Colors.grey;

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
          child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'COMP'
                  ? Icons.check
                  : status == 'REJC'
                      ? Icons.close
                      : Icons.schedule,
              size: 11,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  const _HistoryDetailSheet({
    required this.task,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.historyTime,
    required this.scrollController,
  });

  final TaskOccurrence task;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final DateTime historyTime;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: GoogleFonts.quicksand(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            task.template?.title ?? 'Untitled task',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: const Color(0xFF5A3E36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task.childName,
            style: GoogleFonts.quicksand(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.event,
            label: 'Due',
            value: DateFormat('MMM d, yyyy h:mm a').format(task.dueDate),
          ),
          if (task.status == 'COMP' || task.status == 'REJC')
            _DetailRow(
              icon: Icons.verified_outlined,
              label: statusLabel,
              value: DateFormat('MMM d, yyyy h:mm a').format(historyTime),
            ),
          const SizedBox(height: 18),
          Text(
            'Description',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            task.template?.description.trim().isNotEmpty == true
                ? task.template!.description
                : 'No description provided.',
          ),
          if (task.feedback?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Text(
              'Feedback',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(45)),
              ),
              child: Text(task.feedback!),
            ),
          ],
          if (task.proofUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Text(
              'Proof',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                task.proofUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  const _EmptyHistoryMessage({required this.hasHistory});

  final bool hasHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 44,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            hasHistory
                ? 'No tasks match these filters.'
                : 'No completed, missed, or rejected tasks yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChildFilter {
  const _ChildFilter({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;
}
