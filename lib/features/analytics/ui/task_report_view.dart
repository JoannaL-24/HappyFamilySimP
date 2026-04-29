import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/management/data/manage_repository.dart';
import 'package:happy_family_sim/features/analytics/data/analytics_repository.dart';

class TaskReportScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final ManageRepository manageRepository;
  final AnalyticsRepository analyticsRepository;

  const TaskReportScreen({
    super.key,
    required this.authRepository,
    required this.manageRepository,
    required this.analyticsRepository,
  });

  @override
  State<TaskReportScreen> createState() => _TaskReportScreenState();
}

class _TaskReportScreenState extends State<TaskReportScreen> {
  late DateTimeRange _selectedDateRange;
  String _selectedChildId = 'All Children';
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  TaskReportData? _reportData;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: lastDay,
    );
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final parentId = widget.authRepository.currentUser?.id;
      if (parentId != null) {
        final children = await widget.manageRepository.fetchChildrenData(parentId);
        setState(() {
          _children = children;
        });
        await _fetchReport();
      }
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReport() async {
    final parentId = widget.authRepository.currentUser?.id;
    if (parentId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await widget.analyticsRepository.getTaskReport(
        parentId: parentId,
        childId: _selectedChildId == 'All Children' ? null : _selectedChildId,
        start: _selectedDateRange.start,
        end: _selectedDateRange.end,
      );
      setState(() {
        _reportData = data;
      });
    } catch (e) {
      debugPrint('Error fetching report: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchReport();
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E8),
      appBar: AppBar(
        backgroundColor: const Color(0xffebdfcc),
        title: Text(
          'Task Completion Report',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading && _reportData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildFilters(),
                    const SizedBox(height: 24),
                    if (_reportData != null && _reportData!.totalTasks > 0) ...[
                      _buildPieChartSection(),
                      const SizedBox(height: 24),
                      _buildDetailedStats(),
                    ] else
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No tasks found for this selection.',
            style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _selectDateRange,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF5A3E36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Range',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDateRange(_selectedDateRange),
                          style: GoogleFonts.quicksand(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.face, size: 20, color: Color(0xFF5A3E36)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedChildId,
                  isExpanded: true,
                  underline: Container(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedChildId = newValue;
                      });
                      _fetchReport();
                    }
                  },
                  items: [
                    DropdownMenuItem<String>(
                      value: 'All Children',
                      child: Text('All Children', style: GoogleFonts.quicksand()),
                    ),
                    ..._children.map<DropdownMenuItem<String>>((child) {
                      return DropdownMenuItem<String>(
                        value: child['id'].toString(),
                        child: Text(child['name'], style: GoogleFonts.quicksand()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Distribution',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A3E36),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: _getSections(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    final data = _reportData!;
    
    return [
      if (data.completed > 0)
        PieChartSectionData(
          color: Colors.green.shade400,
          value: data.completed.toDouble(),
          title: '${data.completionRate.toInt()}%',
          radius: 50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (data.rejected > 0)
        PieChartSectionData(
          color: Colors.red.shade400,
          value: data.rejected.toDouble(),
          title: '${data.rejectionRate.toInt()}%',
          radius: 50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (data.missed > 0)
        PieChartSectionData(
          color: Colors.grey.shade400,
          value: data.missed.toDouble(),
          title: '${data.missedRate.toInt()}%',
          radius: 50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (data.pending > 0)
        PieChartSectionData(
          color: Colors.orange.shade400,
          value: data.pending.toDouble(),
          title: '${data.pendingRate.toInt()}%',
          radius: 50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (data.notDoneYet > 0)
        PieChartSectionData(
          color: Colors.blue.shade400,
          value: data.notDoneYet.toDouble(),
          title: '${data.notDoneRate.toInt()}%',
          radius: 50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: Colors.green.shade400, label: 'Completed'),
        _LegendItem(color: Colors.red.shade400, label: 'Rejected'),
        _LegendItem(color: Colors.grey.shade400, label: 'Missed'),
        _LegendItem(color: Colors.orange.shade400, label: 'Pending'),
        _LegendItem(color: Colors.blue.shade400, label: 'Not Done'),
      ],
    );
  }

  Widget _buildDetailedStats() {
    final data = _reportData!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Total Tasks Assigned', value: '${data.totalTasks}'),
          _SummaryRow(
              label: 'Completion Rate',
              value: '${data.completionRate.toStringAsFixed(1)}%',
              isHighlight: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.quicksand(fontSize: 12)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryRow({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.quicksand(color: Colors.grey.shade700)),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
