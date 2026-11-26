part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - STUDENT CLASSES
// Frontend-only class management
// ------------------------------------------------------------

class ClassesPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const ClassesPage({super.key, required this.onRefresh});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _border = AppColors.border;

  final List<ClassItem> _classes = [];
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _pendingEnrollments = const [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final official = await ClassService.getStudentApprovedClasses();
      final personal = await ClassService.getStudentPersonalClasses();
      final pending = await ClassService.getStudentPendingEnrollments();

      final loaded = <ClassItem>[
        ...official.map(
          (c) => ClassItem(
            id: c.id,
            code: c.subjectCode.isEmpty ? 'CLASS' : c.subjectCode,
            name: c.className,
            instructor: c.instructorName,
            location: c.room.isEmpty ? 'TBA' : c.room,
            day: c.scheduleDay.isEmpty ? 'TBA' : c.scheduleDay,
            time: c.scheduleTime.isEmpty ? 'TBA' : c.scheduleTime,
            schedules: c.effectiveSchedules,
            progress: 1.0,
            section: c.section,
            isOfficial: true,
            enrollmentCode: c.enrollmentCode,
            description: c.description,
          ),
        ),
        ...personal.map(
          (p) => ClassItem(
            id: p.id,
            code: p.subjectCode,
            name: p.className,
            instructor: p.instructorName.isEmpty
                ? 'Personal Course'
                : p.instructorName,
            location: p.location.isEmpty ? 'Personal' : p.location,
            day: p.scheduleDay.isEmpty ? 'Flexible' : p.scheduleDay,
            time: p.scheduleTime.isEmpty ? 'Flexible' : p.scheduleTime,
            schedules: p.schedules,
            progress: 1.0,
            section: p.section,
            isOfficial: false,
          ),
        ),
      ];

      if (!mounted) return;
      setState(() {
        _classes
          ..clear()
          ..addAll(loaded);
        _pendingEnrollments = pending;
        _isLoading = false;
      });
      _syncStudentEnrollments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = formatSupabaseError(e);
      });
    }
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

  List<ClassItem> get _filteredClasses {
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
        item.scheduleSummary,
      ].join(' ').toLowerCase();

      final matchesSearch = searchableText.contains(query);

      return matchesSearch;
    }).toList();
  }

  // ------------------------------------------------------------
  // ADD / JOIN CLASS
  // ------------------------------------------------------------

  Future<void> _addClass() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add a Course',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Join an official instructor class using a class code, or create a personal class for your own schedule.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'personal'),
              child: const Text(
                'Personal Course',
                style: TextStyle(color: _darkBlue, fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'join'),
              style: FilledButton.styleFrom(backgroundColor: _blue),
              child: const Text('Join with Enrollment Code'),
            ),
          ],
        );
      },
    );

    if (!mounted || choice == null) return;

    if (choice == 'join') {
      await _joinWithCodeDialog();
      return;
    }

    final newClass = await showDialog<ClassItem>(
      context: context,
      builder: (_) => const _AddClassDialog(),
    );

    if (!mounted || newClass == null) return;

    try {
      await ClassService.createPersonalClass(
        subjectCode: newClass.code,
        className: newClass.name,
        instructorName: newClass.instructor,
        location: newClass.location,
        scheduleDay: newClass.day,
        scheduleTime: newClass.time,
      );
      await _loadClasses();
      widget.onRefresh();
      if (mounted) {
        _showMessage('${newClass.code} was added to your personal classes.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage(formatSupabaseError(e));
      }
    }
  }

  Future<void> _joinWithCodeDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Join Official Class',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Class Enrollment Code',
                hintText: 'e.g. AB12CD',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter the course enrollment code.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _blue),
              child: const Text('Join Class'),
            ),
          ],
        );
      },
    );

    if (submitted == true && mounted) {
      try {
        final result = await ClassService.joinClassByCode(controller.text);
        await _loadClasses();
        widget.onRefresh();
        if (mounted) {
          final className = (result['class_name'] ?? 'class').toString();
          _showMessage(
            'Enrollment request sent for $className (pending instructor approval).',
          );
        }
      } catch (e) {
        if (mounted) {
          _showMessage(formatSupabaseError(e));
        }
      }
    }
    controller.dispose();
  }

  // ------------------------------------------------------------
  // EDIT CLASS
  // ------------------------------------------------------------

  Future<void> _editClass(ClassItem item) async {
    if (item.isOfficial) {
      _showMessage('Official instructor classes cannot be edited by students.');
      return;
    }

    final updatedClass = await showDialog<ClassItem>(
      context: context,
      builder: (_) => _AddClassDialog(initialClass: item),
    );

    if (!mounted || updatedClass == null || item.id == null) return;

    try {
      await supabase
          .from('student_personal_classes')
          .update({
            'subject_code': updatedClass.code.trim().toUpperCase(),
            'class_name': updatedClass.name.trim(),
            'instructor_name': updatedClass.instructor.trim(),
            'location': updatedClass.location.trim(),
            'schedule_day': updatedClass.day.trim(),
            'schedule_time': updatedClass.time.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.id!);
      await _loadClasses();
      widget.onRefresh();
      if (mounted) {
        _showMessage('${updatedClass.code} was updated successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage(formatSupabaseError(e));
      }
    }
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
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(LucideIcons.trash2, size: 17),
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

    if (item.isOfficial) {
      _showMessage(
        'Official instructor classes cannot be deleted by students.',
      );
      return;
    }

    if (item.id != null) {
      try {
        await ClassService.deletePersonalClass(item.id!);
        await _loadClasses();
        widget.onRefresh();
        if (mounted) {
          _showMessage('${item.code} was deleted.');
        }
      } catch (e) {
        if (mounted) {
          _showMessage(formatSupabaseError(e));
        }
      }
    }
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClasses;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ResponsiveContainer(
        maxWidth: 1024,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.md),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildSearchBar(),
            ),

            const SizedBox(height: 22),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildClassCount(filtered.length),
            ),

            if (_pendingEnrollments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Enrollment Requests (${_pendingEnrollments.length})',
                        style: const TextStyle(
                          color: AppColors.warningDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._pendingEnrollments.map((p) {
                        final cls = p['classes'] as Map<String, dynamic>?;
                        final code = (cls?['subject_code'] ?? '').toString();
                        final name = (cls?['class_name'] ?? 'Class').toString();
                        final section = (cls?['section'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '• ${code.isEmpty ? '' : '$code · '}$name${section.isEmpty ? '' : ' ($section)'} — Awaiting approval',
                            style: const TextStyle(
                              color: AppColors.warningDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _blue))
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: AsyncErrorView(
                          message: _error!,
                          onRetry: _loadClasses,
                        ),
                      ),
                    )
                  : filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: _blue,
                      onRefresh: _loadClasses,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 13),
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
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: AcademicPageHeader(
        eyebrow: 'LEARNING',
        title: 'My Courses',
        subtitle: '${_classes.length} enrolled subjects',
        actions: [_buildJoinClassButton()],
      ),
    );
  }

  Widget _buildJoinClassButton() {
    return FilledButton.icon(
      onPressed: _addClass,
      icon: const Icon(LucideIcons.plus, size: 16),
      label: const Text(
        'Join Class',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: const StadiumBorder(),
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
          const Icon(LucideIcons.search, color: _muted, size: 20),
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
                hintStyle: TextStyle(color: _muted, fontSize: 12),
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
              icon: const Icon(LucideIcons.x, color: _muted, size: 18),
            ),
        ],
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
                '$count ${count == 1 ? 'Course' : 'Courses'}',
                style: AppTextStyles.cardHeading,
              ),
              const SizedBox(height: 3),
              const Text('Your enrolled subjects', style: AppTextStyles.meta),
            ],
          ),
        ),
        const Icon(LucideIcons.graduationCap, color: _blue, size: 21),
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
        : 'Add your first class to start organizing your subjects.';

    return EmptyStateView(
      icon: LucideIcons.bookOpen,
      title: 'No courses found',
      message: message,
      actionLabel: hasSearch ? 'Clear search' : null,
      onAction: hasSearch ? _clearSearch : null,
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
  static const Color _darkBlue = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  ({ClassMeetingSchedule schedule, DateTime date})? _nextMeeting() {
    final now = DateTime.now();
    ({ClassMeetingSchedule schedule, DateTime date})? next;

    for (final schedule in item.effectiveSchedules) {
      final meeting = schedule.nextOccurrenceAfter(now);

      if (next == null || meeting.isBefore(next.date)) {
        next = (schedule: schedule, date: meeting);
      }
    }

    return next;
  }

  @override
  Widget build(BuildContext context) {
    final nextMeeting = _nextMeeting();
    final nextMeetingText = nextMeeting == null
        ? 'Schedule unavailable'
        : '${MaterialLocalizations.of(context).formatShortDate(nextMeeting.date)}, '
              '${nextMeeting.schedule.formattedTimeRange}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(classItem: item),
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
              const SizedBox(width: 14),

                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.bookOpen, color: _blue, size: 22),
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
                          crossAxisAlignment: WrapCrossAlignment.center,
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
                              LucideIcons.calendar,
                              size: 13,
                              color: _muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next meeting',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextMeetingText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                    LucideIcons.moreVertical,
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
                          Icon(LucideIcons.pencil, size: 18, color: _blue),
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
                            LucideIcons.trash2,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete class',
                            style: TextStyle(color: AppColors.danger),
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

  const _AddClassDialog({this.initialClass});

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;

  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _instructorController = TextEditingController();
  final _sectionController = TextEditingController();

  late List<ClassMeetingSchedule> _schedules;
  String? _scheduleError;

  bool get _isEditing => widget.initialClass != null;

  @override
  void initState() {
    super.initState();

    final existingClass = widget.initialClass;

    if (existingClass != null) {
      _codeController.text = existingClass.code;
      _nameController.text = existingClass.name;
      _instructorController.text =
          existingClass.instructor == 'Not specified' ||
              existingClass.instructor == 'Personal Course'
          ? ''
          : existingClass.instructor;
      _sectionController.text = existingClass.section;

      final parsed = existingClass.effectiveSchedules;
      _schedules = parsed.isNotEmpty
          ? List<ClassMeetingSchedule>.from(parsed)
          : const [
              ClassMeetingSchedule(
                dayOfWeek: 'Monday',
                startMinutes: 8 * 60,
                endMinutes: 10 * 60,
              ),
            ];
    } else {
      _schedules = const [
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 8 * 60,
          endMinutes: 10 * 60,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _instructorController.dispose();
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
    final formValid = _formKey.currentState?.validate() ?? false;
    final schedErr = ClassMeetingSchedule.validateSchedules(
      _schedules,
      requireAtLeastOne: true,
    );
    setState(() => _scheduleError = schedErr);
    if (!formValid || schedErr != null) return;

    final sorted = ClassMeetingSchedule.sortSchedules(_schedules);
    final roomSummary = ClassMeetingSchedule.encodeRoomSummary(sorted);
    final updatedClass = ClassItem(
      id: widget.initialClass?.id,
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      instructor: _instructorController.text.trim().isEmpty
          ? 'Not specified'
          : _instructorController.text.trim(),
      location: roomSummary.isEmpty ? 'Not specified' : roomSummary,
      day: ClassMeetingSchedule.encodeScheduleDay(sorted),
      time: ClassMeetingSchedule.encodeScheduleTime(sorted),
      schedules: sorted,
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
    final screenSize = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditing ? LucideIcons.pencil : LucideIcons.bookPlus,
                      color: _blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Update Course' : 'Create Course',
                          style: const TextStyle(
                            color: _darkBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'Update subject details and weekly meetings'
                              : 'Enter subject details and weekly meetings',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 18, color: _muted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        controller: _codeController,
                        label: 'Course code',
                        hint: 'e.g. CS 101',
                        icon: LucideIcons.hash,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _nameController,
                        label: 'Class name',
                        hint: 'e.g. Introduction to Programming',
                        icon: LucideIcons.bookOpen,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _sectionController,
                        label: 'Section',
                        hint: 'e.g. Section A or BSCS 3A',
                        icon: LucideIcons.users,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _instructorController,
                        label: 'Instructor',
                        hint: 'e.g. Prof. Santos',
                        icon: LucideIcons.userRound,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),
                      ClassScheduleEditor(
                        schedules: _schedules,
                        errorText: _scheduleError,
                        onChanged: (updated) {
                          setState(() {
                            _schedules = updated;
                            _scheduleError =
                                ClassMeetingSchedule.validateSchedules(
                                  updated,
                                  requireAtLeastOne: true,
                                );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _saveClass,
                    icon: Icon(
                      _isEditing ? LucideIcons.save : LucideIcons.plus,
                      size: 16,
                    ),
                    label: Text(_isEditing ? 'Save Changes' : 'Add Class'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      decoration: _decoration(label: label, hint: hint, icon: icon),
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
      labelStyle: const TextStyle(color: _muted, fontSize: 12),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      prefixIcon: Icon(icon, color: _blue, size: 18),
      filled: true,
      fillColor: AppColors.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
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
        borderSide: const BorderSide(color: _blue, width: 1.2),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
  }
}
