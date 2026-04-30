import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/tasks/data/child/tasks_repository.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';

const _questBackground = Color(0xFFFFF6E8);
const _questPanel = Color(0xFFFFFBF2);
const _questBrown = Color(0xFF5A3E36);
const _questText = Color(0xFF3E2D28);
const _questMuted = Color(0xFF6E5A50);
const _questSuccess = Color(0xFF58A96B);
const _questMissed = Color(0xFF8A7A70);
const _questDanger = Color(0xFFD05A4E);
const _questPhoto = Color(0xFF4F83CC);
const _questFood = Color(0xFFE8873D);
const _questPlay = Color(0xFF4F83CC);
const _questClean = Color(0xFF48A06D);
const _questMagic = Color(0xFFB274C8);

class TaskHistoryScreen extends StatefulWidget {
  final AuthRepository authRepository;
  const TaskHistoryScreen({super.key, required this.authRepository});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  final ChildTaskRepository _taskRepository = ChildTaskRepository();
  bool _isLoading = true;
  List<TaskOccurrence> _allHistory = [];

  String _statusFilter = 'All';
  String _periodFilter = 'Month';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = widget.authRepository.currentUser?.id;
      if (userId == null) return;

      final result = await _taskRepository.fetchTaskHistoryByChildId(userId);

