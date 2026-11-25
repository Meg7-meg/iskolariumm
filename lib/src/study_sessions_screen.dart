
part of '../main.dart';

// ============================================================
// ISKOLARIUM - STUDY SESSIONS
// Modern Blue & White Study Planner
// ============================================================

class StudySession {
  String? id;
  String title;
  String subject;
  String description;
  DateTime date;
  TimeOfDay time;
  int duration;
  bool isCompleted;

  StudySession({
    this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.date,
    required this.time,
    required this.duration,
    this.isCompleted = false,
  });

  DateTime get startDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
}

class StudySessionsPage extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const StudySessionsPage({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<StudySessionsPage> createState() => _StudySessionsPageState();
}

class _StudySessionsPageState extends State<StudySessionsPage> {
  static const Color _blue = Color(0xFF1A56DB);
  static const Color _darkBlue = Color(0xFF10213D);
  static const Color _muted = Color(0xFF71809B);
  static const Color _background = Color(0xFFF4F7FD);
  static const Color _lightBlue = Color(0xFFEDF3FF);
  static const Color _border = Color(0xFFE2EAF7);
  static const Color _green = Color(0xFF239B69);

  final List<StudySession> _sessions = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final records = await OrganizerService.getStudySessions();
      if (!mounted) return;
      setState(() {
        _sessions
          ..clear()
          ..addAll(
            records.map((r) {
              final parts = r.startTime.split(':');
              final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;
              final minute =
                  parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
              return StudySession(
                id: r.id,
                title: r.title,
                subject: r.subject,
                description: r.description,
                date: r.sessionDate,
                time: TimeOfDay(hour: hour, minute: minute),
                duration: r.durationMinutes,
                isCompleted: r.isCompleted,
              );
            }),
          );
      });
    } catch (_) {}
  }

  List<StudySession> get _filteredSessions {
    final filtered = _sessions.where((session) {
      if (_selectedFilter == 'Completed') {
        return session.isCompleted;
      }

      if (_selectedFilter == 'Upcoming') {
        return !session.isCompleted;
      }

      return true;
    }).toList();

    filtered.sort(
      (a, b) => a.startDateTime.compareTo(b.startDateTime),
    );

    return filtered;
  }

  int get _completedCount =>
      _sessions.where((s) => s.isCompleted).length;

  int get _upcomingCount =>
      _sessions.where((s) => !s.isCompleted).length;

  int get _totalStudyMinutes => _sessions.fold(
        0,
        (total, session) =>
            total + (session.isCompleted ? session.duration : 0),
      );

  double get _completionRate =>
      _sessions.isEmpty ? 0 : _completedCount / _sessions.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildBackBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 125),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildSummary(),
                  const SizedBox(height: 30),
                  _buildSectionHeader(),
                  const SizedBox(height: 15),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  _buildSessionList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GlassNavigationIsland(
        selectedIndex: 0,
        onItemSelected: widget.onNavigateToTab,
      ),
    );
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget _buildBackBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 22, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: _darkBlue,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'STUDY TOOLS',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Sessions',
                style: TextStyle(
                  color: _darkBlue,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Make time for focused learning.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: _blue,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _showAddSessionDialog,
            borderRadius: BorderRadius.circular(15),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10213D),
            Color(0xFF183968),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: _darkBlue.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.chartNoAxesCombined,
                color: Color(0xFFA8C5FF),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'YOUR STUDY OVERVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'MY PROGRESS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  LucideIcons.bookOpen,
                  '${_sessions.length}',
                  'Total sessions',
                ),
              ),
              _summaryDivider(),
              Expanded(
                child: _summaryItem(
                  LucideIcons.checkCircle,
                  '$_completedCount',
                  'Completed',
                ),
              ),
              _summaryDivider(),
              Expanded(
                child: _summaryItem(
                  LucideIcons.clock,
                  _formatDuration(_totalStudyMinutes),
                  'Study time',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completion progress',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Text(
                '${(_completionRate * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _completionRate,
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF80ACFF),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            _sessions.isEmpty
                ? 'Start planning your first study session.'
                : '$_completedCount out of ${_sessions.length} sessions completed',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFA8C5FF), size: 18),
        const SizedBox(height: 11),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 65,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white24,
    );
  }

  // ============================================================
  // STUDY PLAN HEADER
  // ============================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text(
            'My Study Plan',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_upcomingCount upcoming',
            style: const TextStyle(
              color: _blue,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    const filters = ['All', 'Upcoming', 'Completed'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _blue.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: selected ? Colors.white : _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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

  // ============================================================
  // SESSION LIST
  // ============================================================

  Widget _buildSessionList() {
    final sessions = _filteredSessions;

    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: sessions.map((session) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: _sessionCard(session),
        );
      }).toList(),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final completed = _selectedFilter == 'Completed';
    final upcoming = _selectedFilter == 'Upcoming';

    final title = completed
        ? 'No completed sessions yet'
        : upcoming
            ? 'No upcoming sessions'
            : 'Your study plan is empty';

    final description = completed
        ? 'Your completed study activities will appear here.'
        : upcoming
            ? 'Plan your next learning activity to stay organized.'
            : 'Create your first study session and start organizing your learning time.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: _lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed
                  ? LucideIcons.checkCheck
                  : LucideIcons.calendarDays,
              color: _blue,
              size: 30,
            ),
          ),
          const SizedBox(height: 19),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.6,
            ),
          ),
          if (!completed) ...[
            const SizedBox(height: 23),
            ElevatedButton.icon(
              onPressed: _showAddSessionDialog,
              icon: const Icon(LucideIcons.plus, size: 17),
              label: const Text('Create study session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SESSION CARD
  // ============================================================

  Widget _sessionCard(StudySession session) {
    final completed = session.isCompleted;
    final accent = completed ? _green : _blue;
    final accentBackground =
        completed ? const Color(0xFFEAF8F1) : _lightBlue;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _darkBlue.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed
                      ? LucideIcons.checkCheck
                      : LucideIcons.bookOpen,
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: completed ? _muted : _darkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      session.subject,
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
              PopupMenuButton<String>(
                icon: const Icon(
                  LucideIcons.ellipsis,
                  color: _muted,
                  size: 21,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditSessionDialog(session);
                  } else if (value == 'delete') {
                    _deleteSession(session);
                  } else if (value == 'toggle') {
                    _toggleCompleted(session);
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
                        Text('Edit session'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          completed
                              ? LucideIcons.rotateCcw
                              : LucideIcons.checkCircle,
                          size: 17,
                          color: _green,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          completed
                              ? 'Mark as upcoming'
                              : 'Mark as completed',
                        ),
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
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete session',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (session.description.trim().isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              session.description,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: _border),
          const SizedBox(height: 14),
          Wrap(
            spacing: 17,
            runSpacing: 11,
            children: [
              _sessionDetail(
                LucideIcons.calendarDays,
                _formatDate(session.date),
              ),
              _sessionDetail(
                LucideIcons.clock,
                _formatTime(session.time),
              ),
              _sessionDetail(
                LucideIcons.timer,
                '${session.duration} min',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  completed ? 'COMPLETED' : 'UPCOMING',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (!completed)
                TextButton(
                  onPressed: () => _toggleCompleted(session),
                  child: const Text(
                    'Complete session',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionDetail(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD SESSION
  // ============================================================

  Future<void> _showAddSessionDialog() async {
    await _showSessionDialog();
  }

  // ============================================================
  // EDIT SESSION
  // ============================================================

  Future<void> _showEditSessionDialog(StudySession session) async {
    await _showSessionDialog(session: session);
  }

  // ============================================================
  // ADD / EDIT SESSION DIALOG
  // ============================================================

  Future<void> _showSessionDialog({
    StudySession? session,
  }) async {
    final isEditing = session != null;

    final titleController = TextEditingController(
      text: session?.title ?? '',
    );

    final subjectController = TextEditingController(
      text: session?.subject ?? '',
    );

    final descriptionController = TextEditingController(
      text: session?.description ?? '',
    );

    DateTime selectedDate = session?.date ?? DateTime.now();
    TimeOfDay selectedTime = session?.time ?? TimeOfDay.now();
    int selectedDuration = session?.duration ?? 60;

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: _lightBlue,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                isEditing
                                    ? LucideIcons.pencil
                                    : LucideIcons.bookOpen,
                                color: _blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Edit Study Session'
                                        : 'New Study Session',
                                    style: const TextStyle(
                                      color: _darkBlue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEditing
                                        ? 'Update your study plan details'
                                        : 'Plan your next learning activity',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext),
                              icon: const Icon(
                                LucideIcons.x,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _dialogLabel('SESSION TITLE'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: titleController,
                          decoration: _inputDecoration(
                            'e.g. Review Chapter 3',
                            LucideIcons.book,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a session title.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 17),
                        _dialogLabel('SUBJECT'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: subjectController,
                          decoration: _inputDecoration(
                            'e.g. Data Science',
                            LucideIcons.graduationCap,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a subject.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 17),
                        _dialogLabel('STUDY GOAL / DESCRIPTION'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            'What do you want to accomplish?',
                            LucideIcons.notebookPen,
                          ),
                        ),

                        const SizedBox(height: 20),
                        _dialogLabel('DATE AND TIME'),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: _pickerButton(
                                icon: LucideIcons.calendarDays,
                                label: _formatDate(selectedDate),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _pickerButton(
                                icon: LucideIcons.clock,
                                label: _formatTime(selectedTime),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: dialogContext,
                                    initialTime: selectedTime,
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedTime = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _dialogLabel('STUDY DURATION'),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<int>(
                          value: selectedDuration,
                          decoration: _inputDecoration(
                            'Select duration',
                            LucideIcons.timer,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          items: const [
                            DropdownMenuItem(
                              value: 25,
                              child: Text('25 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('30 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 45,
                              child: Text('45 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 60,
                              child: Text('1 hour'),
                            ),
                            DropdownMenuItem(
                              value: 90,
                              child: Text('1 hour 30 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 120,
                              child: Text('2 hours'),
                            ),
                            DropdownMenuItem(
                              value: 180,
                              child: Text('3 hours'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedDuration = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final timeStr =
                                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                                  try {
                                    if (isEditing && session.id != null) {
                                      await OrganizerService.updateStudySession(
                                        id: session.id!,
                                        title: titleController.text.trim(),
                                        subject: subjectController.text.trim(),
                                        description:
                                            descriptionController.text.trim(),
                                        sessionDate: selectedDate,
                                        startTime: timeStr,
                                        durationMinutes: selectedDuration,
                                      );
                                    } else {
                                      await OrganizerService.createStudySession(
                                        title: titleController.text.trim(),
                                        subject: subjectController.text.trim(),
                                        description:
                                            descriptionController.text.trim(),
                                        sessionDate: selectedDate,
                                        startTime: timeStr,
                                        durationMinutes: selectedDuration,
                                      );
                                    }

                                    await _loadSessions();
                                    if (!mounted) return;
                                    setState(() => _selectedFilter = 'All');
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing
                                              ? 'Study session updated successfully.'
                                              : 'Study session created successfully.',
                                        ),
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
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isEditing ? 'Save Changes' : 'Save Session',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      subjectController.dispose();
      descriptionController.dispose();
    }
  }

  // ============================================================
  // DIALOG HELPERS
  // ============================================================

  Widget _dialogLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _muted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9AAAC2),
        fontSize: 11,
      ),
      prefixIcon: Icon(icon, color: _muted, size: 17),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: _blue,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Icon(icon, color: _blue, size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SESSION ACTIONS
  // ============================================================

  Future<void> _toggleCompleted(StudySession session) async {
    final next = !session.isCompleted;
    setState(() {
      session.isCompleted = next;
    });

    if (session.id != null) {
      try {
        await OrganizerService.toggleStudySessionCompleted(session.id!, next);
      } catch (e) {
        if (mounted) {
          setState(() => session.isCompleted = !next);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(formatSupabaseError(e))),
          );
          return;
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          session.isCompleted
              ? 'Study session marked as completed.'
              : 'Study session moved back to upcoming.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteSession(StudySession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          title: const Text(
            'Delete study session?',
            style: TextStyle(
              color: _darkBlue,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          content: const Text(
            'This study session will be permanently removed from your list.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      if (session.id != null) {
        try {
          await OrganizerService.deleteStudySession(session.id!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(formatSupabaseError(e))),
            );
          }
          return;
        }
      }

      setState(() {
        _sessions.remove(session);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study session deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // FORMATTING HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';

    return '${hours}h ${remainingMinutes}m';
  }
}
