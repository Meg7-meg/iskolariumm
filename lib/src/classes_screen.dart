part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - STUDENT CLASSES
// Frontend-only class management
// ------------------------------------------------------------

class ClassesPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const ClassesPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  late final List<ClassItem> _classes;
  final TextEditingController _searchController =
      TextEditingController();

  String _filter = 'All';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _classes = List<ClassItem>.of(sampleClasses);
    _syncStudentEnrollments();
  }

  // Keep the shared enrollment list updated so announcements can be
  // delivered only to students enrolled in the matching class and section.
  void _syncStudentEnrollments() {
    StudentEnrollmentStore.sync(
      _classes
          .map(
            (item) => StudentEnrollment(
              code: item.code,
              name: item.name,
              section: item.section,
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // FILTER LOGIC
  // ------------------------------------------------------------

  bool _matchesDay(String day, int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    if (weekday < 1 || weekday > 7) return false;

    final normalized = day.trim().toLowerCase();
    final target = days[weekday - 1];

    return normalized == target ||
        normalized == target.substring(0, 3);
  }

  bool _isScheduledThisWeek(String day) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final normalized = day.trim().toLowerCase();

    return days.any(
      (value) =>
          normalized == value ||
          normalized == value.substring(0, 3),
    );
  }

  List<ClassItem> get _filteredClasses {
    final today = DateTime.now().weekday;
    final query = _search.trim().toLowerCase();

    return _classes.where((item) {
      final searchableText = [
        item.name,
        item.code,
        item.section,
        item.instructor,
        item.location,
        item.day,
        item.time,
      ].join(' ').toLowerCase();

      final matchesSearch = searchableText.contains(query);

      final matchesFilter = switch (_filter) {
        'Today' => _matchesDay(item.day, today),
        'This week' => _isScheduledThisWeek(item.day),
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ------------------------------------------------------------
  // ADD CLASS
  // ------------------------------------------------------------

  Future<void> _addClass() async {
    final newClass = await showDialog<ClassItem>(
      context: context,
      builder: (_) => const _AddClassDialog(),
    );

    if (!mounted || newClass == null) return;

    setState(() {
      _classes.add(newClass);
    });

    _syncStudentEnrollments();
    widget.onRefresh();
    _showMessage('${newClass.code} was added to your classes.');
  }

  // ------------------------------------------------------------
  // EDIT CLASS
  // ------------------------------------------------------------

  Future<void> _editClass(ClassItem item) async {
    final updatedClass = await showDialog<ClassItem>(
      context: context,
      builder: (_) => _AddClassDialog(
        initialClass: item,
      ),
    );

    if (!mounted || updatedClass == null) return;

    final index = _classes.indexOf(item);

    if (index == -1) return;

    setState(() {
      _classes[index] = updatedClass;
    });

    _syncStudentEnrollments();
    widget.onRefresh();
    _showMessage('${updatedClass.code} was updated successfully.');
  }

  // ------------------------------------------------------------
  // DELETE CLASS
  // ------------------------------------------------------------

  Future<void> _deleteClass(ClassItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Class?',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${item.code} - ${item.name}? This action cannot be undone.',
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
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _classes.remove(item);
    });

    _syncStudentEnrollments();
    widget.onRefresh();
    _showMessage('${item.code} was deleted.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkBlue,
        ),
      );
  }

  // ------------------------------------------------------------
  // CLEAR FILTERS
  // ------------------------------------------------------------

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _search = '';
      _filter = 'All';
    });
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClasses;

    return Container(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 22),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildSearchBar(),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildFilterBar(),
          ),

          const SizedBox(height: 22),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildClassCount(filtered.length),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      110,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 13),
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return ClassListCard(
                        item: item,
                        onEdit: () => _editClass(item),
                        onDelete: () => _deleteClass(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Classes',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_classes.length} enrolled subjects',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Tooltip(
      message: 'Add a class',
      child: Material(
        color: _blue,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: _blue.withValues(alpha: 0.22),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _addClass,
          child: const SizedBox(
            width: 50,
            height: 50,
            child: Center(
              child: Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _darkBlue.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.search,
            color: _muted,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              style: const TextStyle(
                color: _darkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search classes, subjects or instructors...',
                hintStyle: TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_search.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _search = '';
                });
              },
              icon: const Icon(
                LucideIcons.x,
                color: _muted,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTERS
  // ------------------------------------------------------------

  Widget _buildFilterBar() {
    const labels = ['All', 'Today', 'This week'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: labels.map((label) {
          final selected = _filter == label;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filter = label;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
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
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? _blue : _muted,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------
  // CLASS COUNT
  // ------------------------------------------------------------

  Widget _buildClassCount(int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 35,
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
                '$count ${count == 1 ? 'Class' : 'Classes'}',
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Your enrolled subjects',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          LucideIcons.graduationCap,
          color: _blue,
          size: 21,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    final hasSearch = _search.trim().isNotEmpty;

    final message = hasSearch
        ? 'Try another keyword or check your spelling.'
        : _filter == 'Today'
            ? 'You have no classes scheduled for today.'
            : _filter == 'This week'
                ? 'There are no classes scheduled this week.'
                : 'Add your first class to start organizing your subjects.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.bookOpen,
                  color: _blue,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No classes found',
              style: TextStyle(
                color: _darkBlue,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            if (_filter != 'All' || _search.isNotEmpty)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(
                  LucideIcons.rotateCcw,
                  size: 15,
                ),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(
                  foregroundColor: _blue,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: _addClass,
                icon: const Icon(LucideIcons.plus, size: 17),
                label: const Text('Add a class'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// CLASS CARD
// ------------------------------------------------------------

class ClassListCard extends StatelessWidget {
  final ClassItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClassListCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final progress = item.progress.clamp(0.0, 1.0);
    final progressColor = progress >= 0.75
        ? AppColors.success
        : progress >= 0.40
            ? AppColors.warning
            : AppColors.info;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(
                classItem: item,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1A56DB),
                        AppColors.primaryLight,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.bookOpen,
                        color: _blue,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 5,
                          crossAxisAlignment:
                              WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.code,
                                style: const TextStyle(
                                  color: _blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.infoLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.section,
                                style: const TextStyle(
                                  color: AppColors.infoDark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${item.day} · ${item.time}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _darkBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Row(
                          children: [
                            const Icon(
                              LucideIcons.userRound,
                              size: 13,
                              color: _muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${item.instructor} · ${item.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Class progress',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                color: progressColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor:
                                const Color(0xFFE0ECFF),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CLASS OPTIONS MENU
                PopupMenuButton<String>(
                  tooltip: 'Class options',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    color: _muted,
                    size: 21,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: _blue,
                          ),
                          SizedBox(width: 10),
                          Text('Edit class'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete class',
                            style: TextStyle(
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// ADD / EDIT CLASS DIALOG
// ------------------------------------------------------------

class _AddClassDialog extends StatefulWidget {
  final ClassItem? initialClass;

  const _AddClassDialog({
    this.initialClass,
  });

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;

  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _instructorController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _sectionController = TextEditingController();

  String _selectedDay = 'Monday';

  bool get _isEditing => widget.initialClass != null;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();

    final existingClass = widget.initialClass;

    if (existingClass != null) {
      _codeController.text = existingClass.code;
      _nameController.text = existingClass.name;
      _instructorController.text =
          existingClass.instructor == 'Not specified'
              ? ''
              : existingClass.instructor;
      _locationController.text =
          existingClass.location == 'Not specified'
              ? ''
              : existingClass.location;
      _timeController.text =
          existingClass.time == 'Time not specified'
              ? ''
              : existingClass.time;
      _sectionController.text = existingClass.section;

      _selectedDay = _days.firstWhere(
        (day) => day.toLowerCase() ==
            existingClass.day.trim().toLowerCase(),
        orElse: () => 'Monday',
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _instructorController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  // ------------------------------------------------------------
  // SAVE CLASS
  // ------------------------------------------------------------

  void _saveClass() {
    if (!_formKey.currentState!.validate()) return;

    final updatedClass = ClassItem(
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      instructor: _instructorController.text.trim().isEmpty
          ? 'Not specified'
          : _instructorController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? 'Not specified'
          : _locationController.text.trim(),
      day: _selectedDay,
      time: _timeController.text.trim().isEmpty
          ? 'Time not specified'
          : _timeController.text.trim(),
      section: _sectionController.text.trim().isEmpty
          ? 'Section A'
          : _sectionController.text.trim(),
      progress: widget.initialClass?.progress ?? 0.0,
    );

    Navigator.pop(context, updatedClass);
  }

  // ------------------------------------------------------------
  // DIALOG UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 12),

      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _isEditing
                  ? Icons.edit_outlined
                  : LucideIcons.bookPlus,
              color: _blue,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Class' : 'Add a Class',
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEditing
                      ? 'Update your subject information'
                      : 'Enter your subject information',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  controller: _codeController,
                  label: 'Course code',
                  hint: 'e.g. CS 101',
                  icon: LucideIcons.hash,
                  validator: _requiredValidator,
                ),

                const SizedBox(height: 13),

                _field(
                  controller: _nameController,
                  label: 'Class name',
                  hint: 'e.g. Introduction to Programming',
                  icon: LucideIcons.bookOpen,
                  validator: _requiredValidator,
                ),

                const SizedBox(height: 13),

                _field(
                  controller: _sectionController,
                  label: 'Section',
                  hint: 'e.g. Section A or BSCS 3A',
                  icon: LucideIcons.users,
                  validator: _requiredValidator,
                ),

                const SizedBox(height: 13),

                _field(
                  controller: _instructorController,
                  label: 'Instructor',
                  hint: 'e.g. Prof. Santos',
                  icon: LucideIcons.userRound,
                ),

                const SizedBox(height: 13),

                _field(
                  controller: _locationController,
                  label: 'Room / Location',
                  hint: 'e.g. Room 12',
                  icon: LucideIcons.mapPin,
                ),

                const SizedBox(height: 13),

                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: _decoration(
                    label: 'Class day',
                    icon: LucideIcons.calendarDays,
                  ),
                  items: _days.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedDay = value;
                    });
                  },
                ),

                const SizedBox(height: 13),

                _field(
                  controller: _timeController,
                  label: 'Class time',
                  hint: 'e.g. 9:00 AM - 10:30 AM',
                  icon: LucideIcons.clock,
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.info,
                        color: _blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Your changes will update this class in the current app session.'
                              : 'This class will be added to this screen using temporary app data.',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        FilledButton.icon(
          onPressed: _saveClass,
          icon: Icon(
            _isEditing ? Icons.save_outlined : LucideIcons.plus,
            size: 16,
          ),
          label: Text(
            _isEditing ? 'Save Changes' : 'Add Class',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(
        color: _darkBlue,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: _decoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _decoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 12,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA8BC),
        fontSize: 11,
      ),
      prefixIcon: Icon(
        icon,
        color: _blue,
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
          color: _blue,
          width: 1.2,
        ),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
  }
}