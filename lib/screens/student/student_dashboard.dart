
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../main.dart' show ClassDetailScreen, ClassItem;
import '../../services/academic_service.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../services/organizer_service.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';

// ============================================================
// ISKOLARIUM - STUDENT DASHBOARD
// ============================================================

class StudentDashboard extends StatefulWidget {
  final VoidCallback onOpenClasses;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenStudySessions;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenScores;
  final VoidCallback onRefresh;

  const StudentDashboard({
    super.key,
    required this.onOpenClasses,
    required this.onOpenTasks,
    required this.onOpenNotifications,
    required this.onOpenStudySessions,
    required this.onOpenAttendance,
    required this.onOpenScores,
    required this.onRefresh,
  });

  // Shared application color palette.
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.navy;
  static const Color navy = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color background = AppColors.background;
  static const Color border = AppColors.border;
  static const Color lightBlue = AppColors.primaryLight;

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  static const Color primaryBlue = StudentDashboard.primaryBlue;
  static const Color navy = StudentDashboard.navy;
  static const Color muted = StudentDashboard.muted;
  static const Color border = StudentDashboard.border;

  String _studentName = 'Student';
  int _classCount = 0;
  int _tasksDueCount = 0;
  int _attendancePercent = 0;
  int _unreadNotifications = 0;
  List<_TodayMeetingEntry> _todayClasses = const [];
  StudentTaskRecord? _nextDeadline;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final profile = await AuthService.getCurrentProfile();
      final official = await ClassService.getStudentApprovedClasses();
      final personal = await ClassService.getStudentPersonalClasses();
      final tasks = await OrganizerService.getTasks();
      final attendance = await AcademicService.getStudentAttendance();
      final notifications = await OrganizerService.getNotifications();

      final todayWeekday = DateTime.now().weekday;

      final todayRows = <_TodayMeetingEntry>[];
      for (final c in official) {
        final meetings = c.effectiveSchedules
            .where((m) => m.weekday == todayWeekday)
            .toList();
        if (meetings.isNotEmpty) {
          final classItem = ClassItem(
            id: c.id,
            code: c.subjectCode.isEmpty ? 'CLASS' : c.subjectCode,
            name: c.className,
            instructor: c.instructorName,
            location: c.roomSummary,
            day: c.scheduleDay.isEmpty ? 'TBA' : c.scheduleDay,
            time: c.scheduleTime.isEmpty ? 'TBA' : c.scheduleTime,
            schedules: c.effectiveSchedules,
            progress: 1.0,
            section: c.section,
            isOfficial: true,
            enrollmentCode: c.enrollmentCode,
            description: c.description,
          );
          for (final m in meetings) {
            final room = m.room.trim().isNotEmpty
                ? m.room.trim()
                : (c.room.trim().isEmpty ? 'Room TBA' : c.room.trim());
            todayRows.add(
              _TodayMeetingEntry(
                classItem: classItem,
                subjectCode: c.subjectCode.isEmpty ? 'CLASS' : c.subjectCode,
                subjectName: c.className,
                startMinutes: m.startMinutes,
                endMinutes: m.endMinutes,
                startTimeLabel: m.formattedStartTime,
                endTimeLabel: m.formattedEndTime,
                room: room,
                instructor: c.instructorName,
              ),
            );
          }
        }
      }
      for (final p in personal) {
        final meetings = p.schedules
            .where((m) => m.weekday == todayWeekday)
            .toList();
        if (meetings.isNotEmpty) {
          final instructorLabel =
              p.instructorName.isEmpty ? 'Personal Class' : p.instructorName;
          final classItem = ClassItem(
            id: p.id,
            code: p.subjectCode,
            name: p.className,
            instructor: instructorLabel,
            location: p.location.isEmpty ? 'Personal' : p.location,
            day: p.scheduleDay.isEmpty ? 'Flexible' : p.scheduleDay,
            time: p.scheduleTime.isEmpty ? 'Flexible' : p.scheduleTime,
            schedules: p.schedules,
            progress: 1.0,
            section: p.section,
            isOfficial: false,
          );
          for (final m in meetings) {
            final room = m.room.trim().isNotEmpty
                ? m.room.trim()
                : (p.location.trim().isEmpty
                    ? 'Personal'
                    : p.location.trim());
            todayRows.add(
              _TodayMeetingEntry(
                classItem: classItem,
                subjectCode: p.subjectCode,
                subjectName: p.className,
                startMinutes: m.startMinutes,
                endMinutes: m.endMinutes,
                startTimeLabel: m.formattedStartTime,
                endTimeLabel: m.formattedEndTime,
                room: room,
                instructor: instructorLabel,
              ),
            );
          }
        }
      }

