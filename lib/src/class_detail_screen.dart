part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - CLASS DETAIL SCREEN
// Clean blue and white academic interface
// ------------------------------------------------------------

class ClassDetailScreen extends StatefulWidget {
  final ClassItem classItem;
  final int initialTab;
  final OfficialClassRecord? instructorClassRecord;
  final int activityCount;
  final int attendanceCount;
  final VoidCallback? onManageStudents;
  final VoidCallback? onManageAttendance;
  final VoidCallback? onManageActivities;
  final VoidCallback? onEnterScores;
  final VoidCallback? onCopyJoinCode;
  final VoidCallback? onManageAnnouncements;
  final Future<void> Function()? onOpenAttendanceHistory;
  final Future<void> Function(AttendanceSessionRecord)? onOpenAttendanceSession;

  const ClassDetailScreen({
    super.key,
    required this.classItem,
    this.initialTab = 0,
    this.instructorClassRecord,
    this.activityCount = 0,
    this.attendanceCount = 0,
    this.onManageStudents,
    this.onManageAttendance,
    this.onManageActivities,
    this.onEnterScores,
    this.onCopyJoinCode,
    this.onManageAnnouncements,
    this.onOpenAttendanceHistory,
    this.onOpenAttendanceSession,
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

  List<AnnouncementRecord> _announcements = const [];
  bool _announcementsLoading = false;
  bool _announcementsLoaded = false;
  late Future<_InstructorClassDetailsData>? _instructorDetailsFuture;

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab.clamp(0, 3);
    _notesController = TextEditingController();
    final instructorRecord = widget.instructorClassRecord;
    if (instructorRecord != null) {
      _instructorDetailsFuture = _loadInstructorDetails(instructorRecord.id);
    } else {
      _instructorDetailsFuture = null;
      _loadClassNotes();
    }
  }

  Future<_InstructorClassDetailsData> _loadInstructorDetails(
    String classId,
  ) async {
    final assignments = await AcademicService.getClassAssignments(classId);
    final quizzes = await AcademicService.getClassQuizzes(classId);
    final announcements = await AcademicService.getClassAnnouncements(classId);
    List<AttendanceSessionRecord> attendanceSessions = const [];
    String? attendanceSessionsError;
    try {
      attendanceSessions = await AcademicService.getClassAttendanceSessions(
        classId,
      );
    } catch (error) {
      attendanceSessionsError = formatSupabaseError(error);
    }
    return _InstructorClassDetailsData(
      assignments: assignments,
      quizzes: quizzes,
      announcements: announcements,
      attendanceSessions: attendanceSessions,
      attendanceSessionsError: attendanceSessionsError,
    );
  }

  Future<void> _openAttendanceHistory({
    AttendanceSessionRecord? session,
  }) async {
    if (session != null) {
      await widget.onOpenAttendanceSession?.call(session);
    } else {
      await widget.onOpenAttendanceHistory?.call();
    }
    final record = widget.instructorClassRecord;
    if (mounted && record != null) {
      setState(() {
        _instructorDetailsFuture = _loadInstructorDetails(record.id);
      });
    }
  }

  Future<void> _loadAnnouncements() async {
    final item = widget.classItem;
    if (item.id == null || !item.isOfficial || _announcementsLoading) return;
    if (mounted) setState(() => _announcementsLoading = true);
    try {
      final list = await AcademicService.getClassAnnouncements(item.id!);
      if (!mounted) return;
      setState(() {
        _announcements = list;
        _announcementsLoading = false;
        _announcementsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _announcementsLoading = false;
        _announcementsLoaded = true;
      });
    }
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
              (n) =>
                  _ClassNote(id: n.id, text: n.content, createdAt: n.updatedAt),
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
    final instructorClass = widget.instructorClassRecord;
    if (instructorClass != null) {
      return _buildInstructorScreen(item, instructorClass);
    }

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
                child: _buildSelectedTab(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorScreen(ClassItem item, OfficialClassRecord record) {
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
              const SizedBox(height: 22),
              FutureBuilder<_InstructorClassDetailsData>(
                future: _instructorDetailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _contentCard(
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _contentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Class details could not be loaded.',
                            style: TextStyle(
                              color: _darkBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatSupabaseError(snapshot.error!),
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _instructorDetailsFuture =
                                    _loadInstructorDetails(record.id);
                              });
                            },
                            icon: const Icon(LucideIcons.refreshCw, size: 15),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (data == null) return const SizedBox.shrink();
                  return _buildInstructorSections(record, data);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorSections(
    OfficialClassRecord record,
    _InstructorClassDetailsData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Class Overview',
          'Course, section, schedule, and location',
        ),
        const SizedBox(height: 12),
        _contentCard(
          child: Column(
            children: [
              _summaryRow(LucideIcons.bookOpen, 'Subject', record.className),
              const SizedBox(height: 14),
              _summaryRow(LucideIcons.hash, 'Subject code', record.subjectCode),
              const SizedBox(height: 14),
              _summaryRow(LucideIcons.users, 'Section', record.section),
              if (record.program.isNotEmpty) ...[
                const SizedBox(height: 14),
                _summaryRow(
                  LucideIcons.graduationCap,
                  'Program',
                  record.program,
                ),
              ],
              const SizedBox(height: 14),
              _summaryRow(
                LucideIcons.calendarDays,
                'Schedule',
                record.scheduleMultiline,
              ),
              const SizedBox(height: 14),
              _summaryRow(LucideIcons.mapPin, 'Room', record.roomSummary),
              if (record.enrollmentCode.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Enrollment code',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        record.enrollmentCode,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: _darkBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.onCopyJoinCode != null)
                      IconButton(
                        tooltip: 'Copy enrollment code',
                        onPressed: widget.onCopyJoinCode,
                        icon: const Icon(LucideIcons.copy, size: 16),
                        color: _blue,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle('Students', 'Enrollment and requests'),
        const SizedBox(height: 12),
        _contentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(
                LucideIcons.users,
                'Enrolled students',
                record.approvedStudentCount.toString(),
              ),
              const SizedBox(height: 14),
              _summaryRow(
                LucideIcons.userRoundCheck,
                'Pending requests',
                record.pendingRequestCount.toString(),
              ),
              if (widget.onManageStudents != null) ...[
                const SizedBox(height: 12),
                _instructorActionButton(
                  icon: LucideIcons.userPlus,
                  label: 'Manage students',
                  onPressed: widget.onManageStudents,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle('Attendance', 'Attendance activity for this class'),
        const SizedBox(height: 12),
        _contentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(
                LucideIcons.clipboardCheck,
                'Records today',
                widget.attendanceCount.toString(),
              ),
              if (widget.onManageAttendance != null) ...[
                const SizedBox(height: 12),
                _instructorActionButton(
                  icon: LucideIcons.clipboardCheck,
                  label: 'Open attendance',
                  onPressed: widget.onManageAttendance,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle(
          'Attendance History',
          'Saved sessions and previous meeting records',
        ),
        const SizedBox(height: 12),
        _contentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.attendanceSessionsError != null) ...[
                const Text(
                  'Attendance history could not be loaded.',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.attendanceSessionsError!,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ] else if (data.attendanceSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No attendance sessions have been saved for this class.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                )
              else
                ...data.attendanceSessions
                    .take(3)
                    .map(_instructorAttendanceSessionRow),
              if (widget.onOpenAttendanceHistory != null) ...[
                const SizedBox(height: 8),
                _instructorActionButton(
                  icon: LucideIcons.history,
                  label: 'View attendance history',
                  onPressed: _openAttendanceHistory,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle(
          'Tasks & Quizzes',
          '${widget.activityCount} activities in this class',
        ),
        const SizedBox(height: 12),
        _contentCard(
          child: Column(
            children: [
              if (data.assignments.isEmpty && data.quizzes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tasks or quizzes yet.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ...data.assignments.map(
                (assignment) => _instructorActivityRow(
                  icon: LucideIcons.fileText,
                  title: assignment.title,
                  subtitle: assignment.dueAt == null
                      ? assignment.category
                      : '${assignment.category} · Due ${_shortDate(assignment.dueAt!)}',
                ),
              ),
              ...data.quizzes.map(
                (quiz) => _instructorActivityRow(
                  icon: LucideIcons.clipboardList,
                  title: quiz.title,
                  subtitle: quiz.closesAt == null
                      ? 'Quiz'
                      : 'Quiz · Closes ${_shortDate(quiz.closesAt!)}',
                ),
              ),
              if (widget.onManageActivities != null ||
                  widget.onEnterScores != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.onManageActivities != null)
                      OutlinedButton.icon(
                        onPressed: widget.onManageActivities,
                        icon: const Icon(LucideIcons.filePlus2, size: 15),
                        label: const Text('Manage tasks'),
                      ),
                    if (widget.onEnterScores != null)
                      OutlinedButton.icon(
                        onPressed: widget.onEnterScores,
                        icon: const Icon(LucideIcons.award, size: 15),
                        label: const Text('Enter scores'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle('Announcements', 'Updates for this class'),
        const SizedBox(height: 12),
        _contentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.announcements.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No announcements for this class.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                )
              else
                ...data.announcements.map(
                  (announcement) => _instructorActivityRow(
                    icon: LucideIcons.megaphone,
                    title: announcement.title,
                    subtitle:
                        '${announcement.instructorName} · ${_shortDate(announcement.createdAt)}',
                    description: announcement.content,
                  ),
                ),
              if (widget.onManageAnnouncements != null) ...[
                const SizedBox(height: 10),
                _instructorActionButton(
                  icon: LucideIcons.megaphone,
                  label: 'Manage announcements',
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onManageAnnouncements?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _instructorAttendanceSessionRow(AttendanceSessionRecord session) {
    final label = session.meetingLabel.isEmpty
        ? _shortDate(session.sessionDate)
        : session.meetingLabel;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _lightBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.history, color: _blue, size: 16),
      ),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _darkBlue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        _shortDate(session.sessionDate),
        style: const TextStyle(color: _muted, fontSize: 10),
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: _muted, size: 16),
      onTap: widget.onOpenAttendanceSession == null
          ? null
          : () => _openAttendanceHistory(session: session),
    );
  }

  Widget _instructorActivityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _blue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructorActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }

  String _shortDate(DateTime date) {
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
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
        icon: const Icon(LucideIcons.arrowLeft, color: _darkBlue, size: 21),
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
          icon: const Icon(LucideIcons.ellipsis, color: _darkBlue),
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
                  Icon(LucideIcons.info, size: 17, color: _darkBlue),
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
        color: AppColors.navy,
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

          Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),

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
                child: _headerInformation(LucideIcons.mapPin, item.location),
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
        Icon(icon, color: Colors.white70, size: 15),
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
    const tabs = ['Details', 'Assignments', 'Announcements', 'Notes'];

    const icons = [
      LucideIcons.layoutDashboard,
      LucideIcons.clipboardList,
      LucideIcons.megaphone,
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
                  border: selected ? Border.all(color: _border) : null,
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

  Widget _buildSelectedTab(ClassItem item) {
    switch (_selectedTabIndex) {
      case 1:
        // Lazy-load assignments on first visit to the Tasks tab
        if (!_assignmentsLoaded && !_assignmentsLoading) {
          _loadAssignments();
        }
        return _buildTasksTab(item);

      case 2:
        if (!_announcementsLoaded && !_announcementsLoading) {
          _loadAnnouncements();
        }
        return _buildAnnouncementsTab(item);

      case 3:
        return _buildNotesTab();

      default:
        return _buildOverviewTab(item);
    }
  }

  // ------------------------------------------------------------
  // OVERVIEW TAB
  // ------------------------------------------------------------

  Widget _buildOverviewTab(ClassItem item) {
    return Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Instructor', 'Your class instructor'),

        const SizedBox(height: 12),

        _buildInstructorCard(item),

        const SizedBox(height: 22),

        _sectionTitle('Class Information', 'Your class schedule and location'),

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

        _sectionTitle('Class Summary', 'Important subject information'),

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
          const Icon(LucideIcons.userRound, color: _blue, size: 19),
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
            child: Center(child: Icon(icon, color: _blue, size: 18)),
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
            style: const TextStyle(color: _muted, fontSize: 10),
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
          _summaryRow(LucideIcons.bookOpen, 'Subject', item.name),
          const SizedBox(height: 15),
          _summaryRow(LucideIcons.hash, 'Course code', item.code),
          const SizedBox(height: 15),
          _summaryRow(LucideIcons.userRound, 'Instructor', item.instructor),
          const SizedBox(height: 15),
          _summaryRow(LucideIcons.mapPin, 'Classroom', item.location),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: _blue, size: 15)),
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
  // ANNOUNCEMENTS TAB
  // ------------------------------------------------------------

  Widget _buildAnnouncementsTab(ClassItem item) {
    return Column(
      key: const ValueKey('announcements'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Announcements',
          'Updates published by your class instructor',
        ),
        const SizedBox(height: 14),
        if (_announcementsLoading)
          _contentCard(
            padding: const EdgeInsets.all(28),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (!item.isOfficial)
          _contentCard(
            padding: const EdgeInsets.all(24),
            child: const Text(
              'Announcements are available for official instructor-led classes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          )
        else if (_announcements.isEmpty)
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
                  child: const Icon(
                    LucideIcons.megaphone,
                    color: _blue,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No announcements',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your instructor has not published any updates yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.6),
                ),
              ],
            ),
          )
        else
          ..._announcements.map(_buildAnnouncementCard),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementRecord announcement) {
    final date = announcement.createdAt.toLocal();
    final timestamp =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _contentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.megaphone,
                    color: _blue,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          color: _darkBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posted by ${announcement.instructorName.isEmpty ? 'Instructor' : announcement.instructorName}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement.content,
              style: const TextStyle(
                color: _darkBlue,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 12, color: _muted),
                const SizedBox(width: 5),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
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
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.6),
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
                        horizontal: 7,
                        vertical: 2,
                      ),
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
                  Icon(LucideIcons.notebookPen, color: _blue, size: 19),
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
                  hintText: 'Write your class notes here...\n\nExample:\n• Important topics\n• Things to review\n• Questions to ask your instructor',
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
                    borderSide: const BorderSide(color: _blue, width: 1.2),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveClassNote,
                  icon: const Icon(LucideIcons.save, size: 16),
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
                  Icon(LucideIcons.info, color: _muted, size: 14),
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
                    LucideIcons.stickyNote,
                    color: _blue,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No saved notes',
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
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            _savedNotes.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSavedNoteCard(_savedNotes[index], index),
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
              const Icon(LucideIcons.notebookPen, color: _blue, size: 17),
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
                  LucideIcons.trash2,
                  color: AppColors.danger,
                  size: 17,
                ),
              ),
            ],
          ),
          Text(
            note.text,
            style: const TextStyle(color: _darkBlue, fontSize: 12, height: 1.6),
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

  Widget _sectionTitle(String title, String subtitle) {
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
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 10)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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

                _summaryRow(LucideIcons.bookOpen, 'Subject', item.name),

                const SizedBox(height: 15),

                _summaryRow(LucideIcons.hash, 'Course code', item.code),

                const SizedBox(height: 15),

                _summaryRow(
                  LucideIcons.calendarDays,
                  'Schedule',
                  item.scheduleMultiline,
                ),

                const SizedBox(height: 15),

                _summaryRow(LucideIcons.mapPin, 'Location', item.location),

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

class _InstructorClassDetailsData {
  final List<ClassAssignmentRecord> assignments;
  final List<QuizRecord> quizzes;
  final List<AnnouncementRecord> announcements;
  final List<AttendanceSessionRecord> attendanceSessions;
  final String? attendanceSessionsError;

  const _InstructorClassDetailsData({
    required this.assignments,
    required this.quizzes,
    required this.announcements,
    required this.attendanceSessions,
    required this.attendanceSessionsError,
  });
}

class _ClassNote {
  final String? id;
  final String text;
  final DateTime createdAt;

  const _ClassNote({this.id, required this.text, required this.createdAt});
}
