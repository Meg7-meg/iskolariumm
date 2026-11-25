part of '../main.dart';

// ============================================================
// ISKOLARIUM - TASKS SCREEN
// Student academic task management
// ============================================================

class TasksPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const TasksPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String filter = 'All';
  bool sortAscending = true;
  String searchQuery = '';
  bool _isLoading = true;
  List<ClassAssignmentRecord> _officialAssignments = const [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final records = await OrganizerService.getTasks();
      List<ClassAssignmentRecord> assignments = const [];
      try {
        assignments = await AcademicService.getStudentAssignments();
      } catch (_) {
        // Keep personal tasks working even if migration 003 isn't applied yet.
      }
      TaskStore.items
        ..clear()
        ..addAll(
          records.map((r) {
            String dueText = 'Due date not set';
            if (r.dueAt != null) {
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              dueText =
                  'Due ${months[r.dueAt!.month - 1]} ${r.dueAt!.day}, ${r.dueAt!.year}';
            }
            return TaskItem(
              id: r.id,
              title: r.title,
              subject: r.subject.isEmpty ? 'General' : r.subject,
              description: r.description,
              category: r.category,
              dueAt: r.dueAt,
              due: dueText,
              priority: r.priority,
              done: r.isCompleted,
            );
          }),
        );
      if (mounted) {
        setState(() {
          _officialAssignments = assignments;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final allTasks = TaskStore.items;

    final remainingCount =
        allTasks.where((task) => !task.done).length;
    final completedCount =
        allTasks.where((task) => task.done).length;

    final tasks = allTasks.where((task) {
      final matchesFilter = filter == 'All'
          ? true
          : filter == 'Upcoming'
              ? !task.done
              : task.done;

      final query = searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.subject.toLowerCase().contains(query) ||
          task.priority.toLowerCase().contains(query) ||
          task.due.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();

    tasks.sort((a, b) {
      final comparison = a.title
          .toLowerCase()
          .compareTo(b.title.toLowerCase());

      return sortAscending ? comparison : -comparison;
    });

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ResponsiveContainer(
        maxWidth: 960,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: AcademicPageHeader(
                eyebrow: 'Academic Tasks',
                title: 'My Tasks',
                subtitle:
                    '$remainingCount ${remainingCount == 1 ? 'task' : 'tasks'} remaining',
                actions: [
                  FilledButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('New Task'),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildSummary(
              allCount: allTasks.length,
              remainingCount: remainingCount,
              completedCount: completedCount,
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildSearchField(),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildFilterBar(
              allCount: allTasks.length,
              upcomingCount: remainingCount,
              doneCount: completedCount,
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tasks.length} ${tasks.length == 1 ? 'Task' : 'Tasks'}',
                        style: const TextStyle(
                          color: _darkBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Manage your academic activities',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSortButton(),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_officialAssignments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Assignments (${_officialAssignments.length})',
                      style: const TextStyle(
                        color: _darkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._officialAssignments.take(3).map((a) {
                      final dueStr = a.dueAt == null
                          ? 'No due date'
                          : 'Due ${a.dueAt!.month}/${a.dueAt!.day}/${a.dueAt!.year}';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${a.subjectCode}: ${a.title} ($dueStr)',
                          style: const TextStyle(
                            color: _darkBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      110,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];

                      return Dismissible(
                        key: ObjectKey(task),
                        direction: DismissDirection.endToStart,
                        background: _buildDeleteBackground(),
                        confirmDismiss: (_) =>
                            _confirmDelete(task),
                        onDismissed: (_) {
                          _deleteTask(task);
                        },
                        child: TaskCard(
                          task: task,
                          onChanged: (value) async {
                            final next = value ?? false;
                            setState(() {
                              task.done = next;
                            });
                            if (task.id != null) {
                              try {
                                await OrganizerService.toggleTaskCompleted(
                                  task.id!,
                                  next,
                                );
                              } catch (e) {
                                if (mounted) {
                                  setState(() => task.done = !next);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(formatSupabaseError(e)),
                                    ),
                                  );
                                }
                              }
                            }
                            widget.onRefresh();
                          },
                          onEdit: () {
                            _editTask(task);
                          },
                          onDelete: () {
                            _deleteTaskWithConfirmation(task);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  // ============================================================
  // HEADER (kept for compatibility)
  // ============================================================

  Widget _buildHeader(int remainingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Tasks',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$remainingCount ${remainingCount == 1 ? 'task' : 'tasks'} remaining',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _blue,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _addTask,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary({
    required int allCount,
    required int remainingCount,
    required int completedCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            label: 'Total',
            count: allCount,
            icon: LucideIcons.clipboardList,
            color: _blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            label: 'Pending',
            count: remainingCount,
            icon: LucideIcons.clock3,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            label: 'Completed',
            count: completedCount,
            icon: LucideIcons.circleCheck,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: const TextStyle(
          color: _darkBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks or subjects...',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            color: _muted,
            size: 18,
          ),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    LucideIcons.x,
                    color: _muted,
                    size: 17,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar({
    required int allCount,
    required int upcomingCount,
    required int doneCount,
  }) {
    final filters = [
      ('All', allCount),
      ('Upcoming', upcomingCount),
      ('Done', doneCount),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: filters.map((item) {
          final label = item.$1;
          final count = item.$2;

                    final selected = filter == label;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  filter = label;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: selected
                      ? Border.all(color: _border)
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _blue.withValues(alpha: 0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? _blue : _muted,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _lightBlue
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: selected ? _blue : _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SORT BUTTON
  // ============================================================

  Widget _buildSortButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          sortAscending = !sortAscending;
        });
      },
      icon: const Icon(
        LucideIcons.arrowUpDown,
        size: 14,
      ),
      label: Text(sortAscending ? 'A–Z' : 'Z–A'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkBlue,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // ADD TASK
  // ============================================================

  void _addTask() {
    showTaskDialog(
      context,
      onSaved: () {
        setState(() {});
        widget.onRefresh();
      },
    );
  }

  // ============================================================
  // EDIT TASK
  // ============================================================

  void _editTask(TaskItem task) {
    showTaskDialog(
      context,
      task: task,
      onSaved: () {
        setState(() {});
        widget.onRefresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  // ============================================================
  // DELETE BACKGROUND
  // ============================================================

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.trash2,
            color: AppColors.danger,
            size: 22,
          ),
          SizedBox(height: 5),
          Text(
            'Delete',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(TaskItem task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete task?',
            style: TextStyle(
              color: _darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteTaskWithConfirmation(
    TaskItem task,
  ) async {
    final confirmed = await _confirmDelete(task);

    if (confirmed && mounted) {
      _deleteTask(task);
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    final originalIndex = TaskStore.items.indexOf(task);

    if (originalIndex == -1) return;

    setState(() {
      TaskStore.items.remove(task);
    });

    if (task.id != null) {
      try {
        await OrganizerService.deleteTask(task.id!);
      } catch (e) {
        if (mounted) {
          setState(() {
            TaskStore.items.insert(
              originalIndex.clamp(0, TaskStore.items.length),
              task,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(formatSupabaseError(e))),
          );
          return;
        }
      }
    }

    widget.onRefresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task deleted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    String title;
    String description;
    IconData icon;

    if (searchQuery.trim().isNotEmpty) {
      title = 'No matching tasks';
      description =
          'Try another keyword or clear your search.';
      icon = LucideIcons.searchX;
    } else if (filter == 'Upcoming') {
      title = 'All caught up!';
      description =
          'You do not have any pending tasks right now.';
      icon = LucideIcons.circleCheck;
    } else if (filter == 'Done') {
      title = 'No completed tasks';
      description =
          'Tasks you complete will appear here.';
      icon = LucideIcons.clipboardCheck;
    } else {
      title = 'No tasks yet';
      description =
          'Add your first academic task to get started.';
      icon = LucideIcons.notebookPen;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 34,
                color: _blue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkBlue,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                  });
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TASK CARD
// ============================================================

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final completed = task.done;
    final dueColor = completed
        ? AppColors.successDark
        : task.priority == 'High'
            ? AppColors.danger
            : task.priority == 'Medium'
                ? AppColors.warningDark
                : AppColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.background
            : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: completed
              ? AppColors.border
              : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.045),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: completed
                    ? AppColors.primaryLight
                    : _blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(17),
                  bottomLeft: Radius.circular(17),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Center(
              child: Transform.scale(
                scale: 0.95,
                child: Checkbox(
                  value: completed,
                  onChanged: onChanged,
                  activeColor: _blue,
                  side: const BorderSide(
                    color: AppColors.primaryLight,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: completed ? _muted : _darkBlue,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.bookOpen,
                          color: _blue,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          completed
                              ? LucideIcons.circleCheck
                              : LucideIcons.clock3,
                          color: dueColor,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            completed ? 'Completed' : task.due,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dueColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 5,
                top: 8,
                bottom: 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Task options',
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      LucideIcons.ellipsis,
                      color: _muted,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.pencil,
                              size: 17,
                              color: _blue,
                            ),
                            SizedBox(width: 10),
                            Text('Edit Task'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 17,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 10),
                            Text('Delete Task'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 7,
                      bottom: 5,
                    ),
                    child: PriorityPill(
                      priority: completed ? 'Done' : task.priority,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRIORITY PILL
// ============================================================

class PriorityPill extends StatelessWidget {
  final String priority;

  const PriorityPill({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final high = priority == 'High';
    final done = priority == 'Done';
    final low = priority == 'Low';

    final background = high
        ? AppColors.danger
        : done
            ? AppColors.surfaceSoft
            : low
                ? AppColors.successLight
                : AppColors.warningLight;

    final foreground = high
        ? Colors.white
        : done
            ? AppColors.textSecondary
            : low
                ? AppColors.successDark
                : AppColors.warningDark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// ADD / EDIT TASK DIALOG
// ============================================================

void showTaskDialog(
  BuildContext context, {
  TaskItem? task,
  required VoidCallback onSaved,
}) {
  final isEditing = task != null;

  final titleController = TextEditingController(
    text: task?.title ?? '',
  );

  final subjectController = TextEditingController(
    text: task?.subject ?? '',
  );

  DateTime? selectedDueDate;
  String selectedPriority = task?.priority ?? 'Medium';

  final priorities = ['Low', 'Medium', 'High'];

  // Keep the existing due-date text when editing.
  String existingDue = task?.due ?? '';

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return 'Due ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEditing ? 'Edit Task' : 'Add New Task',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: _taskInputDecoration(
                      label: 'Task title',
                      icon: LucideIcons.pencil,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: _taskInputDecoration(
                      label: 'Subject',
                      icon: LucideIcons.bookOpen,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Due date',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(
                        now.year,
                        now.month,
                        now.day,
                      );

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? today,
                        firstDate: today,
                        lastDate: today.add(
                          const Duration(days: 3650),
                        ),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedDueDate = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendarDays,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedDueDate != null
                                  ? formatDate(selectedDueDate!)
                                  : existingDue.isNotEmpty
                                      ? existingDue
                                      : 'Choose a due date (optional)',
                              style: TextStyle(
                                color: selectedDueDate == null &&
                                        existingDue.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.textSecondary,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Priority',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: priorities.map((priority) {
                      final selected =
                          selectedPriority == priority;

                      return Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedPriority = priority;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 150,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (priority == 'High'
                                        ? AppColors.danger
                                        : priority == 'Medium'
                                            ? AppColors.warning
                                            : AppColors.success)
                                    : AppColors.surfaceSoft,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? (priority == 'High'
                                          ? AppColors.danger
                                          : priority == 'Medium'
                                              ? AppColors.warning
                                              : AppColors.success)
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : (priority == 'High'
                                            ? AppColors.dangerDark
                                            : priority == 'Medium'
                                                ? AppColors.warningDark
                                                : AppColors.successDark),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final subject =
                      subjectController.text.trim();

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a task title.',
                        ),
                      ),
                    );
                    return;
                  }

                  final dueDate = selectedDueDate ?? task?.dueAt;
                  final due = dueDate != null
                      ? formatDate(dueDate)
                      : existingDue.isNotEmpty
                          ? existingDue
                          : 'Due date not set';

                  try {
                    if (isEditing && task!.id != null) {
                      await OrganizerService.updateTask(
                        id: task.id!,
                        title: title,
                        subject: subject.isEmpty ? 'General' : subject,
                        dueAt: dueDate,
                        priority: selectedPriority,
                        isCompleted: task.done,
                      );
                      final index = TaskStore.items.indexOf(task);
                      if (index != -1) {
                        TaskStore.items[index] = TaskItem(
                          id: task.id,
                          title: title,
                          subject: subject.isEmpty ? 'General' : subject,
                          dueAt: dueDate,
                          due: due,
                          priority: selectedPriority,
                          done: task.done,
                        );
                      }
                    } else {
                      final created = await OrganizerService.createTask(
                        title: title,
                        subject: subject.isEmpty ? 'General' : subject,
                        dueAt: dueDate,
                        priority: selectedPriority,
                      );
                      TaskStore.items.insert(
                        0,
                        TaskItem(
                          id: created.id,
                          title: created.title,
                          subject: created.subject.isEmpty
                              ? 'General'
                              : created.subject,
                          dueAt: created.dueAt,
                          due: due,
                          priority: created.priority,
                        ),
                      );
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    onSaved();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(formatSupabaseError(e))),
                    );
                  }
                },
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Task',
                ),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    titleController.dispose();
    subjectController.dispose();
  });
}

// ============================================================
// TASK INPUT DECORATION
// ============================================================

InputDecoration _taskInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 12,
    ),
    prefixIcon: Icon(
      icon,
      color: AppColors.primary,
      size: 18,
    ),
    filled: true,
    fillColor: AppColors.surfaceSoft,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 13,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.2,
      ),
    ),
  );
}