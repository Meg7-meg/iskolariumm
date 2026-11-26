import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../main.dart' show ClassDetailScreen, ClassItem;
import '../../services/academic_service.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../services/organizer_service.dart';
import '../../services/supabase_client_provider.dart';
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
  final VoidCallback onAddTask;
  final VoidCallback onRefresh;

  const StudentDashboard({
    super.key,
    required this.onOpenClasses,
    required this.onOpenTasks,
    required this.onOpenNotifications,
    required this.onOpenStudySessions,
    required this.onOpenAttendance,
    required this.onOpenScores,
    required this.onAddTask,
    required this.onRefresh,
  });

  // Shared application color palette.
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.textPrimary;
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
  static const Color border = StudentDashboard.border;

  String _studentName = 'Student';
  int _attendancePercent = 0;
  int _unreadNotifications = 0;
  int _activeCourseCount = 0;
  DateTime? _attendanceProgressDate;
  List<_TodayMeetingEntry> _todayClasses = const [];
  List<StudentTaskRecord> _dashboardTasks = const [];
  List<ClassAssignmentRecord> _classAssignments = const [];
  Set<String> _completedTaskIds = {};
  String? _assignmentLoadError;

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
      List<ClassAssignmentRecord> assignments = const [];
      String? assignmentLoadError;
      try {
        assignments = await AcademicService.getStudentAssignments();
      } catch (error) {
        assignmentLoadError = formatSupabaseError(error);
      }
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
          final instructorLabel = p.instructorName.isEmpty
              ? 'Personal Course'
              : p.instructorName;
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
                : (p.location.trim().isEmpty ? 'Personal' : p.location.trim());
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

      final presentCount = attendance
          .where((a) => a.status == 'present' || a.status == 'late')
          .length;
      final pct = attendance.isEmpty
          ? 0
          : ((presentCount / attendance.length) * 100).round();
      final attendanceProgressDate = _mostRecentDate(
        attendance.map((record) => record.attendanceDate),
      );
      if (!mounted) return;
      setState(() {
        _studentName = profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : 'Student';
        _attendancePercent = pct;
        _activeCourseCount = official.length + personal.length;
        _attendanceProgressDate = attendanceProgressDate;
        _unreadNotifications = notifications.where((n) => n.isUnread).length;
        _todayClasses = todayRows;
        _dashboardTasks = tasks;
        _classAssignments = assignments;
        _assignmentLoadError = assignmentLoadError;
        _completedTaskIds = tasks
            .where((task) => task.isCompleted)
            .map((task) => task.id)
            .toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleTask(StudentTaskRecord task) async {
    final wasCompleted = _completedTaskIds.contains(task.id);
    final isCompleted = !wasCompleted;

    setState(() {
      if (isCompleted) {
        _completedTaskIds.add(task.id);
      } else {
        _completedTaskIds.remove(task.id);
      }
    });

    try {
      await OrganizerService.toggleTaskCompleted(task.id, isCompleted);
      widget.onRefresh();
    } catch (error) {
      if (mounted) {
        setState(() {
          if (wasCompleted) {
            _completedTaskIds.add(task.id);
          } else {
            _completedTaskIds.remove(task.id);
          }
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(formatSupabaseError(error))));
      }
    }
  }

  DateTime? _mostRecentDate(Iterable<DateTime?> dates) {
    DateTime? latest;
    for (final date in dates) {
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest;
  }

  String? _formatProgressDate(DateTime? date) {
    if (date == null) return null;
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
    final localDate = date.toLocal();
    return '${months[localDate.month - 1]} ${localDate.day}';
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
      backgroundColor: AppColors.surfaceSoft,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 76),
            child: ResponsiveContainer(
              key: const ValueKey('student-dashboard-container'),
              maxWidth: double.infinity,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDashboardHeader(),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DashboardSectionTitle(title: "Today's Classes"),
                              const SizedBox(height: 12),
                              if (_todayClasses.isEmpty)
                                _NoClassesCard(onAdd: widget.onOpenClasses)
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.navy.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
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
                              const SizedBox(height: 24),
                              _DashboardSectionTitle(
                                title: 'Academic Progress',
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 420;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _AcademicProgressCard(
                                          label: 'Attendance',
                                          value: '$_attendancePercent%',
                                          emphasizeValue: true,
                                          dateLabel: _formatProgressDate(
                                            _attendanceProgressDate,
                                          ),
                                          onTap: widget.onOpenAttendance,
                                        ),
                                      ),
                                      SizedBox(width: compact ? 10 : 12),
                                      Expanded(
                                        child: _AcademicProgressCard(
                                          label: 'Grades',
                                          value: 'View Records',
                                          subtitle:
                                              '$_activeCourseCount active courses',
                                          showChevron: true,
                                          onTap: widget.onOpenScores,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Expanded(
                                    child: _DashboardSectionTitle(
                                      title: 'Upcoming Deadlines',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onAddTask,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),
                                    child: const Text(
                                      '+ Add task',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_assignmentLoadError != null) ...[
                                AsyncErrorView(
                                  message: _assignmentLoadError!,
                                  onRetry: _loadDashboard,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (_dashboardTasks.isEmpty &&
                                  _classAssignments.isEmpty &&
                                  _assignmentLoadError == null)
                                const _NoDeadlinesCard()
                              else ...[
                                for (final assignment in _classAssignments)
                                  _DashboardAssignmentCard(
                                    assignment: assignment,
                                    onTap: widget.onOpenTasks,
                                  ),
                                for (final task in _dashboardTasks)
                                  _DashboardTaskCard(
                                    task: task,
                                    isCompleted: _completedTaskIds.contains(
                                      task.id,
                                    ),
                                    onToggle: () => _toggleTask(task),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildDashboardHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173156), Color(0xFF2C5388)],
        ),
      ),
      child: ResponsiveContainer(
        maxWidth: 960,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
        child: Row(
          key: const ValueKey('student-dashboard-header'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getFormattedDate().toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFDCE7F5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${getGreeting()}, $_studentName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Here’s your academic overview.',
                    style: TextStyle(color: Color(0xFFDCE7F5), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            DashboardNotificationButton(
              onPressed: widget.onOpenNotifications,
              unreadCount: _unreadNotifications,
              isDarkHeader: true,
            ),
          ],
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

  const _DashboardSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionHeading);
  }
}

class _NoClassesCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoClassesCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: const Icon(
              LucideIcons.calendar,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No classes today', style: AppTextStyles.cardHeading),
                SizedBox(height: 3),
                Text(
                  'Enjoy your free day or review notes.',
                  style: AppTextStyles.meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.infoBorder),
              ),
            ),
            child: const Text(
              '+ Add',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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

  const _DashboardScheduleRow({required this.entry, required this.onTap});

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
                  Text(entry.startTimeLabel, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(entry.endTimeLabel, style: AppTextStyles.meta),
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
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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

class _NoDeadlinesCard extends StatelessWidget {
  const _NoDeadlinesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.circleCheck, color: AppColors.success, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All caught up!', style: AppTextStyles.cardHeading),
                SizedBox(height: 3),
                Text(
                  'No pending tasks or deadlines right now.',
                  style: AppTextStyles.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAssignmentCard extends StatelessWidget {
  final ClassAssignmentRecord assignment;
  final VoidCallback onTap;

  const _DashboardAssignmentCard({
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final course = assignment.subjectCode.trim().isNotEmpty
        ? assignment.subjectCode
        : assignment.className;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardHeading,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$course · Class Assignment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DueDatePill(date: assignment.dueAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTaskCard extends StatelessWidget {
  final StudentTaskRecord task;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _DashboardTaskCard({
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${task.subject.trim().isEmpty ? 'General' : task.subject} · Personal Task',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.meta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _DueDatePill(date: task.dueAt),
          ],
        ),
      ),
    );
  }
}

class _DueDatePill extends StatelessWidget {
  final DateTime? date;

  const _DueDatePill({required this.date});

  @override
  Widget build(BuildContext context) {
    final dueAt = date;
    final dateText = dueAt == null
        ? 'No due date'
        : 'Due ${_StudentDashboardDateFormat.shortDate(dueAt)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StudentDashboardDateFormat {
  static String shortDate(DateTime date) {
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
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}';
  }
}

// ============================================================
// ACADEMIC PROGRESS CARD
// ============================================================

class _AcademicProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final String? dateLabel;
  final String? subtitle;
  final bool showChevron;
  final bool emphasizeValue;
  final VoidCallback onTap;

  const _AcademicProgressCard({
    required this.label,
    required this.value,
    this.dateLabel,
    this.subtitle,
    this.showChevron = false,
    this.emphasizeValue = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.meta,
                    ),
                  ),
                  if (dateLabel != null)
                    Text(
                      dateLabel!,
                      maxLines: 1,
                      style: AppTextStyles.meta.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  if (showChevron)
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: emphasizeValue ? 24 : 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.meta.copyWith(fontSize: 10.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
