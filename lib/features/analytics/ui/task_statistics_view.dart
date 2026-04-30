import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/management/data/manage_repository.dart';
import 'package:happy_family_sim/features/analytics/data/analytics_repository.dart';

class TaskStatisticsScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final ManageRepository manageRepository;
  final AnalyticsRepository analyticsRepository;

  const TaskStatisticsScreen({
    super.key,
    required this.authRepository,
    required this.manageRepository,
    required this.analyticsRepository,
  });

  @override
  State<TaskStatisticsScreen> createState() => _TaskStatisticsScreenState();
}

class _TaskStatisticsScreenState extends State<TaskStatisticsScreen> {
  late DateTimeRange _selectedDateRange;
  String _selectedChildId = 'All Children';
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  DetailedTaskReportData? _statsData;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to this month
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
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
        await _fetchStats();
      }
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStats() async {
    final parentId = widget.authRepository.currentUser?.id;
    if (parentId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await widget.analyticsRepository.getDetailedTaskReport(
        parentId: parentId,
        childId: _selectedChildId == 'All Children' ? null : _selectedChildId,
        start: _selectedDateRange.start,
        end: _selectedDateRange.end,
      );
      setState(() {
        _statsData = data;
      });
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
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
      _fetchStats();
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
          'Task Statistics',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading && _statsData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(),
                    const SizedBox(height: 24),
                    _buildInsightsHeader(),
                    const SizedBox(height: 24),
                    if (_statsData != null && _statsData!.categoryStats.isNotEmpty) ...[
                      _buildCategoryStats(),
                      const SizedBox(height: 24),
                      _buildRewardAdjustmentInsights(),
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
          Icon(Icons.query_stats, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No statistics available for this selection.',
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
                      _fetchStats();
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

  Widget _buildInsightsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'These statistics help you identify which task categories need more motivation or easier goals.',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats() {
    final stats = _statsData!.categoryStats;

    return Container(
      height: 350,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Rate by Category',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A3E36),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${stats[groupIndex].categoryName}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()}%',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              stats[value.toInt()].categoryName,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: stats.asMap().entries.map((e) {
                  return _makeGroupData(e.key, e.value.completionRate, e.value.color);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildRewardAdjustmentInsights() {
    final stats = _statsData!.categoryStats;
    final lowPerformers = stats.where((s) => s.completionRate < 50).toList();
    final highPerformers = stats.where((s) => s.completionRate > 80).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward Adjustment Insights',
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36),
          ),
        ),
        const SizedBox(height: 12),
        if (lowPerformers.isEmpty && highPerformers.isEmpty)
          Text(
            'No significant performance trends detected for this period.',
            style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey),
          ),
        ...lowPerformers.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _InsightCard(
            title: 'Low Completion: ${s.categoryName}',
            description: 'Completion rate is only ${s.completionRate.toInt()}%. Consider increasing the rewards for tasks in this category to encourage participation.',
            icon: Icons.trending_down,
            color: Colors.red.shade50,
            iconColor: Colors.red,
          ),
        )),
        ...highPerformers.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _InsightCard(
            title: 'Steady Performance: ${s.categoryName}',
            description: '${s.completionRate.toInt()}% completion rate. Rewards for these tasks seem well-balanced.',
            icon: Icons.trending_up,
            color: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        )),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