      if (mounted) {
        setState(() {
          _allHistory = result;
        });
      }
    } catch (e) {
      Utils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchHistory();
  }

  List<TaskOccurrence> get _filteredTasks {
    return _allHistory.where((task) {
      // filter by status
      bool statusMatch =
          _statusFilter == 'All' ||
          (_statusFilter == 'Completed' && task.status == 'COMP') ||
          (_statusFilter == 'Missed' && task.status == 'MISS') ||
          (_statusFilter == 'Rejected' && task.status == 'REJC');

      if (!statusMatch) return false;

      // filter by period
      final filterDate = task.dueDate;

      if (_periodFilter == 'Day') {
        return filterDate.year == _selectedDate.year &&
            filterDate.month == _selectedDate.month &&
            filterDate.day == _selectedDate.day;
      } else if (_periodFilter == 'Month') {
        return filterDate.year == _selectedDate.year &&
            filterDate.month == _selectedDate.month;
      } else if (_periodFilter == 'Year') {
        return filterDate.year == _selectedDate.year;
      }

      return true;
    }).toList()..sort((a, b) {
      // status priority: Completed (0) > Rejected (1) > Missed (2)
      int getStatusPriority(String status) {
        switch (status) {
          case 'COMP':
            return 0;
          case 'REJC':
            return 1;
          case 'MISS':
            return 2;
          default:
            return 3;
        }
      }

      final priorityA = getStatusPriority(a.status);
      final priorityB = getStatusPriority(b.status);

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // same status, sort by date (newest first)
      final dateA = a.dueDate;
      final dateB = b.dueDate;
      return dateB.compareTo(dateA);
    });
  }

  void _changeDate(int offset) {
    DateTime newDate;

    if (_periodFilter == 'Day') {
      newDate = _selectedDate.add(Duration(days: offset));
    } else if (_periodFilter == 'Month') {
      newDate = DateTime(_selectedDate.year, _selectedDate.month + offset);
    } else {
      newDate = DateTime(_selectedDate.year + offset);
    }

    setState(() {
      _selectedDate = newDate;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_periodFilter == 'Day') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _questBrown,
                onPrimary: Colors.white,
                onSurface: _questBrown,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
      }
    } else if (_periodFilter == 'Month') {
      await _showMonthPicker(context);
    } else if (_periodFilter == 'Year') {
      await _showYearPicker(context);
    }
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _questBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Select Month (${_selectedDate.year})',
            style: GoogleFonts.pixelifySans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _questBrown,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final bool isSelected = _selectedDate.month == index + 1;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        index + 1,
                        _selectedDate.day,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _questBrown.withAlpha(40)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: _questBrown, width: 2)
                          : null,
                    ),
                    child: Text(
                      months[index].substring(0, 3),
                      style: GoogleFonts.quicksand(
                        color: isSelected ? _questBrown : _questText,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showYearPicker(BuildContext context) async {
    const int startYear = 2020;
    const int endYear = 2100;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _questBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Select Year',
            style: GoogleFonts.pixelifySans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _questBrown,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: endYear - startYear + 1,
              itemBuilder: (context, index) {
                final year = endYear - index;
                final bool isSelected = _selectedDate.year == year;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  title: Text(
                    year.toString(),
                    style: GoogleFonts.quicksand(
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: isSelected ? _questBrown : _questText,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(
                        year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );
                    });
                    Navigator.pop(context);
                  },
                  selected: isSelected,
                  selectedTileColor: _questBrown.withAlpha(20),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _questBackground,
      appBar: AppBar(
        backgroundColor: _questBackground,
        foregroundColor: _questBrown,
        elevation: 0,
        title: Text(
          'Quest History',
          style: GoogleFonts.pixelifySans(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: _questBrown,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 14),
                      _buildStatusFilter(),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredTasks.isEmpty)
                SliverFillRemaining(child: _buildQuestEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) =>
                        _buildQuestHistoryCard(_filteredTasks[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final dateText = _periodDateText();

    return _PixelPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: ['Day', 'Month', 'Year'].map((period) {
              return _FilterPill(
                label: period,
                isSelected: _periodFilter == period,
                color: _questBrown,
                onTap: () => setState(() => _periodFilter = period),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PixelIconButton(
                tooltip: 'Previous $_periodFilter',
                icon: Icons.chevron_left,
                onPressed: () => _changeDate(-1),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      dateText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pixelifySans(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: _questBrown,
                      ),
                    ),
                  ),
                ),
              ),
              _PixelIconButton(
                tooltip: 'Next $_periodFilter',
                icon: Icons.chevron_right,
                onPressed: () => _changeDate(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Completed', 'Missed', 'Rejected'].map((status) {
          final isSelected = _statusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterPill(
              label: status,
              icon: status == 'All' ? Icons.auto_awesome : _getStatusIcon(
                status == 'Completed'
                    ? 'COMP'
                    : status == 'Missed'
                        ? 'MISS'
                        : 'REJC',
              ),
              isSelected: isSelected,
              color: _getStatusColor(status),
              onTap: () => setState(() => _statusFilter = status),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _periodDateText() {
    if (_periodFilter == 'Day') {
      return DateFormat('MMM d, yyyy').format(_selectedDate);
    }
    if (_periodFilter == 'Month') {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    }
    return DateFormat('yyyy').format(_selectedDate);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return _questSuccess;
      case 'Missed':
        return _questMissed;
      case 'Rejected':
        return _questDanger;
      default:
        return _questBrown;
    }
  }

  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'COMP':
        return _questSuccess;
      case 'MISS':
        return _questMissed;
      case 'REJC':
        return _questDanger;
      default:
        return _questPhoto;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'COMP':
        return 'Completed';
      case 'MISS':
        return 'Missed';
      case 'REJC':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Widget _buildQuestHistoryCard(TaskOccurrence task) {
    final statusColor = _getTaskStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);
    final template = task.template;
    final resourceColor = _resourceColor(template?.resource ?? '');
    final useApprovalDate =
        (task.status == 'COMP' || task.status == 'REJC') &&
        task.approvalDate != null;
    final displayDate = useApprovalDate ? task.approvalDate! : task.dueDate;
    final dateLabel = useApprovalDate
        ? (task.status == 'REJC' ? 'Rejected' : 'Completed')
        : (task.status == 'MISS' ? 'Missed' : 'Due');

    return Opacity(
      opacity: task.status == 'MISS' ? 0.74 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showQuestTaskDetails(task),
            child: _PixelPanel(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(6),
                        ),
                      ),
                    ),
                    Container(
                      width: 64,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        border: Border(
                          right: BorderSide(
                            color: _questBrown.withAlpha(80),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getStatusIcon(task.status),
                          color: statusColor,
                          size: 30,
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
                              template?.title ?? 'Unknown Quest',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _questText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dateLabel ${DateFormat('MMM d, h:mm a').format(displayDate)}',
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _questMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MiniChip(
                                  icon: _getStatusIcon(task.status),
                                  label: statusLabel,
                                  color: statusColor,
                                ),
                                if (template != null)
                                  _MiniChip(
                                    icon: _resourceIcon(template.resource),
                                    label:
                                        '${template.resourceAmount} ${template.resource}',
                                    color: resourceColor,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _questBrown.withAlpha(120)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuestTaskDetails(TaskOccurrence task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _questBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _buildQuestTaskDetailSheet(task),
    );
  }

  Widget _buildQuestTaskDetailSheet(TaskOccurrence task) {
    final statusColor = _getTaskStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);
    final template = task.template;
    final resourceColor = _resourceColor(template?.resource ?? '');
    const titleColor = _questBrown;

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
            Text(
              'Quest Log',
              textAlign: TextAlign.center,
              style: GoogleFonts.pixelifySans(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              template?.title ?? 'Quest Details',
              style: GoogleFonts.quicksand(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Due ${DateFormat('MMM d, h:mm a').format(task.dueDate)}',
                  color: _questMuted,
                ),
                _MiniChip(
                  icon: _getStatusIcon(task.status),
                  label: statusLabel,
                  color: statusColor,
                ),
                if (task.approvalDate != null &&
                    (task.status == 'COMP' || task.status == 'REJC'))
                  _MiniChip(
                    icon: task.status == 'REJC'
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    label:
                        '${task.status == 'REJC' ? 'Rejected' : 'Completed'} ${DateFormat('MMM d, h:mm a').format(task.approvalDate!)}',
                    color: statusColor,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _PixelPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle(
                    icon: Icons.flag_rounded,
                    label: 'What it was',
                    color: titleColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template?.description.trim().isNotEmpty == true
                        ? template!.description
                        : 'No description provided.',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      height: 1.3,
                      color: _questText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PixelPanel(
              padding: const EdgeInsets.all(12),
              child: _PanelTitle(
                icon: _getStatusIcon(task.status),
                label: _statusMessage(task.status),
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            if (task.proofUrl != null && task.proofUrl!.isNotEmpty) ...[
              _PixelPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PanelTitle(
                      icon: Icons.camera_alt_rounded,
                      label: 'Photo Proof',
                      color: _questPhoto,
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
                          color: _questMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (task.feedback != null && task.feedback!.trim().isNotEmpty) ...[
              _PixelPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PanelTitle(
                      icon: Icons.feedback_rounded,
                      label: 'Parent Feedback',
                      color: _questDanger,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.feedback!.trim(),
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        height: 1.3,
                        color: _questText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (template != null)
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
                      child: Text(
                        'Reward: ${template.resourceAmount} ${template.resource}',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: resourceColor,
                        ),
                      ),
                    ),
                  ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuestEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _PixelPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_edu,
                size: 64,
                color: _questBrown.withAlpha(120),
              ),
              const SizedBox(height: 16),
              Text(
                'No quest logs found.',
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _questBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try changing the filters or date.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  color: _questMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'COMP':
        return 'Quest complete. Nice work!';
      case 'MISS':
        return 'Quest missed. Try the next one!';
      case 'REJC':
        return 'Quest rejected. Check the feedback.';
      default:
        return 'Quest recorded.';
    }
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
        return _questFood;
      case 'play':
        return _questPlay;
      case 'clean':
        return _questClean;
      default:
        return _questMagic;
    }
  }

  Widget _buildHistoryCard(TaskOccurrence task) {
    final statusColor = _getTaskStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);

    // On the card part, display the approval date for rejected and completed tasks,
    // for missed tasks just displayed the due date.
    final bool useApprovalDate =
        (task.status == 'COMP' || task.status == 'REJC') &&
        task.approvalDate != null;
    final displayDate = useApprovalDate ? task.approvalDate! : task.dueDate;
    final dateLabel = useApprovalDate
        ? 'Approved: '
        : (task.status == 'MISS' ? 'Missed: ' : 'Due: ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(_getStatusIcon(task.status), color: statusColor),
        ),
        title: Text(
          task.template?.title ?? 'Unknown Task',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dateLabel${DateFormat('MMM d, yyyy • h:mm a').format(displayDate)}',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.quicksand(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'COMP':
        return Icons.check_circle;
      case 'MISS':
        return Icons.error_outline;
      case 'REJC':
        return Icons.cancel;
      default:
        return Icons.help_outline;
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

  void _showTaskDetails(TaskOccurrence task) {
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
    final statusColor = _getTaskStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              task.template?.title ?? 'Task Details',
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Display due date and approval date for tasks that are completed and rejected
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Due: ${DateFormat('MMMM d, yyyy • h:mm a').format(task.dueDate)}',
                  style: GoogleFonts.quicksand(color: Colors.grey[600]),
                ),
              ],
            ),
            if (task.approvalDate != null &&
                (task.status == 'COMP' || task.status == 'REJC')) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Approved: ${DateFormat('MMMM d, yyyy • h:mm a').format(task.approvalDate!)}',
                    style: GoogleFonts.quicksand(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // task status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(task.status),
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // description
            Text(
              'Description',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.template?.description ?? 'No description provided.',
              style: GoogleFonts.quicksand(fontSize: 16),
            ),
            // photo proof
            if (task.proofUrl != null && task.proofUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
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
            ],
            // feedback
            if (task.feedback != null && task.feedback!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Feedback from Parent',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Text(
                  task.feedback!,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // reward
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Rewards: ${task.template?.resourceAmount} ${task.template?.resource}',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No tasks found for this period.',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try changing the filters or date.',
                style: GoogleFonts.quicksand(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
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
        color: _questPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _questBrown, width: 2),
        boxShadow: const [
          BoxShadow(
            color: _questBrown,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0C2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _questBrown, width: 2),
            boxShadow: const [
              BoxShadow(
                color: _questBrown,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: _questBrown),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(42) : _questPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : _questBrown.withAlpha(90),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected ? color : _questBrown,
              ),
            ),
          ],
        ),
      ),
    );
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
