import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:happy_family_sim/features/tasks/model/task_template.dart';

class ChildTaskHistoryScreen extends StatefulWidget {
  const ChildTaskHistoryScreen({super.key});

  @override
  State<ChildTaskHistoryScreen> createState() => _ChildTaskHistoryScreenState();
}

class _ChildTaskHistoryScreenState extends State<ChildTaskHistoryScreen> {
  String _statusFilter = 'All';
  String _periodFilter = 'Month'; // Default to Month
  DateTime _selectedDate = DateTime.now();

  // Fake data for UI development
  final List<TaskOccurrence> _allHistory = [
    TaskOccurrence(
      id: 1,
      childId: 'child1',
      childName: 'Taylor',
      dueDate: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'COMP',
      templateId: 101,
      template: TaskTemplate(
        id: 101,
        title: 'Clean Room',
        description: 'Make your bed and vacuum the floor.',
        proofRequired: false,
        resource: 'clean',
        resourceAmount: 10,
      ),
    ),
    TaskOccurrence(
      id: 2,
      childId: 'child1',
      childName: 'Taylor',
      dueDate: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      status: 'MISS',
      templateId: 102,
      template: TaskTemplate(
        id: 102,
        title: 'Wash Dishes',
        description: 'Wash and dry all the dishes from dinner.',
        proofRequired: true,
        resource: 'food',
        resourceAmount: 15,
      ),
    ),
    TaskOccurrence(
      id: 3,
      childId: 'child1',
      childName: 'Taylor',
      dueDate: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      status: 'REJ',
      templateId: 103,
      template: TaskTemplate(
        id: 103,
        title: 'Walk Dog',
        description: 'Take the dog for a 15 minute walk around the block.',
        proofRequired: true,
        resource: 'play',
        resourceAmount: 20,
      ),
      feedback: 'The walk was too short. Please try again tomorrow.',
    ),
    TaskOccurrence(
      id: 4,
      childId: 'child1',
      childName: 'Taylor',
      dueDate: DateTime.now().subtract(const Duration(days: 10)),
      status: 'COMP',
      templateId: 101,
      template: TaskTemplate(
        id: 101,
        title: 'Clean Room',
        description: 'Make your bed and vacuum the floor.',
        proofRequired: false,
        resource: 'clean',
        resourceAmount: 10,
      ),
    ),
    TaskOccurrence(
      id: 5,
      childId: 'child1',
      childName: 'Taylor',
      dueDate: DateTime.now().subtract(const Duration(days: 45)),
      status: 'COMP',
      templateId: 104,
      template: TaskTemplate(
        id: 104,
        title: 'Water Plants',
        description: 'Water all the indoor plants.',
        proofRequired: false,
        resource: 'food',
        resourceAmount: 5,
      ),
    ),
    TaskOccurrence(
      id: 6,
      childId: 'child1',
      childName: 'Taylor',
      dueDate: DateTime(2025, 12, 25, 10, 0),
      status: 'COMP',
      templateId: 105,
      template: TaskTemplate(
        id: 105,
        title: 'Open Presents',
        description: 'Merry Christmas!',
        proofRequired: false,
        resource: 'play',
        resourceAmount: 100,
      ),
    ),
  ];

  List<TaskOccurrence> get _filteredTasks {
    return _allHistory.where((task) {
      // Only show final statuses in history
      bool isFinalStatus = task.status == 'COMP' || task.status == 'MISS' || task.status == 'REJ';
      if (!isFinalStatus) return false;

      // Filter by status
      bool statusMatch = _statusFilter == 'All' || 
          (_statusFilter == 'Completed' && task.status == 'COMP') ||
          (_statusFilter == 'Missed' && task.status == 'MISS') ||
          (_statusFilter == 'Rejected' && task.status == 'REJ');

      if (!statusMatch) return false;

      // Filter by period
      if (_periodFilter == 'Day') {
        return task.dueDate.year == _selectedDate.year &&
               task.dueDate.month == _selectedDate.month &&
               task.dueDate.day == _selectedDate.day;
      } else if (_periodFilter == 'Month') {
        return task.dueDate.year == _selectedDate.year &&
               task.dueDate.month == _selectedDate.month;
      } else if (_periodFilter == 'Year') {
        return task.dueDate.year == _selectedDate.year;
      }

      return true;
    }).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  void _changeDate(int offset) {
    setState(() {
      if (_periodFilter == 'Day') {
        _selectedDate = _selectedDate.add(Duration(days: offset));
      } else if (_periodFilter == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset);
      } else if (_periodFilter == 'Year') {
        _selectedDate = DateTime(_selectedDate.year + offset);
      }
    });
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
            child: _filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) => _buildHistoryCard(_filteredTasks[index]),
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
                label: Text(p, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
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
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
              Text(
                dateText,
                style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
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
      case 'Completed': return Colors.green;
      case 'Missed': return Colors.grey;
      case 'Rejected': return Colors.red;
      default: return const Color(0xFF5A3E36);
    }
  }

  Color _getTaskStatusColor(String status) {
    switch (status) {
      case 'COMP': return Colors.green;
      case 'MISS': return Colors.grey;
      case 'REJ': return Colors.red;
      default: return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'COMP': return 'Completed';
      case 'MISS': return 'Missed';
      case 'REJ': return 'Rejected';
      default: return 'Unknown';
    }
  }

  Widget _buildHistoryCard(TaskOccurrence task) {
    final statusColor = _getTaskStatusColor(task.status);
    final statusLabel = _getStatusLabel(task.status);

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
            Text(DateFormat('MMM d, yyyy • h:mm a').format(task.dueDate)),
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
      case 'COMP': return Icons.check_circle;
      case 'MISS': return Icons.error_outline;
      case 'REJ': return Icons.cancel;
      default: return Icons.help_outline;
    }
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
            Text(
              task.template?.title ?? 'Task Details',
              style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(task.dueDate),
                  style: GoogleFonts.quicksand(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(task.status), color: statusColor, size: 18),
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
            Text(
              'Description',
              style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              task.template?.description ?? 'No description provided.',
              style: GoogleFonts.quicksand(fontSize: 16),
            ),
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
    return Center(
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
    );
  }
}
