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

  List<TaskOccurrence> _tasks = [];
  bool _isLoadingTasks = true;

  List<Map<String, dynamic>> _availableChildren = [];

  bool _isSelectionMode = false;
  Set<int> _selectedTaskIds = {};
  
  final List<Map<String, dynamic>> _presetTasks = [
    {
      'title': 'Clean Bedroom',
      'description': 'Pick up toys, vacuum the rug, and make the bed.',
      'resource': 'clean',
      'amount': 2,
    },
    {
      'title': 'Brush Teeth',
      'description': 'Brush for 2 minutes and use mouthwash.',
      'resource': 'food',
      'amount': 1,
    },
    {
      'title': 'Do Homework',
      'description': 'Complete all assignments for tomorrow.',
      'resource': 'play',
      'amount': 3,
    },
  ];

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
      final data = await _taskRepository.fetchChildTasks(userId ?? '');
      setState(() {
        _tasks = data;
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _loadChildren() async {
    final supabase = Supabase.instance.client;
    final manageService = ManageService(supabase);
    final manageRepository = ManageRepository(manageService);

    try {
      final userId = widget.authRepository.currentUser?.id;
      final data = await manageRepository.fetchChildrenData(userId ?? '');
      setState(() => _availableChildren = data);
    } catch (e) {
      if (mounted) {
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
      appBar: _buildAppBar(colorScheme),
      body: _buildBody(),
      floatingActionButton: _buildNewTaskButton(colorScheme),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      centerTitle: true,
      backgroundColor: const Color(0xffebdfcc),
      title: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _isSelectionMode ? "${_selectedTaskIds.length} Selected" : "Tasks",
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5A3E36),
          ),
        ),
      ),
      actions: _buildAppBarActions(colorScheme),
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 1,
    );
  }

  List<Widget> _buildAppBarActions(ColorScheme colorScheme) {
    if (!_isSelectionMode) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => setState(() => _isSelectionMode = true),
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.delete, color: colorScheme.error),
              onPressed: _handleBulkDelete,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildBody() {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return const Center(child: Text("No tasks found."));
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _tasks.length,
        itemBuilder: (context, index) => _TaskCard(
          occurrence: _tasks[index],
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedTaskIds.contains(_tasks[index].id),
          onTap: () => _handleTaskTap(_tasks[index]),
        ),
      ),
    );
  }

  Widget _buildNewTaskButton(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () => _showTaskForm(),
      label: const Text("New Task"),
      icon: const Icon(Icons.add_task),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    );
  }

  void _handleTaskTap(TaskOccurrence occurrence) {
    if (_isSelectionMode) {
      _toggleSelection(occurrence.id);
      return;
    }

    _showTaskForm(occurrence: occurrence);
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
    });
  }

  void _showPresetPicker(BuildContext context, Function(Map<String, dynamic>) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Choose a Preset Task", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _presetTasks.length,
                itemBuilder: (context, index) {
                  final preset = _presetTasks[index];
                  return ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(preset['title']),
                    subtitle: Text(preset['description'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      onSelected(preset);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Edit Logistics: Bottom Sheet ---
  void _showTaskForm({TaskOccurrence? occurrence}) {
    final bool isEditing = occurrence != null;

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
    final List<String> selectedChildIds = isEditing ? [occurrence.childId] : [];

    String? selectedResource = isEditing
        ? occurrence.template?.resource
        : 'food';
    int resourceAmount = isEditing
        ? (occurrence.template?.resourceAmount ?? 1)
        : 1;
    final resourceAmountController = TextEditingController(
      text: isEditing
          ? (occurrence.template?.resourceAmount ?? 1).toString()
          : '1',
    );

    String repeatOption = "Never";
    DateTime? endDate = isEditing ? occurrence.template?.endDate : null;
    Map<String, dynamic>? customRecurrence;
    bool isSaving = false;

    if (isEditing && occurrence.template?.recurrence != null) {
      final rec = occurrence.template!.recurrence!;
      final pattern = _normalizeRecurrencePattern(rec.pattern);
      final hasCustomRule =
          rec.interval != 1 ||
          (rec.dayOfWeek != null && rec.dayOfWeek!.isNotEmpty) ||
          (rec.dayOfMonth != null && rec.dayOfMonth!.isNotEmpty);

      if (hasCustomRule) {
        repeatOption = 'Custom';
        customRecurrence = {
          'pattern': pattern,
          'interval': rec.interval,
          'selectedDays': pattern == 'Weekly'
              ? (rec.dayOfWeek ?? [])
              : (pattern == 'Monthly' ? (rec.dayOfMonth ?? []) : []),
        };
      } else {
        repeatOption = pattern;
      }
    }

    ThemeData theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // TODO: consider allowing drag to dismiss when not editing existing task
      enableDrag: false,
      isDismissible: false,

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
                        onPressed: isSaving
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
                        if (!isEditing) // Only show presets for new tasks
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: OutlinedButton.icon(
                              onPressed: () => _showPresetPicker(context, (preset) {
                                setSheetState(() {
                                  titleController.text = preset['title'];
                                  descController.text = preset['description'];
                                  selectedResource = preset['resource'];
                                  resourceAmount = preset['amount'];
                                  resourceAmountController.text = preset['amount'].toString();
                                });
                              }),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text("Use a Preset Task"),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? "Assignee" : "Assignees",
                              style: theme.textTheme.labelLarge,
                            ),
                            if (!isEditing)
                              Text(
                                "assign to multiple at once",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableChildren.length,
                            itemBuilder: (context, index) {
                              // ... rest of your existing ListView code ...
                              final child = _availableChildren[index];
                              final childId = child['id'].toString();
                              final bool isSelected = isEditing
                                  ? selectedChildId == childId
                                  : selectedChildIds.contains(childId);

                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: GestureDetector(
                                  onTap: () => setSheetState(() {
                                    if (isEditing) {
                                      selectedChildId = childId;
                                      return;
                                    }

                                    if (selectedChildIds.contains(childId)) {
                                      selectedChildIds.remove(childId);
                                    } else {
                                      selectedChildIds.add(childId);
                                    }
                                  }),
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
                                      SizedBox(
                                        width: 72,
                                        child: Text(
                                          child['name'],
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
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
                          selected: selectedResource == null
                              ? <String?>{}
                              : {selectedResource},
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
                          initialValue: repeatOption,
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
                                  customRecurrence = result;
                                  repeatOption = 'Custom';
                                });
                              } else {
                                setSheetState(() => repeatOption = 'Never');
                              }
                            } else {
                              setSheetState(() {
                                repeatOption = val!;
                                customRecurrence = null;
                              });
                            }
                          },
                        ),

                        if (repeatOption != 'Never') ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              repeatOption == 'Custom'
                                  ? TaskUtils.getCustomSummary(customRecurrence)
                                  : "Repeats $repeatOption",
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
                              endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(endDate!)
                                  : "Not set",
                            ),
                            trailing: IconButton.filledTonal(
                              onPressed: () async {
                                final picked = await _showCustomDateTimePicker(
                                  context,
                                  endDate ?? DateTime.now(),
                                  false,
                                );
                                if (picked != null)
                                  setSheetState(() => endDate = picked);
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
                            onPressed: isSaving
                                ? null
                                : () async {
                                    try {
                                      final didSave = await _submitTaskForm(
                                        context: context,
                                        occurrence: occurrence,
                                        title: titleController.text,
                                        description: descController.text,
                                        selectedDate: selectedDate,
                                        currentStatus: currentStatus,
                                        proofRequired: proofRequired,
                                        selectedChildId: selectedChildId,
                                        selectedChildIds: selectedChildIds,
                                        selectedResource: selectedResource,
                                        resourceAmount: resourceAmount,
                                        repeatOption: repeatOption,
                                        customRecurrence: customRecurrence,
                                        endDate: endDate,
                                        onSavingStarted: () => setSheetState(
                                          () => isSaving = true,
                                        ),
                                      );

                                      if (didSave && context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setSheetState(() => isSaving = false);
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
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditing
                                        ? "Save Changes"
                                        : selectedChildIds.length > 1
                                        ? "Create ${selectedChildIds.length} Tasks"
                                        : "Create Task",
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


  Future<bool> _submitTaskForm({
    required BuildContext context,
    required TaskOccurrence? occurrence,
    required String title,
    required String description,
    required DateTime selectedDate,
    required String currentStatus,
    required bool proofRequired,
    required String? selectedChildId,
    required List<String> selectedChildIds,
    required String? selectedResource,
    required int resourceAmount,
    required String repeatOption,
    required Map<String, dynamic>? customRecurrence,
    required DateTime? endDate,
    required VoidCallback onSavingStarted,
  }) async {
    if (!_validateTaskForm(
      context,
      title,
      occurrence == null ? selectedChildIds : [selectedChildId ?? ''],
    )) {
      return false;
    }

    final recurrence = _recurrenceFromForm(
      repeatOption: repeatOption,
      customRecurrence: customRecurrence,
      selectedDate: selectedDate,
    );

    // Check if we are creating a new task or updating an existing one
    if (occurrence == null) {
      onSavingStarted();
      await _createTaskFromForm(
        title: title,
        description: description,
        selectedDate: selectedDate,
        proofRequired: proofRequired,
        selectedChildIds: selectedChildIds,
        selectedResource: selectedResource,
        resourceAmount: resourceAmount,
        recurrence: recurrence,
        endDate: endDate,
      );
      return true;
    }

    return _updateTaskFromForm(
      context: context,
      occurrence: occurrence,
      title: title,
      description: description,
      selectedDate: selectedDate,
      currentStatus: currentStatus,
      proofRequired: proofRequired,
      selectedChildId: selectedChildId!,
      selectedResource: selectedResource,
      resourceAmount: resourceAmount,
      recurrence: recurrence,
      endDate: endDate,
      onSavingStarted: onSavingStarted,
    );
  }

  bool _validateTaskForm(
    BuildContext context,
    String title,
    List<String> selectedChildIds,
  ) {
    if (title.trim().isEmpty) {
      return false;
    }

    if (selectedChildIds.where((id) => id.isNotEmpty).isNotEmpty) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select at least one assignee")),
    );
    return false;
  }

  Future<void> _createTaskFromForm({
    required String title,
    required String description,
    required DateTime selectedDate,
    required bool proofRequired,
    required List<String> selectedChildIds,
    required String? selectedResource,
    required int resourceAmount,
    required _RecurrenceFields recurrence,
    required DateTime? endDate,
  }) async {
    final resource = selectedResource ?? 'food';
    final childIds = selectedChildIds
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (recurrence.pattern == 'Never') {
      final newTasks = <TaskOccurrence>[];

      for (final childId in childIds) {
        final newTemplate = await _taskRepository.createTemplate(
          title: title,
          description: description,
          proofRequired: proofRequired,
          resource: resource,
          resourceAmount: resourceAmount,
        );
        final newTask = await _taskRepository.createOccurrence(
          childId: childId,
          dueDate: selectedDate,
          status: 'NOTD',
          templateId: newTemplate.id,
        );
        newTasks.add(newTask);
      }

      setState(() => _tasks.insertAll(0, newTasks));
      return;
    }

    for (final childId in childIds) {
      await _taskRepository.saveRecurringTask(
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: resource,
        resourceAmount: resourceAmount,
        childId: childId,
        dueDate: selectedDate,
        endDate: endDate,
        pattern: recurrence.pattern,
        interval: recurrence.interval,
        dayOfWeek: recurrence.dayOfWeek,
        dayOfMonth: recurrence.dayOfMonth,
      );
    }
    await _refreshTasks();
  }

  Future<bool> _updateTaskFromForm({
    required BuildContext context,
    required TaskOccurrence occurrence,
    required String title,
    required String description,
    required DateTime selectedDate,
    required String currentStatus,
    required bool proofRequired,
    required String selectedChildId,
    required String? selectedResource,
    required int resourceAmount,
    required _RecurrenceFields recurrence,
    required DateTime? endDate,
    required VoidCallback onSavingStarted,
  }) async {
    final normalizedEndDate = _endOfDay(endDate);
    final updatePlan = await _chooseUpdatePlan(
      context: context,
      occurrence: occurrence,
      title: title,
      description: description,
      selectedDate: selectedDate,
      proofRequired: proofRequired,
      selectedChildId: selectedChildId,
      selectedResource: selectedResource,
      resourceAmount: resourceAmount,
      recurrence: recurrence,
      endDate: normalizedEndDate,
    );

    if (updatePlan == null) {
      return false;
    }

    onSavingStarted();

    if (updatePlan.scope == 'future') {
      await _taskRepository.updateRecurringSeries(
        templateId: occurrence.templateId,
        recurrenceId: occurrence.template!.recurrenceId,
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: selectedResource ?? 'food',
        resourceAmount: resourceAmount,
        childId: selectedChildId,
        startDate: selectedDate,
        pattern: recurrence.pattern,
        interval: recurrence.interval,
        dayOfWeek: recurrence.dayOfWeek,
        dayOfMonth: recurrence.dayOfMonth,
        endDate: normalizedEndDate,
        updateScope: updatePlan.updateScope ?? 'modify',
        updateChildAssignments: selectedChildId != occurrence.childId,
        syncGeneratedOccurrences:
            updatePlan.updateScope == 'bounds' &&
            !_isSameOptionalDate(
              occurrence.template?.endDate,
              normalizedEndDate,
            ),
        oldDueDate: occurrence.dueDate,
      );
      await _refreshTasks();
      return true;
    }

    await _updateSingleTaskFromForm(
      occurrence: occurrence,
      title: title,
      description: description,
      selectedDate: selectedDate,
      currentStatus: currentStatus,
      proofRequired: proofRequired,
      selectedChildId: selectedChildId,
      selectedResource: selectedResource,
      resourceAmount: resourceAmount,
    );
    return true;
  }

  Future<_SeriesUpdatePlan?> _chooseUpdatePlan({
    required BuildContext context,
    required TaskOccurrence occurrence,
    required String title,
    required String description,
    required DateTime selectedDate,
    required bool proofRequired,
    required String selectedChildId,
    required String? selectedResource,
    required int resourceAmount,
    required _RecurrenceFields recurrence,
    required DateTime? endDate,
  }) async {
    final dateChanged = !_isSameDate(occurrence.dueDate, selectedDate);
    final timeChanged = !_isSameTime(occurrence.dueDate, selectedDate);
    final recurrenceChanged = _recurrenceChanged(occurrence, recurrence);
    final patternTypeChanged = _recurrencePatternChanged(
      occurrence,
      recurrence,
    );
    final endDateChanged = !_isSameOptionalDate(
      occurrence.template?.endDate,
      endDate,
    );
    final isCurrentlyRecurring = occurrence.template?.recurrenceId != null;
    final wantToRecurring = recurrence.pattern != 'Never';
    final basicInfoChanged = _basicTaskInfoChanged(
      occurrence: occurrence,
      title: title,
      description: description,
      proofRequired: proofRequired,
      selectedChildId: selectedChildId,
      selectedResource: selectedResource,
      resourceAmount: resourceAmount,
    );

    if (!isCurrentlyRecurring && !wantToRecurring) {
      return _SeriesUpdatePlan.single();
    }
    if (isCurrentlyRecurring && !wantToRecurring) {
      final proceed = await _showSeriesActionDialog(
        context: context,
        title: 'End Recurrence',
        message:
            'This will end the old recurrence before this task and keep this task as a single task with the new changes.',
        confirmLabel: 'End Recurrence',
      );
      if (!proceed) {
        return null;
      }

      return _SeriesUpdatePlan.future('rewrite');
    }
    if (patternTypeChanged || (recurrenceChanged && !dateChanged)) {
      final proceed = await _showSeriesActionDialog(
        context: context,
        title: 'Create New Recurrence',
        message:
            'Changing the repeat rule will end the old recurrence before this task and create a new recurrence from this task forward.',
        confirmLabel: 'Create Recurrence',
      );
      if (!proceed) {
        return null;
      }

      return _SeriesUpdatePlan.future('rewrite');
    }

    if (dateChanged) {
      final proceed = await _showSeriesActionDialog(
        context: context,
        title: 'Rewrite Series',
        message:
            'Changing the due date will rewrite this recurrence so every pending task follows the new schedule. Tasks after the end date will be removed.',
        confirmLabel: 'Rewrite Series',
      );
      if (!proceed) {
        return null;
      }

      return _SeriesUpdatePlan.future('rewriteAll');
    }

    if (endDateChanged || basicInfoChanged) {
      final proceed = await _showSeriesActionDialog(
        context: context,
        title: 'Update Series',
        message:
            'These changes will update this recurrence. Pending tasks will shrink or expand to match the end date, and the time will be updated if it changed.',
        confirmLabel: 'Update Series',
      );
      if (!proceed) {
        return null;
      }

      return _SeriesUpdatePlan.future('bounds');
    }

    if (timeChanged) {
      final scope = await _showEditScopeDialog(context);
      if (scope == null || scope == 'cancel') {
        return null;
      }

      return _SeriesUpdatePlan(
        scope: scope,
        updateScope: scope == 'future' ? 'modify' : null,
      );
    }
    return _SeriesUpdatePlan.single();
  }

  Future<void> _updateSingleTaskFromForm({
    required TaskOccurrence occurrence,
    required String title,
    required String description,
    required DateTime selectedDate,
    required String currentStatus,
    required bool proofRequired,
    required String selectedChildId,
    required String? selectedResource,
    required int resourceAmount,
  }) async {
    final resource = selectedResource ?? 'food';
    final template = occurrence.template;
    final templateChanged =
        title != template?.title ||
        description != template?.description ||
        proofRequired != template?.proofRequired ||
        resource != template?.resource ||
        resourceAmount != template?.resourceAmount;
    final occurrenceChanged =
        !_isSameDate(occurrence.dueDate, selectedDate) ||
        !_isSameTime(occurrence.dueDate, selectedDate) ||
        currentStatus != occurrence.status ||
        selectedChildId != occurrence.childId;

    if (templateChanged) {
      await _taskRepository.updateTemplate(
        templateId: occurrence.templateId,
        title: title,
        description: description,
        proofRequired: proofRequired,
        resource: resource,
        resourceAmount: resourceAmount,
      );
    }

    if (occurrenceChanged) {
      await _taskRepository.updateOccurrence(
        occurrenceId: occurrence.id,
        dueDate: selectedDate,
        status: currentStatus,
        childId: selectedChildId,
      );
    }

    _replaceTaskInState(
      occurrence: occurrence,
      selectedDate: selectedDate,
      currentStatus: currentStatus,
      selectedChildId: selectedChildId,
      title: title,
      description: description,
      proofRequired: proofRequired,
      selectedResource: resource,
      resourceAmount: resourceAmount,
    );
  }

  void _replaceTaskInState({
    required TaskOccurrence occurrence,
    required DateTime selectedDate,
    required String currentStatus,
    required String selectedChildId,
    required String title,
    required String description,
    required bool proofRequired,
    required String selectedResource,
    required int resourceAmount,
  }) {
    final index = _tasks.indexWhere((task) => task.id == occurrence.id);
    if (index == -1) {
      return;
    }

    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        dueDate: selectedDate,
        status: currentStatus,
        childId: selectedChildId,
        childName: _childNameFor(selectedChildId),
        template: _tasks[index].template!.copyWith(
          title: title,
          description: description,
          proofRequired: proofRequired,
          resource: selectedResource,
          resourceAmount: resourceAmount,
        ),
      );
    });
  }

  _RecurrenceFields _recurrenceFromForm({
    required String repeatOption,
    required Map<String, dynamic>? customRecurrence,
    required DateTime selectedDate,
  }) {
    if (repeatOption == 'Never') {
      return const _RecurrenceFields(pattern: 'Never', interval: 1);
    }

    final isCustom = repeatOption == 'Custom';
    final pattern = isCustom
        ? _normalizeRecurrencePattern(
            (customRecurrence?['pattern'] as String?) ?? 'Daily',
          )
        : _normalizeRecurrencePattern(repeatOption);
    final interval = isCustom
        ? (customRecurrence?['interval'] as int?) ?? 1
        : 1;
    final customDays = isCustom
        ? List<int>.from(customRecurrence?['selectedDays'] ?? [])
        : null;
    final selectedDays = customDays == null || customDays.isEmpty
        ? null
        : customDays;

    return _RecurrenceFields(
      pattern: pattern,
      interval: interval,
      dayOfWeek: pattern == 'Weekly'
          ? selectedDays ?? [selectedDate.weekday]
          : null,
      dayOfMonth: pattern == 'Monthly'
          ? selectedDays ?? [selectedDate.day]
          : null,
    );
  }

  bool _recurrenceChanged(
    TaskOccurrence occurrence,
    _RecurrenceFields recurrence,
  ) {
    final oldRecurrence = occurrence.template?.recurrence;
    final oldPattern = _normalizeRecurrencePattern(
      oldRecurrence?.pattern ?? 'Never',
    );

    if (recurrence.pattern != oldPattern) {
      return true;
    }
    if (oldRecurrence == null) {
      return false;
    }
    if (oldRecurrence.interval != recurrence.interval) {
      return true;
    }
    if (recurrence.pattern == 'Weekly') {
      return !_sameIntList(
        oldRecurrence.dayOfWeek ?? [],
        recurrence.dayOfWeek ?? [],
      );
    }
    if (recurrence.pattern == 'Monthly') {
      return !_sameIntList(
        oldRecurrence.dayOfMonth ?? [],
        recurrence.dayOfMonth ?? [],
      );
    }

    return false;
  }

  bool _recurrencePatternChanged(
    TaskOccurrence occurrence,
    _RecurrenceFields recurrence,
  ) {
    final oldPattern = _normalizeRecurrencePattern(
      occurrence.template?.recurrence?.pattern ?? 'Never',
    );

    return recurrence.pattern != oldPattern;
  }

  String _normalizeRecurrencePattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'never':
        return 'Never';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return pattern;
    }
  }

  bool _basicTaskInfoChanged({
    required TaskOccurrence occurrence,
    required String title,
    required String description,
    required bool proofRequired,
    required String selectedChildId,
    required String? selectedResource,
    required int resourceAmount,
  }) {
    final template = occurrence.template;

    return title != template?.title ||
        description != template?.description ||
        proofRequired != template?.proofRequired ||
        selectedChildId != occurrence.childId ||
        (selectedResource ?? 'food') != template?.resource ||
        resourceAmount != template?.resourceAmount;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isSameOptionalDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) {
      return first == second;
    }

    return _isSameDate(first, second);
  }

  bool _isSameTime(DateTime first, DateTime second) {
    return first.hour == second.hour && first.minute == second.minute;
  }

  bool _endDateMovedEarlier(DateTime? oldEndDate, DateTime? newEndDate) {
    if (newEndDate == null) {
      return false;
    }

    if (oldEndDate == null) {
      return true;
    }

    if (_isSameDate(oldEndDate, newEndDate)) {
      return false;
    }

    return newEndDate.isBefore(oldEndDate);
  }

  bool _sameIntList(List<int> first, List<int> second) {
    final sortedFirst = [...first]..sort();
    final sortedSecond = [...second]..sort();

    return listEquals(sortedFirst, sortedSecond);
  }

  DateTime? _endOfDay(DateTime? date) {
    return date?.copyWith(
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
      microsecond: 999,
    );
  }

  String _childNameFor(String selectedChildId) {
    return _availableChildren
        .firstWhere(
          (child) => child['id'] == selectedChildId,
          orElse: () => {'name': 'Unknown'},
        )['name']
        .toString();
  }

  Future<DateTime?> _showCustomDateTimePicker(
    BuildContext context,
    DateTime initialDate,
    bool showTime,
  ) async {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
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
                  width: screenWidth * 0.85,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
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
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),

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
          title: const Text("Update Time"),
          content: const Text(
            "You changed only the time for this repeating task. Should this affect just this task or this and future tasks?",
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

    bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    try {
      // Collect template IDs for the selected occurrences
      final templateIds = _tasks
          .where((t) => _selectedTaskIds.contains(t.id))
          .map((t) => t.templateId)
          .toList();

      await _taskRepository.deleteTasksBulk(
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

  Future<bool> _showSeriesActionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _RecurrenceFields {
  const _RecurrenceFields({
    required this.pattern,
    required this.interval,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  final String pattern;
  final int interval;
  final List<int>? dayOfWeek;
  final List<int>? dayOfMonth;
}

class _SeriesUpdatePlan {
  const _SeriesUpdatePlan({required this.scope, this.updateScope});

  factory _SeriesUpdatePlan.single() {
    return const _SeriesUpdatePlan(scope: 'single');
  }

  factory _SeriesUpdatePlan.future(String updateScope) {
    return _SeriesUpdatePlan(scope: 'future', updateScope: updateScope);
  }

  final String scope;
  final String? updateScope;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.occurrence,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  final TaskOccurrence occurrence;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final template = occurrence.template;
    final isDone = occurrence.status == 'COMP';

    if (template == null) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: isDone ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        color: _cardColor(colorScheme, isDone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor(colorScheme, isDone)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (isSelectionMode) _SelectionIcon(isSelected: isSelected),
                _ChildAvatarWithStatus(
                  avatarUrl: occurrence.childAvatar,
                  isDone: isDone,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TaskCardDetails(
                    occurrence: occurrence,
                    isDone: isDone,
                  ),
                ),
                _TaskCardTrailing(
                  dueDate: occurrence.dueDate,
                  isDone: isDone,
                  showChevron: !isSelectionMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _cardColor(ColorScheme colorScheme, bool isDone) {
    if (isSelected) {
      return colorScheme.primaryContainer;
    }

    return isDone ? colorScheme.surfaceContainerHigh : colorScheme.surface;
  }

  Color _borderColor(ColorScheme colorScheme, bool isDone) {
    if (isSelected) {
      return colorScheme.primary.withAlpha(100);
    }

    return isDone ? Colors.transparent : colorScheme.primary.withAlpha(50);
  }
}

class _SelectionIcon extends StatelessWidget {
  const _SelectionIcon({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.outline,
        size: 20,
      ),
    );
  }
}

class _ChildAvatarWithStatus extends StatelessWidget {
  const _ChildAvatarWithStatus({required this.avatarUrl, required this.isDone});

  final String avatarUrl;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.surfaceDim,
          backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
          child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
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
              child: Icon(Icons.check, size: 10, color: colorScheme.onPrimary),
            ),
          ),
      ],
    );
  }
}

class _TaskCardDetails extends StatelessWidget {
  const _TaskCardDetails({required this.occurrence, required this.isDone});

  final TaskOccurrence occurrence;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final template = occurrence.template!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          template.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? colorScheme.outline : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              occurrence.childName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.secondary,
                // fontWeight: FontWeight.w500,
                // letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // TODO:change icon baeed on resource type in the future 
                  const Icon(Icons.stars_rounded, size: 12, color: Colors.orangeAccent),
                  const SizedBox(width: 4),
                  Text(
                    "${template.resourceAmount}",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaskCardTrailing extends StatelessWidget {
  const _TaskCardTrailing({
    required this.dueDate,
    required this.isDone,
    required this.showChevron,
  });

  final DateTime dueDate;
  final bool isDone;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _DueChip(date: dueDate, isDone: isDone),
        if (showChevron) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 20, color: colorScheme.outline),
        ],
      ],
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.date, required this.isDone});

  final DateTime date;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isOverdue = date.isBefore(DateTime(now.year, now.month, now.day)) && !isDone;

    // Semantic Colors: Red for overdue, Primary for upcoming, Outline for done
    final Color color = isDone 
        ? colorScheme.outline 
        : (isOverdue ? colorScheme.error : colorScheme.primary);

    String label = DateFormat('MMM d').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: isOverdue ? Border.all(color: color.withAlpha(50)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
