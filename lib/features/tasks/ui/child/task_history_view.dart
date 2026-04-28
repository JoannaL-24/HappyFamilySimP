import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/tasks/data/child/tasks_repository.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';

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
                primary: Color(0xFF5A3E36),
                onPrimary: Colors.white,
                onSurface: Color(0xFF5A3E36),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Month (${_selectedDate.year})',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
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
                          ? const Color(0xFF5A3E36).withAlpha(40)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      months[index].substring(0, 3),
                      style: GoogleFonts.quicksand(
                        color: isSelected
                            ? const Color(0xFF5A3E36)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Year',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
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
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF5A3E36)
                          : Colors.black87,
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
                  selectedTileColor: const Color(0xFF5A3E36).withAlpha(20),
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
      backgroundColor: const Color(0xFFFFF6E8),
      appBar: AppBar(
        backgroundColor: const Color(0xffebdfcc),
        title: Text(
          'Task History',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36),
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildStatusFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) =>
                          _buildHistoryCard(_filteredTasks[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    String dateText;

    if (_periodFilter == 'Day') {
      dateText = DateFormat('MMMM d, yyyy').format(_selectedDate);
    } else if (_periodFilter == 'Month') {
      dateText = DateFormat('MMMM yyyy').format(_selectedDate);
    } else {
      dateText = DateFormat('yyyy').format(_selectedDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white.withAlpha(128),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Day', 'Month', 'Year'].map((p) {
              bool isSelected = _periodFilter == p;
              return ChoiceChip(
                label: Text(
                  p,
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
                ),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _periodFilter = p);
                },
                selectedColor: const Color(0xFF5A3E36).withAlpha(40),
                checkmarkColor: const Color(0xFF5A3E36),
              );
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeDate(-1),
              ),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    dateText,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['All', 'Completed', 'Missed', 'Rejected'].map((status) {
          bool isSelected = _statusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status, style: GoogleFonts.quicksand(fontSize: 12)),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _statusFilter = status);
              },
              backgroundColor: Colors.white,
              selectedColor: _getStatusColor(status).withAlpha(40),
              checkmarkColor: _getStatusColor(status),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Missed':
        return Colors.grey;
      case 'Rejected':
        return Colors.red;
      default:
        return const Color(0xFF5A3E36);
    }
  }

  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'COMP':
        return Colors.green;
      case 'MISS':
        return Colors.grey;
      case 'REJC':
        return Colors.red;
      default:
        return Colors.blue;
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
