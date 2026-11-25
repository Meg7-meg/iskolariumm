part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - CLASS DETAIL SCREEN
// Clean blue and white academic interface
// ------------------------------------------------------------

class ClassDetailScreen extends StatefulWidget {
  final ClassItem classItem;

  const ClassDetailScreen({
    super.key,
    required this.classItem,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  int _selectedTabIndex = 0;

  late final TextEditingController _notesController;
  final List<_ClassNote> _savedNotes = [];

  // ---------- Tasks tab state ----------
  List<ClassAssignmentRecord> _assignments = const [];
  bool _assignmentsLoading = false;
  bool _assignmentsLoaded = false;

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadClassNotes();
  }

  Future<void> _loadClassNotes() async {
    final item = widget.classItem;
    if (item.id == null) return;
    try {
      final notes = await OrganizerService.getNotes(
        classId: item.isOfficial ? item.id : null,
        personalClassId: item.isOfficial ? null : item.id,
      );
      if (!mounted) return;
      setState(() {
        _savedNotes
          ..clear()
          ..addAll(
            notes.map(
              (n) => _ClassNote(
                id: n.id,
                text: n.content,
                createdAt: n.updatedAt,
              ),
            ),
          );
      });
    } catch (_) {}
  }

  Future<void> _loadAssignments() async {
    final item = widget.classItem;
    if (item.id == null || !item.isOfficial || _assignmentsLoading) return;
    if (mounted) setState(() => _assignmentsLoading = true);
    try {
      final list = await AcademicService.getClassAssignments(item.id!);
      if (!mounted) return;
      setState(() {
        _assignments = list;
        _assignmentsLoading = false;
        _assignmentsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assignmentsLoading = false;
        _assignmentsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClassNote() async {
    final noteText = _notesController.text.trim();

    if (noteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write a note before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final item = widget.classItem;
      final saved = await OrganizerService.createNote(
        classId: item.isOfficial ? item.id : null,
        personalClassId: item.isOfficial ? null : item.id,
        subjectLabel: '${item.code} - ${item.name}',
        content: noteText,
      );
      if (!mounted) return;
      setState(() {
        _savedNotes.insert(
          0,
          _ClassNote(
            id: saved.id,
            text: saved.content,
            createdAt: saved.updatedAt,
          ),
        );
        _notesController.clear();
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class note saved to Supabase.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatSupabaseError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteClassNote(int index) async {
    final note = _savedNotes[index];
    try {
      if (note.id != null) {
        await OrganizerService.deleteNote(note.id!);
      }
      if (!mounted) return;
      setState(() {
        _savedNotes.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note removed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatSupabaseError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.classItem;
    final progress = item.progress.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(item),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassHeader(item),

              const SizedBox(height: 20),

              _buildTabBar(),

              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildSelectedTab(
                  item,
                  progress,
                  progressPercent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // APP BAR
  // ------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(ClassItem item) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          LucideIcons.arrowLeft,
          color: _darkBlue,
          size: 21,
        ),
      ),
      titleSpacing: 0,
      title: const Text(
        'Class Details',
        style: TextStyle(
          color: _darkBlue,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            LucideIcons.ellipsis,
            color: _darkBlue,
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (value) {
            if (value == 'info') {
              _showClassInformation(item);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 17,
                    color: _darkBlue,
                  ),
                  SizedBox(width: 10),
                  Text('Class information'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ------------------------------------------------------------
  // CLASS HEADER
  // ------------------------------------------------------------

  Widget _buildClassHeader(ClassItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  item.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                LucideIcons.graduationCap,
                color: Colors.white,
                size: 25,
              ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                LucideIcons.userRound,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.instructor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.20),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _headerInformation(
                  LucideIcons.calendarDays,
                  item.scheduleSummary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _headerInformation(
                  LucideIcons.mapPin,
                  item.location,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInformation(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 15,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TAB BAR
  // ------------------------------------------------------------

  Widget _buildTabBar() {
    const tabs = [
      'Overview',
      'Tasks',
      'Notes',
    ];

    const icons = [
      LucideIcons.layoutDashboard,
      LucideIcons.clipboardList,
      LucideIcons.notebookPen,
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 14,
                      color: selected ? _blue : _muted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[index],
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
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------
  // SELECTED TAB CONTENT
  // ------------------------------------------------------------

  Widget _buildSelectedTab(
    ClassItem item,
    double progress,
    int progressPercent,
  ) {
    switch (_selectedTabIndex) {
      case 1:
        // Lazy-load assignments on first visit to the Tasks tab
        if (!_assignmentsLoaded && !_assignmentsLoading) {
          _loadAssignments();
        }
        return _buildTasksTab(item);

      case 2:
        return _buildNotesTab();

      default:
        return _buildOverviewTab(
          item,
          progress,
          progressPercent,
        );
    }
  }

  // ------------------------------------------------------------
  // OVERVIEW TAB
  // ------------------------------------------------------------

  Widget _buildOverviewTab(
    ClassItem item,
    double progress,
    int progressPercent,
  ) {
    return Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Instructor',
          'Your class instructor',
        ),

        const SizedBox(height: 12),

        _buildInstructorCard(item),

        const SizedBox(height: 22),

        _sectionTitle(
          'Class Information',
          'Your class schedule and location',
        ),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _informationCard(
                icon: LucideIcons.calendarDays,
                label: 'Schedule',
                value: item.scheduleMultiline,
                subtitle: item.effectiveSchedules.isEmpty
                    ? 'Class schedule'
                    : '${item.effectiveSchedules.length} weekly meeting${item.effectiveSchedules.length == 1 ? '' : 's'}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _informationCard(
                icon: LucideIcons.mapPin,
                label: 'Location',
                value: item.location,
                subtitle: 'Classroom',
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        _sectionTitle(
          'Course Progress',
          'Your learning progress',
        ),

        const SizedBox(height: 12),

        _buildProgressCard(progress, progressPercent),

        const SizedBox(height: 22),

        _sectionTitle(
          'Class Summary',
          'Important subject information',
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(item),
      ],
    );
  }

  // ------------------------------------------------------------
  // INSTRUCTOR CARD
  // ------------------------------------------------------------

  Widget _buildInstructorCard(ClassItem item) {
    final initials = item.instructor
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return _contentCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'IN' : initials,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLASS INSTRUCTOR',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.instructor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.userRound,
            color: _blue,
            size: 19,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMATION CARD
  // ------------------------------------------------------------

  Widget _informationCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return _contentCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Icon(
                icon,
                color: _blue,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

    // ------------------------------------------------------------
  // PROGRESS CARD
  // ------------------------------------------------------------

  Widget _buildProgressCard(
    double progress,
    int progressPercent,
  ) {
    final progressColor = progress >= 0.75
        ? AppColors.success
        : progress >= 0.40
            ? AppColors.warning
            : AppColors.info;

    return _contentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overall progress',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: _lightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                color: _blue,
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  progressPercent >= 100
                      ? 'You have completed the course progress.'
                      : 'Keep going and stay on track with your classes.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY CARD
  // ------------------------------------------------------------

  Widget _buildSummaryCard(ClassItem item) {
    return _contentCard(
      child: Column(
        children: [
          _summaryRow(
            LucideIcons.bookOpen,
            'Subject',
            item.name,
          ),
          const SizedBox(height: 15),
          _summaryRow(
            LucideIcons.hash,
            'Course code',
            item.code,
          ),
          const SizedBox(height: 15),
          _summaryRow(
            LucideIcons.userRound,
            'Instructor',
            item.instructor,
          ),
          const SizedBox(height: 15),
          _summaryRow(
            LucideIcons.mapPin,
            'Classroom',
            item.location,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              color: _blue,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TASKS TAB  — real data from class_assignments
  // ------------------------------------------------------------

  Widget _buildTasksTab(ClassItem item) {
    return Column(
      key: const ValueKey('tasks'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Class Assignments',
          'Tasks and activities published by your instructor',
        ),

        const SizedBox(height: 14),

        if (_assignmentsLoading)
          _contentCard(
            padding: const EdgeInsets.all(28),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (!item.isOfficial)
          _contentCard(
            padding: const EdgeInsets.all(24),
            child: const Text(
              'Assignments are only available for official instructor-led classes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          )
        else if (_assignments.isEmpty)
          _contentCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.clipboardList,
                      color: _blue,
                      size: 29,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No assignments yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your instructor hasn\'t published any assignments for this class yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          )
        else
          ..._assignments.map((a) => _buildAssignmentCard(a)),
      ],
    );
  }

  Widget _buildAssignmentCard(ClassAssignmentRecord a) {
    final now = DateTime.now();
    final bool isOverdue = a.dueAt != null && a.dueAt!.isBefore(now);
    final Color dueColor = isOverdue ? AppColors.danger : _muted;

    String dueLabel;
    if (a.dueAt == null) {
      dueLabel = 'No due date';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dueLabel =
          'Due ${months[a.dueAt!.month - 1]} ${a.dueAt!.day}, ${a.dueAt!.year}';
      if (isOverdue) dueLabel += ' · Overdue';
    }

    return _contentCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(LucideIcons.clipboardList, color: _blue, size: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _lightBlue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        a.category,
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (a.maxScore != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${a.maxScore!.toStringAsFixed(0)} pts',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  a.title,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (a.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    a.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.clock, color: dueColor, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      dueLabel,
                      style: TextStyle(
                        color: dueColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTES TAB
  // ------------------------------------------------------------

  Widget _buildNotesTab() {
    return Column(
      key: const ValueKey('notes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Class Notes',
          'Keep useful reminders and important points for this subject',
        ),

        const SizedBox(height: 14),

        _contentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.notebookPen,
                    color: _blue,
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Write a note',
                      style: TextStyle(
                        color: _darkBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _notesController,
                maxLines: 8,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 13,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Write your class notes here...\n\nExample:\n• Important topics\n• Things to review\n• Questions to ask your instructor',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: _blue,
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveClassNote,
                  icon: const Icon(
                    Icons.save_outlined,
                    size: 16,
                  ),
                  label: const Text('Save Note'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    color: _muted,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Notes are kept temporarily while this screen remains open. They are not permanently stored.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        _sectionTitle(
          'Saved Notes',
          '${_savedNotes.length} ${_savedNotes.length == 1 ? 'note' : 'notes'} in this session',
        ),

        const SizedBox(height: 12),

        if (_savedNotes.isEmpty)
          _contentCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.sticky_note_2_outlined,
                    color: _blue,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No saved notes yet',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your saved class notes will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            _savedNotes.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSavedNoteCard(
                _savedNotes[index],
                index,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSavedNoteCard(_ClassNote note, int index) {
    final date = note.createdAt;
    final timestamp =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return _contentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                color: _blue,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Class note ${_savedNotes.length - index}',
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete note',
                visualDensity: VisualDensity.compact,
                onPressed: () => _deleteClassNote(index),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 17,
                ),
              ),
            ],
          ),
          Text(
            note.text,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Saved $timestamp',
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SHARED SECTION TITLE
  // ------------------------------------------------------------

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _darkBlue,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SHARED CONTENT CARD
  // ------------------------------------------------------------

  Widget _contentCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _darkBlue.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // CLASS INFORMATION POPUP
  // ------------------------------------------------------------

  void _showClassInformation(ClassItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Class Information',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 18),

                _summaryRow(
                  LucideIcons.bookOpen,
                  'Subject',
                  item.name,
                ),

                const SizedBox(height: 15),

                _summaryRow(
                  LucideIcons.hash,
                  'Course code',
                  item.code,
                ),

                const SizedBox(height: 15),

                _summaryRow(
                  LucideIcons.calendarDays,
                  'Schedule',
                  item.scheduleMultiline,
                ),

                const SizedBox(height: 15),

                _summaryRow(
                  LucideIcons.mapPin,
                  'Location',
                  item.location,
                ),

                const SizedBox(height: 15),

                _summaryRow(
                  LucideIcons.userRound,
                  'Instructor',
                  item.instructor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// TEMPORARY CLASS NOTE MODEL
// ------------------------------------------------------------

class _ClassNote {
  final String? id;
  final String text;
  final DateTime createdAt;

  const _ClassNote({
    this.id,
    required this.text,
    required this.createdAt,
  });
}