      todayRows.sort((a, b) {
        final startCmp = a.startMinutes.compareTo(b.startMinutes);
        if (startCmp != 0) return startCmp;
        final endCmp = a.endMinutes.compareTo(b.endMinutes);
        if (endCmp != 0) return endCmp;
        return a.subjectName.compareTo(b.subjectName);
      });

      final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
      final presentCount = attendance
          .where((a) => a.status == 'present' || a.status == 'late')
          .length;
      final pct = attendance.isEmpty
          ? 0
          : ((presentCount / attendance.length) * 100).round();

      if (!mounted) return;
      setState(() {
        _studentName = profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : 'Student';
        _classCount = official.length + personal.length;
        _tasksDueCount = pendingTasks.length;
        _attendancePercent = pct;
        _unreadNotifications = notifications.where((n) => n.isUnread).length;
        _todayClasses = todayRows;
        _nextDeadline = pendingTasks.isNotEmpty ? pendingTasks.first : null;
      });
    } catch (_) {}
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String getFormattedDate() {
    final now = DateTime.now();

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}';
  }

  Future<void> _handleRefresh() async {
    await _loadDashboard();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 96),
            child: ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcademicPageHeader(
                    eyebrow: getFormattedDate(),
                    title: '${getGreeting()}, $_studentName',
                    subtitle: 'Classes, tasks, attendance, and grades at a glance.',
                    actions: [
                      _DashboardNotificationButton(
                        onPressed: widget.onOpenNotifications,
                        hasUnread: _unreadNotifications > 0,
                      ),
                    ],
                  ),
                  SurfacePanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OVERVIEW TITLE
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Academic Overview',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Text(
                              'THIS WEEK',
                              style: TextStyle(
                                color: muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // RESPONSIVE SUMMARY CARDS
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 10.0;
                            final columns = constraints.maxWidth >= 640 ? 4 : 2;
                            final cardWidth =
                                (constraints.maxWidth - spacing * (columns - 1)) /
                                    columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _DashboardSummaryCard(
                                    icon: LucideIcons.bookOpen,
                                    value: '$_classCount',
                                    label: 'Classes',
                                    accentColor: AppColors.primary,
                                    accentLight: AppColors.primaryLight,
                                    onTap: widget.onOpenClasses,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DashboardSummaryCard(
                                      icon: LucideIcons.clipboardList,
                                      value: '$_tasksDueCount',
                                      label: 'Tasks Due',
                                      accentColor: AppColors.warning,
                                      accentLight: AppColors.warningLight,
                                      onTap: widget.onOpenTasks,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DashboardSummaryCard(
                                      icon: LucideIcons.chartNoAxesColumnIncreasing,
                                      value: '$_attendancePercent%',
                                      label: 'Attendance',
                                      accentColor: AppColors.success,
                                      accentLight: AppColors.successLight,
                                      onTap: widget.onOpenAttendance,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DashboardSummaryCard(
                                      icon: LucideIcons.graduationCap,
                                      value: 'View',
                                      label: 'My Scores',
                                      accentColor: AppColors.study,
                                      accentLight: AppColors.studyLight,
                                      onTap: widget.onOpenScores,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 27),

                          // TODAY'S CLASSES
                          _DashboardSectionTitle(
                            title: "Today's Classes",
                            action: 'See all',
                            onTap: widget.onOpenClasses,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: border),
                            ),
                            child: _todayClasses.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.calendarOff,
                                          size: 18,
                                          color: muted,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'No classes scheduled for today.',
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      _todayClasses.length,
                                      (i) {
                                        final entry = _todayClasses[i];
                                        return Column(
                                          children: [
                                            _DashboardScheduleRow(
                                              entry: entry,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ClassDetailScreen(
                                                      classItem:
                                                          entry.classItem,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (i != _todayClasses.length - 1)
                                              const Divider(
                                                height: 1,
                                                color: border,
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 26),

                          // UPCOMING DEADLINE
                          _DashboardSectionTitle(
                            title: 'Upcoming Deadline',
                            action: 'View tasks',
                            onTap: widget.onOpenTasks,
                          ),
                          const SizedBox(height: 12),
                          if (_nextDeadline == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: border),
                              ),
                              child: const Text(
                                'No upcoming deadlines.',
                                style: TextStyle(color: muted, fontSize: 13),
                              ),
                            )
                          else
                            _UpcomingDeadlineCard(
                              task: _nextDeadline!,
                              onTap: widget.onOpenTasks,
                            ),

                          const SizedBox(height: 26),

                          // STUDY TOOLS
                          const Text(
                            'Study Tools',
                            style: TextStyle(
                              color: navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _StudySessionsCard(
                            onTap: widget.onOpenStudySessions,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION BUTTON
// ============================================================

class _DashboardNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool hasUnread;

  const _DashboardNotificationButton({
    required this.onPressed,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                LucideIcons.bell,
                color: Colors.white,
                size: 23,
              ),
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: StudentDashboard.darkBlue,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _DashboardSummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  final Color accentColor;
  final Color accentLight;

  const _DashboardSummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.accentLight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 19,
                ),
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: StudentDashboard.navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: StudentDashboard.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _DashboardSectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _DashboardSectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: StudentDashboard.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: StudentDashboard.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.arrowRight,
                  color: StudentDashboard.primaryBlue,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TODAY MEETING ENTRY & SCHEDULE ROW
// ============================================================

enum _MeetingStatus { ongoing, upcoming, ended }

class _TodayMeetingEntry {
  final ClassItem classItem;
  final String subjectCode;
  final String subjectName;
  final int startMinutes;
  final int endMinutes;
  final String startTimeLabel;
  final String endTimeLabel;
  final String room;
  final String instructor;

  const _TodayMeetingEntry({
    required this.classItem,
    required this.subjectCode,
    required this.subjectName,
    required this.startMinutes,
    required this.endMinutes,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.room,
    required this.instructor,
  });

  _MeetingStatus statusAt(DateTime now) {
    final nowMins = now.hour * 60 + now.minute;
    if (nowMins >= startMinutes && nowMins < endMinutes) {
      return _MeetingStatus.ongoing;
    }
    if (nowMins < startMinutes) {
      return _MeetingStatus.upcoming;
    }
    return _MeetingStatus.ended;
  }
}

class _DashboardScheduleRow extends StatelessWidget {
  final _TodayMeetingEntry entry;
  final VoidCallback onTap;

  const _DashboardScheduleRow({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = entry.statusAt(DateTime.now());
    final isOngoing = status == _MeetingStatus.ongoing;
    final isUpcoming = status == _MeetingStatus.upcoming;

    final badgeBg = isOngoing
        ? AppColors.primary
        : isUpcoming
            ? AppColors.primaryLight
            : AppColors.surfaceSoft;
    final badgeFg = isOngoing
        ? Colors.white
        : isUpcoming
            ? StudentDashboard.primaryBlue
            : StudentDashboard.muted;
    final badgeText = isOngoing
        ? 'ONGOING'
        : isUpcoming
            ? 'UPCOMING'
            : 'ENDED';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.startTimeLabel,
                    style: const TextStyle(
                      color: StudentDashboard.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.endTimeLabel,
                    style: const TextStyle(
                      color: StudentDashboard.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: isOngoing
                    ? StudentDashboard.primaryBlue
                    : StudentDashboard.border,
                borderRadius: BorderRadius.circular(5),
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          entry.subjectCode,
                          style: const TextStyle(
                            color: StudentDashboard.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudentDashboard.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.room} · ${entry.instructor}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudentDashboard.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeFg,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: StudentDashboard.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// UPCOMING DEADLINE CARD
// ============================================================

class _UpcomingDeadlineCard extends StatelessWidget {
  final StudentTaskRecord task;
  final VoidCallback onTap;

  const _UpcomingDeadlineCard({
    required this.task,
    required this.onTap,
  });

  String get _badgeText {
    final s = task.subject.trim();
    if (s.isEmpty) return 'TSK';
    final words = s.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get _dueLabel {
    final due = task.dueAt;
    if (due == null) return 'No due date';
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
    return 'Due ${months[due.month - 1]} ${due.day}, ${due.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningLight,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.warningBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _badgeText,
                    style: const TextStyle(
                      color: AppColors.warningDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentDashboard.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.subject.isEmpty ? 'General' : task.subject,
                      style: const TextStyle(
                        color: StudentDashboard.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          color: AppColors.warning,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _dueLabel,
                          style: const TextStyle(
                            color: AppColors.warningDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                color: StudentDashboard.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STUDY SESSIONS CARD
// ============================================================

class _StudySessionsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _StudySessionsCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.studyLight,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.studyBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.timer,
                  color: AppColors.study,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Sessions',
                      style: TextStyle(
                        color: StudentDashboard.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Plan focused study time and track your progress.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: StudentDashboard.muted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Open study planner',
                      style: TextStyle(
                        color: AppColors.study,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                color: StudentDashboard.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
