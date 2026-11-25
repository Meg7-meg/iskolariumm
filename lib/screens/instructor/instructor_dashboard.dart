import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/academic_service.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';
import '../../widgets/class_schedule_editor.dart';

import 'take_attendance.dart';
import 'enter_scores.dart';
import 'instructor_profile.dart';
import 'instructor_announcements_screen.dart';

// ============================================================
// INSTRUCTOR DASHBOARD
// ============================================================

class InstructorDashboard extends StatefulWidget {
  final int initialIndex;

  const InstructorDashboard({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<InstructorDashboard> createState() =>
      _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  // DESIGN TOKENS — SHARED ISKOLARIUM PALETTE
  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;
  static const Color _bg = AppColors.background;
  static const Color _ice = AppColors.primaryLight;

  late int selectedIndex;

  String searchQuery = '';
  bool showTodayOnly = false;
  bool showArchived = false;
  bool isLoading = true;
  String? loadError;

  UserProfile? _profile;
  List<OfficialClassRecord> _classes = [];
  Map<String, int> _todayAttendanceCounts = const {};
  Map<String, int> _classAssessmentCounts = const {};

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, 3);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final profile = await AuthService.getCurrentProfile();
      final classes = await ClassService.getInstructorClasses(
        includeArchived: showArchived,
      );
      final classIds =
          classes.where((c) => !c.isArchived).map((c) => c.id).toList();
      final attendanceCounts = await AcademicService.getAttendanceCountsForDate(
        classIds: classIds,
        date: DateTime.now(),
      );

      final assessmentCounts = <String, int>{};
      await Future.wait(
        classIds.map((cid) async {
          try {
            final res = await Future.wait([
              AcademicService.getClassAssignments(cid),
              AcademicService.getClassQuizzes(cid),
            ]);
            assessmentCounts[cid] =
                (res[0] as List).length + (res[1] as List).length;
          } catch (_) {
            assessmentCounts[cid] = 0;
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _classes = classes;
        _todayAttendanceCounts = attendanceCounts;
        _classAssessmentCounts = assessmentCounts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = formatSupabaseError(e);
      });
    }
  }

  List<_InstructorTodayMeeting> get _todayMeetings {
    final todayWeekday = DateTime.now().weekday;
    final list = <_InstructorTodayMeeting>[];

    for (final c in _classes.where((c) => !c.isArchived)) {
      for (final m in c.effectiveSchedules) {
        if (m.weekday == todayWeekday) {
          final mKey = (m.id != null && m.id!.isNotEmpty)
              ? m.id!
              : '${m.dayOfWeek}_${m.startMinutes}_${m.endMinutes}';
          final exactCount = _todayAttendanceCounts['${c.id}|$mKey'] ?? 0;
          final legacyCount = _todayAttendanceCounts['${c.id}|'] ?? 0;
          final recordedCount = exactCount > 0 ? exactCount : legacyCount;

          list.add(
            _InstructorTodayMeeting(
              record: c,
              meeting: m,
              meetingKey: mKey,
              recordedCount: recordedCount,
            ),
          );
        }
      }
    }

    list.sort((a, b) {
      final startCmp = a.meeting.startMinutes.compareTo(b.meeting.startMinutes);
      if (startCmp != 0) return startCmp;
      final endCmp = a.meeting.endMinutes.compareTo(b.meeting.endMinutes);
      if (endCmp != 0) return endCmp;
      return a.record.className.compareTo(b.record.className);
    });
    return list;
  }

  List<Map<String, String>> get assignedClasses => _classes
      .where((c) => !c.isArchived)
      .map(_classToMap)
      .toList();

  Map<String, String> _classToMap(OfficialClassRecord c) {
    return {
      'id': c.id,
      'subject': c.className,
      'section': c.section,
      'code': c.subjectCode,
      'room': c.roomSummary,
      'schedule': c.scheduleMultiline,
      'students': '${c.approvedStudentCount} enrolled students',
      'instructor': _profile?.fullName.isNotEmpty == true
          ? _profile!.fullName
          : c.instructorName,
      'enrollmentCode': c.enrollmentCode,
    };
  }

  bool _isClassScheduledToday(OfficialClassRecord c) {
    return c.isScheduledOnWeekday(DateTime.now().weekday);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formattedToday() {
    final now = DateTime.now();

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

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // ============================================================
  // LAYERED PAGE WRAPPERS
  // ============================================================

  Widget buildHomeScreen() {
    final name = _profile?.fullName.trim() ?? '';
    final greeting = name.isNotEmpty ? 'Welcome back, $name' : 'Welcome back';
    return _buildLayeredPage(
      eyebrow: 'INSTRUCTOR WORKSPACE',
      title: greeting,
      subtitle: 'Your classes and teaching activities',
      child: _buildHomeContent(),
    );
  }

  Widget buildClassesScreen() {
    return _buildLayeredPage(
      eyebrow: 'YOUR TEACHING SPACE',
      title: 'Assigned Classes',
      subtitle: 'Manage your assigned subjects and sections',
      child: _buildClassesContent(),
    );
  }

  Widget buildAnnouncementsScreen() {
    return _buildLayeredPage(
      eyebrow: 'CLASS COMMUNICATION',
      title: 'Announcements',
      subtitle: 'Share updates with a specific class or section',
      child: InstructorAnnouncementsPage(
        assignedClasses: assignedClasses,
      ),
    );
  }

  Widget _buildLayeredPage({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // BLUE HEADER
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 235,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // WHITE CONTENT PANEL
                Positioned(
                  top: 166,
                  left: 15,
                  right: 15,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.07),
                          blurRadius: 22,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HOME SCREEN
  // ============================================================

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final activeClasses = _classes.where((c) => !c.isArchived).toList();
    final totalStudents = activeClasses.fold<int>(
      0,
      (sum, c) => sum + c.approvedStudentCount,
    );
    final totalPending = activeClasses.fold<int>(
      0,
      (sum, c) => sum + c.pendingRequestCount,
    );
    final todayCount = activeClasses.where(_isClassScheduledToday).length;

    return RefreshIndicator(
      color: _blue,
      onRefresh: _loadDashboardData,
      child: ResponsiveContainer(
        maxWidth: 1024,
        padding: EdgeInsets.zero,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 22, 17, 30),
        children: [
          Text(
            _formattedToday(),
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 22),

          // SUMMARY CARDS
          Row(
            children: [
              Expanded(
                child: buildSummaryCard(
                  '${activeClasses.length}',
                  'Active classes',
                  LucideIcons.bookOpen,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSummaryCard(
                  '$totalStudents',
                  totalPending > 0
                      ? 'Students ($totalPending pending)'
                      : 'Enrolled students',
                  LucideIcons.users,
                  accentColor: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: buildSummaryCard(
                  '$todayCount',
                  'Classes today',
                  LucideIcons.calendarDays,
                  accentColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSummaryCard(
                  '$totalPending',
                  'Pending requests',
                  LucideIcons.userCheck,
                  accentColor: AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Classes",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ClassMeetingSchedule.daysOfWeek[DateTime.now().weekday - 1]} · ${_todayMeetings.length} scheduled meeting${_todayMeetings.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => selectedIndex = 1);
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_classes.where((c) => !c.isArchived).isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  const Text(
                    'No classes created yet.',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _openCreateClassDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create your first class'),
                  ),
                ],
              ),
            )
          else if (_todayMeetings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      LucideIcons.calendarOff,
                      color: _muted,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No classes scheduled for today.',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View all assigned classes in the Classes tab.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._todayMeetings.map(_buildTodayMeetingCard),

          const SizedBox(height: 14),

          // VIEW CLASSES BUTTON
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => selectedIndex = 1);
              },
              icon: const Icon(
                LucideIcons.bookOpen,
                size: 19,
              ),
              label: const Text(
                'Manage classes & enrollments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(
                  color: _blue,
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // INFORMATION NOTE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  color: _blue,
                  size: 20,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Your workspace shows only your assigned sections. '
                    'Select a class to manage enrollments, attendance, and scores.',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 13,
                      height: 1.5,
                    ),
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

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget buildSummaryCard(
    String value,
    String label,
    IconData icon, {
    Color accentColor = AppColors.primary,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY'S MEETING CARD
  // ============================================================

  Widget _buildTodayMeetingCard(_InstructorTodayMeeting item) {
    final record = item.record;
    final meeting = item.meeting;
    final classMap = _classToMap(record);
    final hasAttendance = item.recordedCount > 0;
    final roomLabel = meeting.room.trim().isEmpty ? 'TBA' : meeting.room.trim();
    final studentCountLabel =
        '${record.approvedStudentCount} enrolled student${record.approvedStudentCount == 1 ? '' : 's'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
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
                  color: _ice,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: _blue,
                  size: 19,
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
                            color: _ice,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            record.subjectCode,
                            style: const TextStyle(
                              color: _blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.section,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.className,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasAttendance ? _ice : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasAttendance
                        ? _blue.withValues(alpha: 0.25)
                        : _border,
                  ),
                ),
                child: Text(
                  hasAttendance ? 'Recorded' : 'Pending',
                  style: TextStyle(
                    color: hasAttendance ? _blue : _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _classInfoRow(LucideIcons.clock, meeting.formattedTimeRange),
          const SizedBox(height: 6),
          _classInfoRow(
            roomLabel.toLowerCase() == 'online'
                ? LucideIcons.video
                : LucideIcons.mapPin,
            roomLabel,
          ),
          const SizedBox(height: 6),
          _classInfoRow(LucideIcons.users, studentCountLabel),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: hasAttendance
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InstructorAttendanceScreen(
                                  classItem: classMap,
                                  scheduleId: meeting.id,
                                  meetingKey: item.meetingKey,
                                  meetingLabel: meeting.formattedSummary,
                                ),
                              ),
                            );
                            if (mounted) _loadDashboardData();
                          },
                          icon: const Icon(LucideIcons.clipboardCheck, size: 15),
                          label: const Text(
                            'Edit Attendance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue,
                            side: const BorderSide(color: _blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InstructorAttendanceScreen(
                                  classItem: classMap,
                                  scheduleId: meeting.id,
                                  meetingKey: item.meetingKey,
                                  meetingLabel: meeting.formattedSummary,
                                ),
                              ),
                            );
                            if (mounted) _loadDashboardData();
                          },
                          icon: const Icon(LucideIcons.clipboardCheck, size: 15),
                          label: const Text(
                            'Take Attendance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ),
              if ((_classAssessmentCounts[record.id] ?? 0) > 0) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InstructorEnterScoresScreen(
                            classItem: classMap,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Scores',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME CLASS CARD
  // ============================================================

  Widget buildClassCard(Map<String, String> classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.045),
            blurRadius: 12,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _ice,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
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
                      classItem['subject']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${classItem['code']} · ${classItem['section']}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: _blue,
                size: 21,
              ),
            ],
          ),

          const SizedBox(height: 15),

          _classInfoRow(
            LucideIcons.clock,
            classItem['schedule']!,
          ),

          const SizedBox(height: 8),

          _classInfoRow(
            LucideIcons.mapPin,
            classItem['room']!,
          ),

          const SizedBox(height: 8),

          _classInfoRow(
            LucideIcons.users,
            classItem['students']!,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InstructorAttendanceScreen(
                            classItem: classItem,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              if ((_classAssessmentCounts[classItem['id'] ?? ''] ?? 0) > 0) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InstructorEnterScoresScreen(
                              classItem: classItem,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: const BorderSide(color: _blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enter scores',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _classInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: _muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CLASSES SCREEN
  // ============================================================

  Widget _buildClassesContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    final filteredRecords = _classes.where((record) {
      final searchText = searchQuery.toLowerCase();
      final matchesSearch =
          record.className.toLowerCase().contains(searchText) ||
          record.subjectCode.toLowerCase().contains(searchText) ||
          record.section.toLowerCase().contains(searchText);
      final matchesToday = !showTodayOnly || _isClassScheduledToday(record);
      return matchesSearch && matchesToday;
    }).toList();

    return RefreshIndicator(
      color: _blue,
      onRefresh: _loadDashboardData,
      child: ResponsiveContainer(
        maxWidth: 1024,
        padding: EdgeInsets.zero,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 22, 17, 30),
        children: [
          const SizedBox(height: 5),

          // SEARCH FIELD
          TextField(
            onChanged: (value) {
              setState(() => searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search name, code or section',
              hintStyle: const TextStyle(color: _muted, fontSize: 13),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: _muted,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: _blue, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _openCreateClassDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Create Class',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Show Archived'),
                selected: showArchived,
                onSelected: (v) {
                  setState(() => showArchived = v);
                  _loadDashboardData();
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // FILTER
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _ice,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: buildClassFilterButton(
                    label: 'All classes',
                    isSelected: !showTodayOnly,
                    onTap: () => setState(() => showTodayOnly = false),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: buildClassFilterButton(
                    label: 'Today',
                    isSelected: showTodayOnly,
                    onTap: () => setState(() => showTodayOnly = true),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your classes',
                style: TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${filteredRecords.length} sections',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (filteredRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.searchX, color: _muted, size: 32),
                  SizedBox(height: 10),
                  Text(
                    'No assigned classes found.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...filteredRecords.map(_buildManagedClassCard),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, color: _blue, size: 19),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Assigned-class access only. Other instructors' "
                    "classes are not available in this account.",
                    style: TextStyle(color: _navy, fontSize: 12, height: 1.5),
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

  Widget _buildManagedClassCard(OfficialClassRecord record) {
    final classMap = _classToMap(record);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _ice,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.bookOpen, color: _blue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.className,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        record.subjectCode,
                        record.section,
                        if (record.program.isNotEmpty) record.program,
                        if (record.academicYear.isNotEmpty) record.academicYear,
                      ].join(' · ') +
                          (record.isArchived ? ' (Archived)' : ''),
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    await _openCreateClassDialog(existing: record);
                  } else if (action == 'archive') {
                    await ClassService.setClassArchived(
                      record.id,
                      !record.isArchived,
                    );
                    await _loadDashboardData();
                    showMessage(
                      record.isArchived
                          ? 'Class restored.'
                          : 'Class archived.',
                    );
                  } else if (action == 'regen') {
                    final newCode = ClassService.generateCode();
                    await ClassService.updateOfficialClass(
                      classId: record.id,
                      className: record.className,
                      subjectCode: record.subjectCode,
                      section: record.section,
                      academicYear: record.academicYear,
                      program: record.program,
                      room: record.room,
                      scheduleDay: record.scheduleDay,
                      scheduleTime: record.scheduleTime,
                      description: record.description,
                      enrollmentCode: newCode,
                    );
                    await _loadDashboardData();
                    showMessage('New join code generated: $newCode');
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit class')),
                  const PopupMenuItem(
                    value: 'regen',
                    child: Text('Regenerate join code'),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(
                      record.isArchived ? 'Restore class' : 'Archive class',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _classInfoRow(LucideIcons.clock, record.scheduleMultiline),
          const SizedBox(height: 6),
          _classInfoRow(
            LucideIcons.mapPin,
            record.roomSummary,
          ),
          const SizedBox(height: 6),
          _classInfoRow(
            LucideIcons.users,
            '${record.approvedStudentCount} enrolled · ${record.pendingRequestCount} pending',
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: record.enrollmentCode));
              showMessage('Join code ${record.enrollmentCode} copied.');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _ice,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_rounded, size: 15, color: _blue),
                  const SizedBox(width: 6),
                  Text(
                    'Join Code: ${record.enrollmentCode}',
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 13, color: _blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openManageEnrollmentsSheet(record),
                icon: const Icon(LucideIcons.userPlus, size: 15),
                label: Text(
                  record.pendingRequestCount > 0
                      ? 'Students (${record.pendingRequestCount} pending)'
                      : 'Students',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InstructorAttendanceScreen(classItem: classMap),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.clipboardCheck, size: 15),
                label: const Text('Attendance'),
              ),
              if ((_classAssessmentCounts[record.id] ?? 0) > 0)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InstructorEnterScoresScreen(classItem: classMap),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.award, size: 15),
                  label: const Text('Scores'),
                ),
              OutlinedButton.icon(
                onPressed: () => _openClassAssignmentsSheet(record),
                icon: const Icon(LucideIcons.fileText, size: 15),
                label: const Text('Tasks & Quizzes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateClassDialog({OfficialClassRecord? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OfficialClassFormDialog(existing: existing),
    );

    if (saved == true && mounted) {
      await _loadDashboardData();
      showMessage(
        existing == null ? 'Official class created.' : 'Class updated.',
      );
    }
  }

  Future<void> _openClassAssignmentsSheet(OfficialClassRecord record) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController();
    DateTime? dueDate = DateTime.now().add(const Duration(days: 3));
    String category = 'Assignment';
    List<ClassAssignmentRecord> assignments = [];
    ClassAssignmentRecord? editingAssignment;
    bool loading = true;
    bool isSubmitting = false;
    bool didInitialLoad = false;
    String? error;
    String? feedbackMessage;
    bool feedbackIsError = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> load() async {
              try {
                final list = await AcademicService.getClassAssignments(record.id);
                if (!sheetContext.mounted) return;
                setSheetState(() {
                  assignments = list;
                  loading = false;
                  error = null;
                });
              } catch (e) {
                if (!sheetContext.mounted) return;
                setSheetState(() {
                  loading = false;
                  error = formatSupabaseError(e);
                });
              }
            }

            if (!didInitialLoad) {
              didInitialLoad = true;
              load();
            }

            void startEditing(ClassAssignmentRecord a) {
              setSheetState(() {
                editingAssignment = a;
                titleCtrl.text = a.title;
                descCtrl.text = a.description;
                maxScoreCtrl.text = a.maxScore == null
                    ? ''
                    : a.maxScore!.toStringAsFixed(0);
                category = const ['Assignment', 'Activity', 'Project']
                        .contains(a.category)
                    ? a.category
                    : 'Assignment';
                dueDate = a.dueAt;
                feedbackMessage = null;
              });
            }

            void cancelEditing() {
              setSheetState(() {
                editingAssignment = null;
                titleCtrl.clear();
                descCtrl.clear();
                maxScoreCtrl.clear();
                category = 'Assignment';
                dueDate = DateTime.now().add(const Duration(days: 3));
                feedbackMessage = null;
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${record.subjectCode} · Assignments',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                        ),
                        if (editingAssignment != null)
                          TextButton(
                            onPressed: isSubmitting ? null : cancelEditing,
                            child: const Text('Cancel Edit'),
                          ),
                      ],
                    ),
                    if (feedbackMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: feedbackIsError
                              ? AppColors.dangerLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: feedbackIsError
                                ? AppColors.dangerBorder
                                : AppColors.successBorder,
                          ),
                        ),
                        child: Text(
                          feedbackMessage!,
                          style: TextStyle(
                            color: feedbackIsError
                                ? AppColors.dangerDark
                                : AppColors.successDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assignment / Task Title',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instructions (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Assignment',
                                child: Text('Assignment'),
                              ),
                              DropdownMenuItem(
                                value: 'Activity',
                                child: Text('Activity'),
                              ),
                              DropdownMenuItem(
                                value: 'Project',
                                child: Text('Project'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => category = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxScoreCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Score',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: dueDate ?? DateTime.now(),
                                      firstDate: DateTime(2024),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null && sheetContext.mounted) {
                                      setSheetState(() => dueDate = picked);
                                    }
                                  },
                            icon: const Icon(LucideIcons.calendar, size: 15),
                            label: Text(
                              dueDate == null
                                  ? 'Set Due Date'
                                  : 'Due ${dueDate!.month}/${dueDate!.day}/${dueDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final title = titleCtrl.text.trim();
                                  if (title.isEmpty) {
                                    setSheetState(() {
                                      feedbackMessage =
                                          'Please enter an assignment title.';
                                      feedbackIsError = true;
                                    });
                                    return;
                                  }

                                  final maxScoreText = maxScoreCtrl.text.trim();
                                  final parsedMaxScore = maxScoreText.isEmpty
                                      ? null
                                      : double.tryParse(maxScoreText);
                                  if (maxScoreText.isNotEmpty &&
                                      parsedMaxScore == null) {
                                    setSheetState(() {
                                      feedbackMessage =
                                          'Max Score must be a valid number.';
                                      feedbackIsError = true;
                                    });
                                    return;
                                  }

                                  setSheetState(() {
                                    isSubmitting = true;
                                    feedbackMessage = null;
                                  });

                                  try {
                                    final isEditing = editingAssignment != null;
                                    if (isEditing) {
                                      await AcademicService
                                          .updateClassAssignment(
                                        id: editingAssignment!.id,
                                        title: title,
                                        description: descCtrl.text,
                                        category: category,
                                        dueAt: dueDate,
                                        maxScore: parsedMaxScore,
                                      );
                                    } else {
                                      await AcademicService
                                          .createClassAssignment(
                                        classId: record.id,
                                        title: title,
                                        description: descCtrl.text,
                                        category: category,
                                        dueAt: dueDate,
                                        maxScore: parsedMaxScore,
                                      );
                                    }

                                    if (!sheetContext.mounted) return;
                                    editingAssignment = null;
                                    titleCtrl.clear();
                                    descCtrl.clear();
                                    maxScoreCtrl.clear();
                                    category = 'Assignment';
                                    dueDate = DateTime.now()
                                        .add(const Duration(days: 3));
                                    await load();
                                    if (!sheetContext.mounted) return;
                                    setSheetState(() {
                                      isSubmitting = false;
                                      feedbackMessage = isEditing
                                          ? 'Assignment updated.'
                                          : 'Assignment published.';
                                      feedbackIsError = false;
                                    });
                                  } catch (e) {
                                    if (!sheetContext.mounted) return;
                                    setSheetState(() {
                                      isSubmitting = false;
                                      feedbackMessage = formatSupabaseError(e);
                                      feedbackIsError = true;
                                    });
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  editingAssignment != null
                                      ? 'Save Changes'
                                      : 'Publish',
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red))
                    else if (assignments.isEmpty)
                      const Text(
                        'No assignments published for this class yet.',
                        style: TextStyle(color: _muted),
                      )
                    else
                      ...assignments.map(
                        (a) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            a.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              a.category,
                              if (a.dueAt != null)
                                'Due ${a.dueAt!.month}/${a.dueAt!.day}/${a.dueAt!.year}',
                              if (a.maxScore != null)
                                '${a.maxScore!.toStringAsFixed(0)} pts',
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.pencil,
                                  size: 17,
                                  color: _blue,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () => startEditing(a),
                              ),
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        try {
                                          await AcademicService
                                              .deleteClassAssignment(a.id);
                                          if (editingAssignment?.id == a.id) {
                                            cancelEditing();
                                          }
                                          await load();
                                          if (!sheetContext.mounted) return;
                                          setSheetState(() {
                                            feedbackMessage =
                                                'Assignment deleted.';
                                            feedbackIsError = false;
                                          });
                                        } catch (e) {
                                          if (!sheetContext.mounted) return;
                                          setSheetState(() {
                                            feedbackMessage =
                                                formatSupabaseError(e);
                                            feedbackIsError = true;
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    maxScoreCtrl.dispose();
  }

  Future<void> _openManageEnrollmentsSheet(OfficialClassRecord record) async {
    final emailCtrl = TextEditingController();
    List<EnrollmentRecord> enrollments = [];
    bool loading = true;
    String? error;

    Future<void> load(StateSetter setSheetState) async {
      setSheetState(() {
        loading = true;
        error = null;
      });
      try {
        enrollments = await ClassService.getClassEnrollments(record.id);
        setSheetState(() => loading = false);
      } catch (e) {
        setSheetState(() {
          loading = false;
          error = formatSupabaseError(e);
        });
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (loading && enrollments.isEmpty && error == null) {
              Future.microtask(() => load(setSheetState));
            }
            final pending =
                enrollments.where((e) => e.status == 'pending').toList();
            final approved =
                enrollments.where((e) => e.status == 'approved').toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SizedBox(
                height: 460,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.subjectCode} · ${record.section} Students',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Enroll student by email',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            if (emailCtrl.text.trim().isEmpty) return;
                            try {
                              await ClassService.enrollStudentByEmail(
                                classId: record.id,
                                studentEmail: emailCtrl.text,
                              );
                              emailCtrl.clear();
                              await load(setSheetState);
                              await _loadDashboardData();
                            } catch (e) {
                              if (mounted) showMessage(formatSupabaseError(e));
                            }
                          },
                          child: const Text('Enroll'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                              ? Center(child: Text(error!))
                              : ListView(
                                  children: [
                                    if (pending.isNotEmpty) ...[
                                      const Text(
                                        'Pending Requests',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _navy,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...pending.map(
                                        (e) => ListTile(
                                          dense: true,
                                          title: Text(e.studentName),
                                          subtitle: Text(e.studentEmail),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.success,
                                                ),
                                                onPressed: () async {
                                                  await ClassService
                                                      .updateEnrollmentStatus(
                                                    enrollmentId: e.id,
                                                    status: 'approved',
                                                  );
                                                  await load(setSheetState);
                                                  await _loadDashboardData();
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: AppColors.danger,
                                                ),
                                                onPressed: () async {
                                                  await ClassService
                                                      .updateEnrollmentStatus(
                                                    enrollmentId: e.id,
                                                    status: 'rejected',
                                                  );
                                                  await load(setSheetState);
                                                  await _loadDashboardData();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(),
                                    ],
                                    Text(
                                      'Enrolled Students (${approved.length})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _navy,
                                      ),
                                    ),
                                    if (approved.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          'No enrolled students yet.',
                                          style: TextStyle(color: _muted),
                                        ),
                                      )
                                    else
                                      ...approved.map(
                                        (e) => ListTile(
                                          dense: true,
                                          leading: const Icon(
                                            Icons.person_outline,
                                            size: 20,
                                          ),
                                          title: Text(e.studentName),
                                          subtitle: Text(e.studentEmail),
                                        ),
                                      ),
                                  ],
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    emailCtrl.dispose();
  }

  // ============================================================
  // CLASS FILTER BUTTON
  // ============================================================

  Widget buildClassFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _blue : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _muted,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGNED CLASS CARD
  // ============================================================

  Widget buildAssignedClassCard(Map<String, String> classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstructorAttendanceScreen(
                classItem: classItem,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _ice,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.bookOpen,
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
                          classItem['subject']!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${classItem['code']} · ${classItem['section']}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: _blue,
                    size: 21,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              _classInfoRow(
                LucideIcons.clock,
                classItem['schedule']!,
              ),

              const SizedBox(height: 8),

              _classInfoRow(
                LucideIcons.mapPin,
                classItem['room']!,
              ),

              const SizedBox(height: 8),

              _classInfoRow(
                LucideIcons.users,
                classItem['students']!,
              ),

              const SizedBox(height: 8),

              _classInfoRow(
                LucideIcons.userRound,
                classItem['instructor']!,
              ),

              const SizedBox(height: 13),

              const Divider(color: _border, height: 1),

              const SizedBox(height: 12),

              const Row(
                children: [
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 16,
                    color: _blue,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Open class workspace',
                    style: TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHomeScreen(),
      buildClassesScreen(),
      buildAnnouncementsScreen(),
      const InstructorProfile(),
    ];

    const destinations = [
      AcademicNavDestination(
        icon: LucideIcons.layoutDashboard,
        label: 'Overview',
      ),
      AcademicNavDestination(
        icon: LucideIcons.bookOpen,
        label: 'Classes',
      ),
      AcademicNavDestination(
        icon: LucideIcons.megaphone,
        label: 'Announcements',
      ),
      AcademicNavDestination(
        icon: LucideIcons.userRound,
        label: 'Profile',
      ),
    ];

    return AcademicNavigationShell(
      roleLabel: 'Instructor Portal',
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelected: (index) => setState(() => selectedIndex = index),
      sidebarAction: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _openCreateClassDialog,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('New Class'),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
    );
  }
}

// ============================================================
// INSTRUCTOR GLASS NAVIGATION ISLAND
// ============================================================

class InstructorGlassNavigationIsland extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const InstructorGlassNavigationIsland({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color _blue = AppColors.primary;
  static const Color _muted = AppColors.textSecondary;

  static const List<_InstructorNavItem> _items = [
    _InstructorNavItem(
      icon: LucideIcons.house,
      label: 'Home',
    ),
    _InstructorNavItem(
      icon: LucideIcons.bookOpen,
      label: 'Classes',
    ),
    _InstructorNavItem(
      icon: LucideIcons.megaphone,
      label: 'Announcements',
    ),
    _InstructorNavItem(
      icon: LucideIcons.userRound,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: List.generate(
                    _items.length,
                    (index) {
                      final item = _items[index];
                      final isSelected = selectedIndex == index;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 6,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onItemSelected(index),
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 250,
                                ),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.border,
                                          width: 0.8,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.08 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 22,
                                        color: isSelected
                                            ? _blue
                                            : _muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        color: isSelected
                                            ? _blue
                                            : _muted,
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INSTRUCTOR NAVIGATION ITEM
// ============================================================

class _InstructorNavItem {
  final IconData icon;
  final String label;

  const _InstructorNavItem({
    required this.icon,
    required this.label,
  });
}

// ============================================================
// CREATE / EDIT OFFICIAL CLASS MODAL
// ============================================================

class _OfficialClassFormDialog extends StatefulWidget {
  final OfficialClassRecord? existing;

  const _OfficialClassFormDialog({this.existing});

  @override
  State<_OfficialClassFormDialog> createState() =>
      _OfficialClassFormDialogState();
}

class _OfficialClassFormDialogState extends State<_OfficialClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sectionCtrl;
  late final TextEditingController _programCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _descCtrl;

  late List<ClassMeetingSchedule> _schedules;
  String? _scheduleError;
  String? _submitError;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl.text = e?.subjectCode ?? '';
    _nameCtrl = TextEditingController(text: e?.className ?? '');
    _sectionCtrl = TextEditingController(text: e?.section ?? 'Section A');
    _programCtrl = TextEditingController(text: e?.program ?? '');
    _yearCtrl = TextEditingController(text: e?.academicYear ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');

    if (e != null) {
      final loaded = e.effectiveSchedules;
      _schedules = loaded.isNotEmpty
          ? List<ClassMeetingSchedule>.from(loaded)
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
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    _programCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final schedErr = ClassMeetingSchedule.validateSchedules(
      _schedules,
      requireAtLeastOne: true,
    );

    setState(() {
      _scheduleError = schedErr;
      _submitError = null;
    });

    if (!formValid || schedErr != null) return;

    setState(() => _isSaving = true);
    try {
      final sortedSchedules = ClassMeetingSchedule.sortSchedules(_schedules);
      if (_isEditing) {
        await ClassService.updateOfficialClass(
          classId: widget.existing!.id,
          className: _nameCtrl.text,
          subjectCode: _codeCtrl.text,
          section: _sectionCtrl.text,
          academicYear: _yearCtrl.text,
          program: _programCtrl.text,
          schedules: sortedSchedules,
          description: _descCtrl.text,
        );
      } else {
        await ClassService.createOfficialClass(
          className: _nameCtrl.text,
          subjectCode: _codeCtrl.text,
          section: _sectionCtrl.text,
          academicYear: _yearCtrl.text,
          program: _programCtrl.text,
          schedules: sortedSchedules,
          description: _descCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _submitError = formatSupabaseError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 480;

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
          maxWidth: 520,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditing ? LucideIcons.pencil : LucideIcons.bookPlus,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Class' : 'Create Official Class',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'Update class details and weekly meetings'
                              : 'Set class details and weekly meeting schedules',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context, false),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // SCROLLABLE BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLASS DETAILS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isCompact) ...[
                        _buildTextField(
                          controller: _codeCtrl,
                          label: 'Subject Code',
                          hint: 'e.g. CS 304',
                          required: true,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _sectionCtrl,
                          label: 'Section',
                          hint: 'e.g. Section A',
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _codeCtrl,
                                label: 'Subject Code',
                                hint: 'e.g. CS 304',
                                required: true,
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _sectionCtrl,
                                label: 'Section',
                                hint: 'e.g. Section A',
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Class Name',
                        hint: 'e.g. Data Structures and Algorithms',
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      if (isCompact) ...[
                        _buildTextField(
                          controller: _programCtrl,
                          label: 'Program',
                          hint: 'e.g. BSCS',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _yearCtrl,
                          label: 'Academic Year',
                          hint: 'e.g. 2026-2027',
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _programCtrl,
                                label: 'Program',
                                hint: 'e.g. BSCS',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _yearCtrl,
                                label: 'Academic Year',
                                hint: 'e.g. 2026-2027',
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descCtrl,
                        label: 'Description',
                        hint: 'Optional course overview or notes',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),

                      // WEEKLY SCHEDULE EDITOR
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

                      if (_submitError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.dangerBorder),
                          ),
                          child: Text(
                            _submitError!,
                            style: const TextStyle(
                              color: AppColors.dangerDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER ACTIONS
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Create Class'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}

// ============================================================
// TODAY MEETING DATA CLASS
// ============================================================

class _InstructorTodayMeeting {
  final OfficialClassRecord record;
  final ClassMeetingSchedule meeting;
  final String meetingKey;
  final int recordedCount;

  const _InstructorTodayMeeting({
    required this.record,
    required this.meeting,
    required this.meetingKey,
    required this.recordedCount,
  });
}