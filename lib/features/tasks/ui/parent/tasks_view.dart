import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:happy_family_sim/features/management/data/manage_repository.dart';
import 'package:happy_family_sim/features/management/data/manage_service.dart';
import 'package:happy_family_sim/features/tasks/util/custom_recurring_page.dart';
import 'package:happy_family_sim/features/tasks/util/recurring_tools.dart';
import 'package:intl/intl.dart';
import 'package:happy_family_sim/features/tasks/model/task_occurence.dart';
import 'package:happy_family_sim/features/tasks/data/task_repository.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentTasksScreen extends StatefulWidget {
  final AuthRepository authRepository;
  const ParentTasksScreen({super.key, required this.authRepository});

  @override
  State<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends State<ParentTasksScreen> {
  final TaskRepository _taskRepository = TaskRepository();

  // future as state to enable
  // late Future<List<TaskOccurrence>> _tasksFuture;
  List<TaskOccurrence> _tasks = [];
  bool _isLoadingTasks = true;

  List<Map<String, dynamic>> _availableChildren = [];
  bool _isLoadingChildren = true;

  bool _isSelectionMode = false;
  Set<int> _selectedTaskIds = {};

  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
    _loadChildren();
  }

  Future<void> _refreshTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final userId = widget.authRepository.currentUser?.id;
      // 2. Fetch data and store it directly in our new list
      final data = await _taskRepository.fetchChildTasks(userId ?? '');
      setState(() {
        _tasks = data;
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() => _isLoadingTasks = false);
    }
  }
  // late List<TaskOccurrence> _tasks;
  // @override
  // void initState() {
  //   super.initState();
  //   _tasks = [
  //     TaskOccurrence(
  //       id: 1,
  //       templateId: 101,
  //       dueDate: DateTime.now().add(const Duration(days: 1)),
  //       status: 'NOTD',
  //       template: TaskTemplate(
  //         id: 101,
  //         title: "Clean Bedroom",
  //         description: "Pick up toys, vacuum the rug, and make the bed.",
  //         proofRequired: true,
  //         startDate: DateTime.now(),
  //         endDate: DateTime.now().add(const Duration(days: 7)),
  //       ),
  //     ),
  //     TaskOccurrence(
  //       id: 2,
  //       templateId: 102,
  //       dueDate: DateTime.now().subtract(const Duration(hours: 2)),
  //       status: 'COMP',
  //       template: TaskTemplate(
  //         id: 102,
  //         title: "Brush Teeth",
  //         description: "Brush for 2 minutes and use mouthwash.",
  //         proofRequired: false,
  //         startDate: DateTime.now(),
  //         endDate: DateTime.now().add(const Duration(days: 30)),
  //       ),
  //     ),
  //   ];
  // }

  Future<void> _loadChildren() async {
    final supabase = Supabase.instance.client;
    final manageService = ManageService(supabase);
    final manageRepository = ManageRepository(manageService);
    setState(() {
      _isLoadingChildren = true;
      _hasError = false; // Reset error state on retry
    });

    try {
      final userId = widget.authRepository.currentUser?.id;
      final data = await manageRepository.fetchChildrenData(userId ?? '');
      setState(() {
        _availableChildren = data;
        _isLoadingChildren = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingChildren = false;
        _hasError = true;
      });

      // Show an actionable error message
      if (mounted) {
        // Ensure the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load children list'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'Retry', onPressed: _loadChildren),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E8),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xffebdfcc),
        title: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _isSelectionMode ? "${_selectedTaskIds.length} Selected" : "Tasks",
            style: GoogleFonts.quicksand(
                // fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5A3E36), //soft dark brown
              ),
          ),
        ),
        actions: [
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: () => setState(() => _isSelectionMode = true),
              ),
            ),

          if (_isSelectionMode) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, color: colorScheme.error),
                    onPressed: _handleBulkDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedTaskIds.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 1,
      ),
      body: _isLoadingTasks
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text("No tasks found."))
          : RefreshIndicator(
              onRefresh: _refreshTasks,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final occurrence = _tasks[index];
                  // Safely access the template
                  final template = occurrence.template;
                  final isDone = occurrence.status == 'COMP';
                  final isSelected = _selectedTaskIds.contains(occurrence.id);

                  return Opacity(
                    opacity: isDone ? 0.6 : 1.0,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      color: isSelected
                          ? colorScheme
                                .primaryContainer // Highlight selected
                          : (isDone
                                ? colorScheme.surfaceContainerHigh
                                : colorScheme.surface),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        // side: BorderSide(color: isDone ? colorScheme.outlineVariant.withAlpha(125): colorScheme.outlineVariant, width: 0.7),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary.withAlpha(100)
                              : (isDone
                                    ? Colors.transparent
                                    : colorScheme.primary.withAlpha(50)),

                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(occurrence.id);
                          } else {
                            _showTaskForm(occurrence: occurrence);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // 0. Delection Checkbox (only in selection mode)
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                    size: 20,
                                  ),
                                ),
                              // 1. Left aligned: indicator
                              Stack(
                                children: [
                                  _buildChildIndicator(
                                    occurrence
                                        .childAvatar, // Using the URL we generated earlier
                                    colorScheme,
                                  ),
                                  if (isDone)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 10,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // 2. Left aligned: Task Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template!.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isDone
                                                ? colorScheme.outline
                                                : colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          occurrence.childName,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color: colorScheme.secondary,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons
                                              .stars_rounded, // Visual cue for "Reward"
                                          size: 14,
                                          color: Colors
                                              .orangeAccent, // Or use colorScheme.tertiary
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${template.resourceAmount} ${template.resource}",
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 3. Right aligned: Due Date + Chevron
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildDueChip(
                                    occurrence.dueDate,
                                    colorScheme,
                                    isDone,
                                  ),
                                  if (!_isSelectionMode) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: colorScheme.outline,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        label: const Text("New Task"),
        icon: const Icon(Icons.add_task),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  // --- Helper UI Components ---
  Widget _buildChildIndicator(String avatarUrl, ColorScheme colorScheme) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.surfaceDim,
      backgroundImage: NetworkImage(avatarUrl),
      // default icon
      // final bool isDone = status == 'DONE';
      // return Container(
      //   width: 48,
      //   height: 48,
      //   decoration: BoxDecoration(
      //     shape: BoxShape.circle,
      //     color: colorScheme.surfaceDim,
      //     // color: isDone ? colorScheme.surfaceDim : colorScheme.surfaceDim,
      //     // border: Border.all(
      //     //   color: isDone ? colorScheme.primary : colorScheme.outlineVariant,
      //     //   width: 2,
      //     // ),
      //   ),
      //   child: Icon(
      //     Icons.person,
      //     // isDone ? Icons.check : Icons.person,
      //     color: colorScheme.primary,
      //   ),
    );
  }

  Widget _buildDueChip(DateTime date, ColorScheme colors, bool isDone) {
    final color = isDone ? colors.outline : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(
          0x1A,
        ), // 0.1 opacity in alpha channel (0x1A = 26 out of 255)
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('MMM d').format(date), // Use intl package
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Edit Logistics: Bottom Sheet ---
  void _showTaskForm({TaskOccurrence? occurrence}) {
    final bool isEditing = occurrence != null;

    // 1. Initialize Controllers and State
    final titleController = TextEditingController(
      text: isEditing ? occurrence.template?.title : "",
    );
    final descController = TextEditingController(
      text: isEditing ? occurrence.template?.description : "",
    );
    DateTime selectedDate = isEditing
        ? occurrence.dueDate
        : DateTime.now().add(const Duration(hours: 1));
    String currentStatus = isEditing ? occurrence.status : 'NOTD';
    bool proofRequired = isEditing
        ? (occurrence.template?.proofRequired ?? false)
        : false;
    String? selectedChildId = isEditing ? occurrence.childId : null;

    String? selectedResource = isEditing
        ? occurrence.template?.resource
        : 'Food';
    int resourceAmount = isEditing
        ? (occurrence.template?.resourceAmount ?? 1)
        : 1;
    final resourceAmountController = TextEditingController(
      text: isEditing
          ? (occurrence.template?.resourceAmount ?? 1).toString()
          : '1',
    );

    String _repeatOption = "Never";
    DateTime? _endDate = isEditing ? occurrence.template?.endDate : null;
    Map<String, dynamic>? _customRecurrence;
    bool _isSaving = false;

    // 2. Pre-populate Recurrence Info (UI Dropdown mapping)
    if (isEditing && occurrence.template?.recurrence != null) {
      final rec = occurrence.template!.recurrence!;
      final pattern = rec.pattern.toLowerCase();

      if (rec.interval == 1 &&
          rec.dayOfWeek == null &&
          rec.dayOfMonth == null) {
        if (pattern == 'daily')
          _repeatOption = 'Daily';
        else if (pattern == 'weekly')
          _repeatOption = 'Weekly';
        else if (pattern == 'monthly')
          _repeatOption = 'Monthly';
        else
          _repeatOption = 'Custom';
      } else {
        _repeatOption = 'Custom';
      }

      if (_repeatOption == 'Custom') {
        _customRecurrence = {
          'pattern': pattern,
          'interval': rec.interval,
          'selectedDays': pattern == 'weekly'
              ? (rec.dayOfWeek ?? [])
              : (pattern == 'monthly' ? (rec.dayOfMonth ?? []) : []),
        };
      }
    }

    ThemeData theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // --- FIX: Prevent accidental exit via swipe or tapping outside ---
      enableDrag: false,
      isDismissible: false,
      // -----------------------------------------------------------------
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header / Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? "Edit Task" : "New Task",
                        style: theme.textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      MediaQuery.of(context).viewInsets.bottom + 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Task Title
                        TextField(
                          controller: titleController,
                          onChanged: (value) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: "Task Title",
                            errorText: titleController.text.isEmpty
                                ? "Title is required"
                                : null,
                            prefixIcon: const Icon(Icons.title),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Task Description
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            prefixIcon: Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 3. Due Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time),
                          title: const Text("Due Date & Time"),
                          subtitle: Text(
                            DateFormat(
                              'EEEE, MMM d, h:mm a',
                            ).format(selectedDate),
                          ),
                          trailing: IconButton.filledTonal(
                            onPressed: () async {
                              final result = await _showCustomDateTimePicker(
                                context,
                                selectedDate,
                                true,
                              );
                              if (result != null)
                                setSheetState(() => selectedDate = result);
                            },
                            icon: const Icon(Icons.edit_calendar),
                          ),
                        ),

                        // 4. Assignee (Child) Selector
                        Text("Assignee", style: theme.textTheme.labelLarge),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableChildren.length,
                            itemBuilder: (context, index) {
                              final child = _availableChildren[index];
                              final bool isSelected =
                                  selectedChildId == child['id'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: GestureDetector(
                                  onTap: () => setSheetState(
                                    () => selectedChildId = child['id'],
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outlineVariant,
                                        child: CircleAvatar(
                                          radius: 27,
                                          backgroundImage:
                                              child['avatar_url'] != null
                                              ? NetworkImage(
                                                  child['avatar_url'],
                                                )
                                              : null,
                                          child: child['avatar_url'] == null
                                              ? Text(
                                                  child['name'][0]
                                                      .toUpperCase(),
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        child['name'],
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // 5. Status (Only in Edit)
                        if (isEditing) ...[
                          const SizedBox(height: 16),
                          Text(
                            "Task Status",
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'NOTD',
                                label: Text('Pending'),
                                icon: Icon(Icons.hourglass_empty),
                              ),
                              ButtonSegment(
                                value: 'COMP',
                                label: Text('Completed'),
                                icon: Icon(Icons.check_circle_outline),
                              ),
                            ],
                            selected: {currentStatus},
                            onSelectionChanged: (newVal) => setSheetState(
                              () => currentStatus = newVal.first,
                            ),
                          ),
                        ],

                        // 6. Proof Required
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Proof Required"),
                          value: proofRequired,
                          onChanged: (val) =>
                              setSheetState(() => proofRequired = val),
                        ),
                        // 6b. Resource Type
                        const SizedBox(height: 8),
                        Text("Resource", style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        SegmentedButton<String?>(
                          segments: const [
                            ButtonSegment(
                              value: 'food',
                              label: Text('Food'),
                              icon: Icon(Icons.fastfood),
                            ),
                            ButtonSegment(
                              value: 'play',
                              label: Text('Play'),
                              icon: Icon(Icons.sports_esports),
                            ),
                            ButtonSegment(
                              value: 'clean',
                              label: Text('Clean'),
                              icon: Icon(Icons.cleaning_services),
                            ),
                          ],
                          selected: {selectedResource},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (val) => setSheetState(() {
                            selectedResource = val.isEmpty ? null : val.first;
                          }),
                        ),

                        // 6c. Resource Amount (only shown when a resource is selected)
                        if (selectedResource != null) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: resourceAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Resource Amount",
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null)
                                setSheetState(() => resourceAmount = parsed);
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        // 7. Recurring Section
                        Text("Repeated", style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _repeatOption,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.repeat),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              ['Never', 'Daily', 'Weekly', 'Monthly', 'Custom']
                                  .map(
                                    (val) => DropdownMenuItem(
                                      value: val,
                                      child: Text(val),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) async {
                            if (val == 'Custom') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CustomRecurrencePage(),
                                ),
                              );
                              if (result != null) {
                                setSheetState(() {
                                  _customRecurrence = result;
                                  _repeatOption = 'Custom';
                                });
                              } else {
                                setSheetState(() => _repeatOption = 'Never');
                              }
                            } else {
                              setSheetState(() {
                                _repeatOption = val!;
                                _customRecurrence = null;
                              });
                            }
                          },
                        ),

                        if (_repeatOption != 'Never') ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              _repeatOption == 'Custom'
                                  ? TaskUtils.getCustomSummary(
                                      _customRecurrence,
                                    )
                                  : "Repeats $_repeatOption",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: const Text("End Repeat On"),
                            subtitle: Text(
                              _endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                  : "Not set",
                            ),
                            trailing: IconButton.filledTonal(
                              onPressed: () async {
                                final picked = await _showCustomDateTimePicker(
                                  context,
                                  _endDate ?? DateTime.now(),
                                  false,
                                );
                                if (picked != null)
                                  setSheetState(() => _endDate = picked);
                              },
                              icon: const Icon(Icons.edit_calendar),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // 8. COMBINED SAVE LOGIC
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (titleController.text.trim().isEmpty)
                                      return;
                                    if (selectedChildId == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please select an assignee",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final TaskRepository repository =
                                        TaskRepository();
                                    try {
                                      if (isEditing) {
                                        if (isEditing) {
                                          // --- 1. DETECTION LOGIC ---
                                          bool dateChanged =
                                              occurrence.dueDate.year !=
                                                  selectedDate.year ||
                                              occurrence.dueDate.month !=
                                                  selectedDate.month ||
                                              occurrence.dueDate.day !=
                                                  selectedDate.day;

                                          bool timeChanged =
                                              occurrence.dueDate.hour !=
                                                  selectedDate.hour ||
                                              occurrence.dueDate.minute !=
                                                  selectedDate.minute;

                                          String newPattern =
                                              _repeatOption == 'Custom'
                                              ? _customRecurrence!['pattern']
                                              : _repeatOption.toLowerCase();

                                          String oldPattern =
                                              occurrence
                                                  .template
                                                  ?.recurrence
                                                  ?.pattern
                                                  .toLowerCase() ??
                                              'never';
                                          bool patternChanged =
                                              newPattern != oldPattern;
                                          if (!patternChanged &&
                                              occurrence
                                                      .template
                                                      ?.recurrence
                                                      ?.interval !=
                                                  null) {
                                            int oldInterval = occurrence
                                                .template!
                                                .recurrence!
                                                .interval;
                                            int newInterval =
                                                _repeatOption == 'Custom'
                                                ? _customRecurrence!['interval']
                                                : 1;
                                            patternChanged =
                                                oldInterval != newInterval;
                                            if (!patternChanged && newPattern == 'weekly') {
                                              List<int> oldDays =
                                                  occurrence
                                                      .template!
                                                      .recurrence!
                                                      .dayOfWeek ??
                                                  [];
                                              List<int> newDays =
                                                  List<int>.from(
                                                    _customRecurrence![
                                                        'selectedDays'],
                                                  );
                                              oldDays.sort();
                                              newDays.sort();
                                              patternChanged =
                                                  !listEquals(oldDays, newDays);
                                            } else if (!patternChanged &&
                                                newPattern == 'monthly') {
                                              List<int> oldDays =
                                                  occurrence
                                                      .template!
                                                      .recurrence!
                                                      .dayOfMonth ??
                                                  [];
                                              List<int> newDays =
                                                  List<int>.from(
                                                    _customRecurrence![
                                                        'selectedDays'],
                                                  );
                                              oldDays.sort();
                                              newDays.sort();
                                              patternChanged =
                                                  !listEquals(oldDays, newDays);
                                            }
                                          }

                                          _endDate = _endDate?.copyWith(
                                            hour: 23,
                                            minute: 59,
                                            second: 00,
                                          );
                                          bool endDateChanged =
                                              occurrence.template?.endDate !=
                                              _endDate;

                                          bool needsForcedSeriesUpdate =
                                              dateChanged ||
                                              patternChanged ||
                                              endDateChanged;
                                          bool isCurrentlyRecurring =
                                              occurrence
                                                  .template
                                                  ?.recurrenceId !=
                                              null;
                                          bool isNowRecurring =
                                              _repeatOption != "Never";

                                          bool basicInfoChanged =
                                              titleController.text !=
                                                  occurrence.template?.title ||
                                              descController.text !=
                                                  occurrence
                                                      .template
                                                      ?.description ||
                                              proofRequired !=
                                                  occurrence
                                                      .template
                                                      ?.proofRequired ||
                                              selectedChildId !=
                                                  occurrence.childId||
                                              selectedResource !=
                                                  occurrence
                                                      .template!.resource||
                                              resourceAmount !=
                                                  (occurrence
                                                          .template
                                                          !.resourceAmount ?? 1);

                                          String? scope;
                                          String? updateScope;

                                          // --- 2. DIALOG LOGIC ---
                                          if (isCurrentlyRecurring ||
                                              isNowRecurring) {
                                            if (needsForcedSeriesUpdate) {
                                              // Prompt 1: Structural change (Warns about resetting future tasks)
                                              final proceed =
                                                  await _showForcedUpdateDialog(
                                                    context,
                                                  );
                                              if (!proceed) return;
                                              scope = 'future';
                                              updateScope =
                                                  'rewrite'; // Nuke and Pave
                                              if (endDateChanged)
                                                updateScope =
                                                    'alter'; // Just update end date, keep pattern
                                            } else if (timeChanged) {
                                              // Prompt 2: Time change (Ask "This task" vs "All future")
                                              scope =
                                                  await _showEditScopeDialog(
                                                    context,
                                                  );
                                              if (scope == null ||
                                                  scope == 'cancel')
                                                return;
                                              if (scope == 'future')
                                                updateScope =
                                                    'alter'; // Just update template time
                                            } else if (basicInfoChanged) {
                                              // Prompt 3: Just text/assignee changes (Quietly apply to series)
                                              final proceed =
                                                  await _showForcedUpdateDialog(
                                                    context,
                                                  );
                                              if (!proceed) return;
                                              scope = 'future';
                                              updateScope = 'alter';
                                            } else {
                                              // Only status changed
                                              scope = 'single';
                                            }
                                          }

                                          setSheetState(() => _isSaving = true);

                                          // --- 3. EXECUTION LOGIC ---
                                          if (scope == 'future') {
                                            int interval =
                                                _repeatOption == 'Custom'
                                                ? _customRecurrence!['interval']
                                                : 1;
                                            List<int>? dayOfWeek;
                                            List<int>? dayOfMonth;

                                            if (_repeatOption == 'Custom') {
                                              if (newPattern == 'weekly')
                                                dayOfWeek = List<int>.from(
                                                  _customRecurrence!['selectedDays'],
                                                );
                                              if (newPattern == 'monthly')
                                                dayOfMonth = List<int>.from(
                                                  _customRecurrence!['selectedDays'],
                                                );
                                            } else if (_repeatOption !=
                                                'Never') {
                                              if (newPattern == 'weekly')
                                                dayOfWeek = [
                                                  selectedDate.weekday,
                                                ];
                                              if (newPattern == 'monthly')
                                                dayOfMonth = [selectedDate.day];
                                            }

                                            await repository.updateRecurringSeries(
                                              templateId: occurrence.templateId,
                                              recurrenceId: occurrence
                                                  .template!
                                                  .recurrenceId,
                                              title: titleController.text,
                                              description: descController.text,
                                              proofRequired: proofRequired,
                                              resource:
                                                  selectedResource ?? 'food',
                                              resourceAmount: resourceAmount,
                                              childId: selectedChildId!,
                                              startDate:
                                                  selectedDate, // New anchor date
                                              pattern: newPattern,
                                              interval: interval,
                                              dayOfWeek: dayOfWeek,
                                              dayOfMonth: dayOfMonth,
                                              endDate: _endDate,
                                              updateScope:
                                                  updateScope ?? 'alter',
                                              oldDueDate: occurrence.dueDate,
                                            );
                                            await _refreshTasks();
                                          } else {
                                            // --- SINGLE TASK UPDATE ---
                                            await Future.wait([
                                              repository.updateTemplate(
                                                templateId:
                                                    occurrence.templateId,
                                                title: titleController.text,
                                                description:
                                                    descController.text,
                                                proofRequired: proofRequired,
                                                resource:
                                                    selectedResource ?? 'food',
                                                resourceAmount: resourceAmount,
                                              ),
                                              repository.updateOccurrence(
                                                occurrenceId: occurrence.id,
                                                dueDate: selectedDate,
                                                status: currentStatus,
                                                childId: selectedChildId!,
                                              ),
                                            ]);

                                            int index = _tasks.indexWhere(
                                              (t) => t.id == occurrence.id,
                                            );
                                            if (index != -1) {
                                              setState(() {
                                                _tasks[index] = _tasks[index]
                                                    .copyWith(
                                                      dueDate: selectedDate,
                                                      status: currentStatus,
                                                      childId: selectedChildId,
                                                      childName: _availableChildren
                                                          .firstWhere(
                                                            (c) =>
                                                                c['id'] ==
                                                                selectedChildId,
                                                            orElse: () => {
                                                              'name': 'Unknown',
                                                            },
                                                          )['name'],
                                                      template: _tasks[index]
                                                          .template!
                                                          .copyWith(
                                                            title:
                                                                titleController
                                                                    .text,
                                                            description:
                                                                descController
                                                                    .text,
                                                            proofRequired:
                                                                proofRequired,
                                                            resource:
                                                                selectedResource ?? 'food',
                                                            resourceAmount:
                                                                resourceAmount,
                                                          ),
                                                    );
                                              });
                                            }
                                          }
                                        }
                                      } else {
                                        // New Task Logic
                                        setSheetState(() => _isSaving = true);
                                        if (_repeatOption == "Never") {
                                          final newTemplate = await repository
                                              .createTemplate(
                                                title: titleController.text,
                                                description:
                                                    descController.text,
                                                proofRequired: proofRequired,
                                                resource: selectedResource ?? 'food',
                                                resourceAmount: resourceAmount,
                                              );
                                          final newTask = await repository
                                              .createOccurrence(
                                                childId: selectedChildId!,
                                                dueDate: selectedDate,
                                                status: 'NOTD',
                                                templateId: newTemplate.id,
                                              );
                                          setState(
                                            () => _tasks.insert(0, newTask),
                                          );
                                        } else {
                                          String pattern =
                                              _repeatOption == 'Custom'
                                              ? _customRecurrence!['pattern']
                                              : _repeatOption.toLowerCase();
                                          int interval =
                                              _repeatOption == 'Custom'
                                              ? _customRecurrence!['interval']
                                              : 1;
                                          List<int>? dayOfWeek;
                                          List<int>? dayOfMonth;
                                          if (_repeatOption == 'Custom') {
                                            if (pattern == 'weekly')
                                              dayOfWeek = List<int>.from(
                                                _customRecurrence!['selectedDays'],
                                              );
                                            if (pattern == 'monthly')
                                              dayOfMonth = List<int>.from(
                                                _customRecurrence!['selectedDays'],
                                              );
                                          } else {
                                            if (pattern == 'weekly')
                                              dayOfWeek = [
                                                selectedDate.weekday,
                                              ];
                                            if (pattern == 'monthly')
                                              dayOfMonth = [selectedDate.day];
                                          }
                                          await repository.saveRecurringTask(
                                            title: titleController.text,
                                            description: descController.text,
                                            proofRequired: proofRequired,
                                            resource:
                                                selectedResource ?? 'food',
                                            resourceAmount: resourceAmount,
                                            childId: selectedChildId!,
                                            dueDate: selectedDate,
                                            endDate: _endDate,
                                            pattern: pattern,
                                            interval: interval,
                                            dayOfWeek: dayOfWeek,
                                            dayOfMonth: dayOfMonth,
                                          );
                                          await _refreshTasks();
                                        }
                                      }
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    } catch (e) {
                                      if (context.mounted) {
                                        setSheetState(() => _isSaving = false);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditing ? "Save Changes" : "Create Task",
                                  ),
                          ),
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

  String _getRecurrenceSummary(String option, Map<String, dynamic>? custom) {
    if (option != "Custom") return "Repeats $option";

    final pattern = custom?['pattern'] ?? 'daily';
    final interval = custom?['interval'] ?? 1;
    final days = custom?['selectedDays'] as List<int>?;

    String unit = pattern == 'daily'
        ? 'day'
        : pattern == 'weekly'
        ? 'week'
        : 'month';
    String plural = interval > 1 ? 's' : '';

    String summary = "Every $interval $unit$plural";
    if (days != null && days.isNotEmpty) {
      summary += " on ${days.join(', ')}";
    }
    return summary;
  }

  Future<DateTime?> _showCustomDateTimePicker(
    BuildContext context,
    DateTime initialDate,
    bool showTime,
  ) async {
    final theme = Theme.of(context);
    String? dialogError;
    // These variables hold the "in-progress" selection
    DateTime tempDate = initialDate;
    DateTime tempTime = initialDate;

    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: const Color.fromARGB(
        86,
        0,
        0,
        0,
      ), // Dims the background gradually
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        // This creates the gradual "Fade In" effect
        return FadeTransition(
          opacity: anim1,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                content: SizedBox(
                  width: 330,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      // 1. Calendar
                      SizedBox(
                        height: 320,
                        child: CalendarDatePicker(
                          // We use a Key here to force the widget to recreate
                          // and jump to the new month if the chip date is far away
                          key: ValueKey(tempDate),
                          initialDate: tempDate,
                          firstDate: tempDate.isBefore(DateTime.now())
                              ? tempDate
                              : DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          onDateChanged: (date) {
                            setDialogState(() => tempDate = date);
                          },
                        ),
                      ),
                      // 2. Quick Select Chips
                      if (showTime) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 18,
                            left: 12,
                            right: 12,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickChip("Tmr", 1, (newDate) {
                                  // This tells the Dialog to refresh the Calendar highlight
                                  setDialogState(() => tempDate = newDate);
                                }),
                                const SizedBox(width: 8),
                                _buildQuickChip("+3 Days", 3, (newDate) {
                                  setDialogState(() => tempDate = newDate);
                                }),
                                const SizedBox(width: 8),
                                _buildQuickChip("Next Week", 7, (newDate) {
                                  setDialogState(() => tempDate = newDate);
                                }),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),

                        // 3. Time Picker\
                        SizedBox(
                          height: 120,
                          child: CupertinoTheme(
                            data: CupertinoThemeData(
                              textTheme: CupertinoTextThemeData(
                                dateTimePickerTextStyle: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              initialDateTime: tempTime,
                              onDateTimeChanged: (time) {
                                // Time changes don't need to rebuild the calendar,
                                // but we save it to tempTime
                                tempTime = time;
                              },
                            ),
                          ),
                        ),
                      ],
                      // 4. Error Message (e.g. for past date selection)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          dialogError ?? "",
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // 1. The Clear Button
                  if (!showTime)
                    TextButton(
                      onPressed: () {
                        // Return null to signify the date has been cleared
                        Navigator.pop(context, null);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.error, // Subtle warning color
                      ),
                      child: const Text("Clear"),
                    ),
                  const Spacer(), // Pushes OK and Cancel to the right
                  // 2. The Cancel Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),

                  // 3. The OK Button
                  FilledButton.tonal(
                    onPressed: () {
                      final finalResult = DateTime(
                        tempDate.year,
                        tempDate.month,
                        tempDate.day,
                        tempTime.hour,
                        tempTime.minute,
                      );

                      if (finalResult.isBefore(DateTime.now())) {
                        setDialogState(() {
                          dialogError = "Please select a future date and time";
                        });
                        return;
                      }
                      Navigator.pop(context, finalResult);
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _showEditScopeDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Recurring Task"),
          content: const Text(
            "You changed the details of a repeating task. How would you like to save these changes?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'single'),
              child: const Text("This task only"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'future'),
              child: const Text("This and all future"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickChip(
    String label,
    int daysToAdd,
    Function(DateTime) onSelected,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final now = DateTime.now();
        final futureDate = DateTime(now.year, now.month, now.day + daysToAdd);
        onSelected(futureDate);
      },
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
        // Optional: Exit selection mode if last item is unselected
        if (_selectedTaskIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  Future<void> _handleBulkDelete() async {
    if (_selectedTaskIds.isEmpty) return;
    final TaskRepository taskRepository = TaskRepository();

    bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    try {
      // Collect template IDs for the selected occurrences
      final templateIds = _tasks
          .where((t) => _selectedTaskIds.contains(t.id))
          .map((t) => t.templateId)
          .toList();

      await taskRepository.deleteTasksBulk(
        _selectedTaskIds.toList(),
        templateIds,
      );

      setState(() {
        _tasks.removeWhere((t) => _selectedTaskIds.contains(t.id));
        _selectedTaskIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (!mounted) return; // Guard against async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete tasks: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _handleBulkDelete, // Allow user to try again
          ),
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Task?"),
            content: const Text(
              "This will permanently remove this task and all its data.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showForcedUpdateDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Update Series"),
            content: const Text(
              "Changing the date or repeat pattern will reset all upcoming occurrences in this series. Do you want to apply this to all future tasks?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Update All"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
