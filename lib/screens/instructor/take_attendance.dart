import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/academic_service.dart';
import '../../services/class_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';
import 'review_attendance.dart';

// ============================================================
// INSTRUCTOR ATTENDANCE SCREEN
// Swiss Design + Modern Minimalist
// ============================================================

class InstructorAttendanceScreen extends StatefulWidget {
  final Map<String, String> classItem;
  final String? scheduleId;
  final String? meetingKey;
  final String? meetingLabel;
  final bool correctionMode;
  final DateTime? correctionDate;
  final String? correctionSessionId;

  const InstructorAttendanceScreen({
    super.key,
    required this.classItem,
    this.scheduleId,
    this.meetingKey,
    this.meetingLabel,
    this.correctionMode = false,
    this.correctionDate,
    this.correctionSessionId,
  });

  @override
  State<InstructorAttendanceScreen> createState() =>
      _InstructorAttendanceScreenState();
}

class _InstructorAttendanceScreenState
    extends State<InstructorAttendanceScreen> {
  late DateTime selectedDate;

  final List<Map<String, dynamic>> students = [];
  final TextEditingController _correctionReasonController =
      TextEditingController();
  List<ClassMeetingSchedule> _schedules = const [];
  ClassMeetingSchedule? _selectedSchedule;
  AttendanceSessionRecord? _existingSession;
  late Future<_AttendanceHistoryData> _attendanceHistoryFuture;
  final Map<String, Future<List<AttendanceRecord>>> _historyDetailsFutures = {};
  final Set<String> _expandedHistorySessionIds = {};
  bool _isLoading = true;
  String? _loadError;
  String? _availabilityMessage;
  String? _sessionStorageError;
  bool _isAvailable = false;
  bool _isSavedCurrentSession = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    final date = widget.correctionDate ?? AcademicService.manilaToday;
    selectedDate = DateTime.utc(date.year, date.month, date.day);
    _attendanceHistoryFuture = _loadAttendanceHistory();
    _loadStudentsAndAttendance();
  }

  @override
  void dispose() {
    _correctionReasonController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<_AttendanceHistoryData> _loadAttendanceHistory() async {
    final classId = widget.classItem['id'];
    if (classId == null || classId.isEmpty) {
      throw Exception('Missing class ID.');
    }

    final loadedSessions = await AcademicService.getClassAttendanceSessions(
      classId,
    );
    final today = AcademicService.manilaToday;
    final sessions = loadedSessions
        .where(
          (session) =>
              session.sessionDate.year != today.year ||
              session.sessionDate.month != today.month ||
              session.sessionDate.day != today.day,
        )
        .toList(growable: false);
    final summaries = await AcademicService.getAttendanceSessionSummaries(
      classId: classId,
      sessionIds: sessions.map((session) => session.id).toList(),
    );
    return _AttendanceHistoryData(sessions: sessions, summaries: summaries);
  }

  Future<void> _refreshAttendanceHistory() async {
    setState(() {
      _attendanceHistoryFuture = _loadAttendanceHistory();
      _historyDetailsFutures.clear();
    });
    try {
      await _attendanceHistoryFuture;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatAttendanceSessionsError(error))),
        );
      }
    }
  }

  Future<void> _loadStudentsAndAttendance() async {
    final classId = widget.classItem['id'];
    if (classId == null || classId.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Missing class ID.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _availabilityMessage = null;
        _sessionStorageError = null;
        _isAvailable = false;
        _isSavedCurrentSession = false;
      });
    }

    try {
      final schedules = await ClassService.getClassSchedulesForAttendance(
        classId,
      );
      final dateSchedules = schedules
          .where((schedule) => schedule.weekday == selectedDate.weekday)
          .toList();
      ClassMeetingSchedule? selectedSchedule;
      if (widget.scheduleId != null) {
        for (final schedule in dateSchedules) {
          if (schedule.id == widget.scheduleId) {
            selectedSchedule = schedule;
            break;
          }
        }
      } else if (_selectedSchedule?.id != null) {
        for (final schedule in dateSchedules) {
          if (schedule.id == _selectedSchedule!.id) {
            selectedSchedule = schedule;
            break;
          }
        }
      }
      selectedSchedule ??= dateSchedules.isEmpty ? null : dateSchedules.first;

      final isToday =
          selectedDate.year == AcademicService.manilaToday.year &&
          selectedDate.month == AcademicService.manilaToday.month &&
          selectedDate.day == AcademicService.manilaToday.day;
      final isExistingSessionCorrection =
          widget.correctionMode && widget.correctionSessionId != null;
      if (!isExistingSessionCorrection &&
          (dateSchedules.isEmpty ||
              (widget.scheduleId != null && selectedSchedule?.id == null))) {
        if (!mounted) return;
        setState(() {
          _schedules = schedules;
          _selectedSchedule = null;
          _isLoading = false;
          _availabilityMessage = schedules.isEmpty
              ? 'No weekly class schedule is available. Attendance cannot be taken until a schedule is recorded.'
              : 'Attendance is unavailable on this date because the class has no scheduled meeting.'
                    '${_nextMeetingMessage(schedules)}';
        });
        return;
      }

      if (!widget.correctionMode && !isToday) {
        if (!mounted) return;
        setState(() {
          _schedules = schedules;
          _selectedSchedule = selectedSchedule;
          _isLoading = false;
          _availabilityMessage =
              'Regular attendance can only be taken for today in Manila time.';
        });
        return;
      }

      if (widget.correctionMode &&
          widget.correctionSessionId == null &&
          !selectedDate.isBefore(AcademicService.manilaToday)) {
        if (!mounted) return;
        setState(() {
          _schedules = schedules;
          _selectedSchedule = selectedSchedule;
          _isLoading = false;
          _availabilityMessage = 'Choose a past scheduled meeting date to record a missed meeting.';
        });
        return;
      }

      List<AttendanceSessionRecord> sessions = const [];
      String? sessionStorageError;
      try {
        sessions = await AcademicService.getClassAttendanceSessionsOn(
          classId,
          selectedDate,
        );
      } catch (error) {
        if (!isMissingSupabaseTable(error, 'attendance_sessions')) rethrow;
        sessionStorageError = formatAttendanceSessionsError(error);
      }

      if (sessionStorageError != null && widget.correctionMode) {
        if (!mounted) return;
        setState(() {
          _schedules = schedules;
          _selectedSchedule = selectedSchedule;
          _availabilityMessage = sessionStorageError;
          _sessionStorageError = sessionStorageError;
          _isLoading = false;
        });
        return;
      }

      AttendanceSessionRecord? existingSession;
      if (widget.correctionSessionId != null) {
        for (final session in sessions) {
          if (session.id == widget.correctionSessionId) {
            existingSession = session;
            break;
          }
        }
        if (existingSession == null) {
          throw Exception('The selected attendance session was not found.');
        }
      } else {
        final scheduleId = selectedSchedule?.id ?? widget.scheduleId;
        final meetingKey = widget.meetingKey?.trim().isNotEmpty == true
            ? widget.meetingKey!.trim()
            : (scheduleId ?? '').trim();
        existingSession = AcademicService.findAttendanceSessionForMeeting(
          sessions: sessions,
          meetingKey: meetingKey,
          scheduleId: scheduleId,
          hasSingleScheduledMeeting: dateSchedules.length == 1,
        );
      }

      if (widget.correctionMode &&
          widget.correctionSessionId == null &&
          existingSession != null) {
        if (!mounted) return;
        setState(() {
          _schedules = schedules;
          _selectedSchedule = selectedSchedule;
          _existingSession = existingSession;
          _isLoading = false;
          _availabilityMessage = 'An attendance session already exists for this date. Open it from Attendance History to make an audited correction.';
        });
        return;
      }

      final approved = existingSession == null
          ? (await ClassService.getClassEnrollments(classId))
                .where((enrollment) => enrollment.status == 'approved')
                .toList()
          : const [];
      final existingRecords = existingSession == null
          ? const <AttendanceRecord>[]
          : await AcademicService.getAttendanceSessionRecords(
              existingSession.id,
            );
      final roster = existingSession == null
          ? approved.map((enrollment) {
              return {
                'name': enrollment.studentName,
                'id': enrollment.studentId,
                'email': enrollment.studentEmail,
                'status': null,
                'remarks': '',
              };
            }).toList()
          : existingRecords.map((record) {
              return {
                'name': record.studentName,
                'id': record.studentId,
                'email': '',
                'status': _displayStatus(record.status),
                'remarks': record.remarks,
              };
            }).toList();

      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _selectedSchedule = selectedSchedule;
        _existingSession = existingSession;
        _sessionStorageError = sessionStorageError;
        _isSavedCurrentSession =
            !widget.correctionMode && existingSession != null;
        students
          ..clear()
          ..addAll(roster);
        _isLoading = false;
        _isAvailable = true;
        _availabilityMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = formatSupabaseError(e);
      });
    }
  }

  String _displayStatus(String status) {
    if (status.isEmpty) return status;
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
  }

  String _nextMeetingMessage(List<ClassMeetingSchedule> schedules) {
    final today = AcademicService.manilaToday;
    for (var offset = 1; offset <= 7; offset++) {
      final date = today.add(Duration(days: offset));
      final meetings = schedules
          .where((schedule) => schedule.weekday == date.weekday)
          .toList();
      if (meetings.isNotEmpty) {
        return ' Next scheduled meeting: ${_formatDate(date)} (${meetings.first.formattedTimeRange}).';
      }
    }
    return '';
  }

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

  Future<void> selectClassDate() async {
    if (!widget.correctionMode ||
        widget.correctionSessionId != null ||
        _schedules.isEmpty) {
      return;
    }
    final today = AcademicService.manilaToday;
    DateTime? nearestPastScheduledDate;
    for (var offset = 1; offset <= 366; offset++) {
      final candidate = today.subtract(Duration(days: offset));
      if (_schedules.any((schedule) => schedule.weekday == candidate.weekday)) {
        nearestPastScheduledDate = candidate;
        break;
      }
    }
    if (nearestPastScheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No past scheduled meeting date was found.'),
        ),
      );
      return;
    }

    final initialDate =
        selectedDate.isBefore(today) &&
            _schedules.any(
              (schedule) => schedule.weekday == selectedDate.weekday,
            )
        ? selectedDate
        : nearestPastScheduledDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today.subtract(const Duration(days: 1)),
      selectableDayPredicate: (date) =>
          _schedules.any((schedule) => schedule.weekday == date.weekday),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = DateTime.utc(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
        students.clear();
        _existingSession = null;
      });
      await _loadStudentsAndAttendance();
    }
  }

  String get formattedDate {
    return _formatDate(selectedDate);
  }

  // ============================================================
  // COMPUTED COUNTS
  // ============================================================

  int get presentCount =>
      students.where((s) => s['status'] == 'Present').length;

  int get absentCount => students.where((s) => s['status'] == 'Absent').length;

  int get lateCount => students.where((s) => s['status'] == 'Late').length;

  int get excusedCount =>
      students.where((s) => s['status'] == 'Excused').length;

  int get unmarkedCount => students.where((s) => s['status'] == null).length;

  int get totalStudents => students.length;

  // ============================================================
  // MARK ATTENDANCE
  // ============================================================

  void updateAttendance(int index, String status) {
    if (_sessionStorageError != null) return;
    setState(() {
      students[index]['status'] = status;
    });
  }

  // ============================================================
  // NAVIGATE TO REVIEW
  // ============================================================

  Future<void> reviewAttendance() async {
    if (!_isAvailable ||
        _sessionStorageError != null ||
        (_isSavedCurrentSession && !widget.correctionMode) ||
        unmarkedCount > 0 ||
        (widget.correctionMode &&
            _correctionReasonController.text.trim().isEmpty)) {
      return;
    }

    final selectedSchedule = _selectedSchedule;
    final scheduleId =
        _existingSession?.scheduleId ??
        selectedSchedule?.id ??
        widget.scheduleId;
    final meetingKey =
        _existingSession?.meetingKey ??
        widget.meetingKey ??
        selectedSchedule?.id ??
        '';
    final meetingLabel =
        _existingSession?.meetingLabel ??
        widget.meetingLabel ??
        selectedSchedule?.formattedSummary ??
        '';
    final room = _existingSession?.room ?? selectedSchedule?.room ?? '';

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorReviewAttendanceScreen(
          classItem: widget.classItem,
          students: students.map((s) => Map<String, dynamic>.from(s)).toList(),
          selectedDate: selectedDate,
          scheduleId: scheduleId,
          meetingKey: meetingKey,
          meetingLabel: meetingLabel,
          room: room,
          correctionMode: widget.correctionMode,
          correctionSessionId: _existingSession?.id,
          correctionReason: _correctionReasonController.text.trim(),
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // STATUS BADGE COLOR HELPERS (monochromatic)
  // ============================================================

  Color _statusFg(String? status) {
    switch (status) {
      case 'Present':
        return AppColors.primary;
      case 'Absent':
        return AppColors.textPrimary;
      case 'Late':
        return AppColors.textSecondary;
      case 'Excused':
        return AppColors.textSecondary;
      default:
        return AppColors.warningDark;
    }
  }

  Color _statusBg(String? status) {
    switch (status) {
      case 'Present':
        return AppColors.primaryLight;
      case 'Absent':
        return AppColors.surfaceSoft;
      case 'Late':
        return AppColors.surfaceSoft;
      case 'Excused':
        return AppColors.surfaceSoft;
      default:
        return AppColors.warningLight;
    }
  }

  // ============================================================
  // STUDENT ATTENDANCE CARD
  // ============================================================

  Widget _buildStudentCard(int index) {
    final student = students[index];
    final String? status = student['status'];
    final bool isUnmarked = status == null;
    final bool isReadOnly =
        (_isSavedCurrentSession && !widget.correctionMode) ||
        _sessionStorageError != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isUnmarked ? AppColors.warningBorder : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // — Student info row —
            Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    LucideIcons.userRound,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                // Name + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] as String? ?? '',
                        style: AppTextStyles.cardHeading,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student['id'] as String? ?? '',
                        style: AppTextStyles.meta,
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status ?? 'Unmarked',
                    style: TextStyle(
                      color: _statusFg(status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            if (isReadOnly) ...[
              if ((student['remarks'] as String? ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Remark: ${student['remarks']}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPrimaryButton(
                      label: 'Present',
                      isSelected: status == 'Present',
                      onTap: () => updateAttendance(index, 'Present'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSecondaryButton(
                      label: 'Absent',
                      isSelected: status == 'Absent',
                      onTap: () => updateAttendance(index, 'Absent'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildMoreButton(index, status),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey('attendance-remark-${student['id']}'),
                initialValue: student['remarks'] as String? ?? '',
                maxLines: 2,
                minLines: 1,
                onChanged: (value) => student['remarks'] = value,
                decoration: InputDecoration(
                  hintText: 'Optional remark',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON BUILDERS
  // ============================================================

  /// Blue filled button — "Present"
  Widget _buildPrimaryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 38,
      child: isSelected
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  /// Neutral outlined button — "Absent"
  Widget _buildSecondaryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 38,
      child: isSelected
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  /// "More" popup for Late / Excused
  Widget _buildMoreButton(int index, String? currentStatus) {
    final bool isMoreSelected =
        currentStatus == 'Late' || currentStatus == 'Excused';

    return SizedBox(
      height: 38,
      child: PopupMenuButton<String>(
        onSelected: (val) => updateAttendance(index, val),
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        elevation: 2,
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'Late',
            child: Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 15,
                  color: currentStatus == 'Late'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Late',
                  style: TextStyle(
                    color: currentStatus == 'Late'
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: currentStatus == 'Late'
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (currentStatus == 'Late') ...[
                  const Spacer(),
                  const Icon(
                    LucideIcons.check,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Excused',
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileCheck,
                  size: 15,
                  color: currentStatus == 'Excused'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Excused',
                  style: TextStyle(
                    color: currentStatus == 'Excused'
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: currentStatus == 'Excused'
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (currentStatus == 'Excused') ...[
                  const Spacer(),
                  const Icon(
                    LucideIcons.check,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ],
        child: Container(
          width: 38,
          decoration: BoxDecoration(
            color: isMoreSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isMoreSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Icon(
            LucideIcons.moreHorizontal,
            size: 16,
            color: isMoreSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY STRIP
  // ============================================================

  Widget _buildSummaryStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Primary stats row
          Row(
            children: [
              _buildStatBlock(
                value: '$presentCount',
                label: 'Present',
                valueColor: AppColors.primary,
              ),
              _buildStatDivider(),
              _buildStatBlock(
                value: '$absentCount',
                label: 'Absent',
                valueColor: AppColors.textPrimary,
              ),
              _buildStatDivider(),
              _buildStatBlock(
                value: '$unmarkedCount',
                label: 'Unmarked',
                valueColor: unmarkedCount > 0
                    ? AppColors.warningDark
                    : AppColors.textSecondary,
              ),
            ],
          ),

          // Secondary stats (only show if any exist)
          if (lateCount > 0 || excusedCount > 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                if (lateCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$lateCount Late',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (excusedCount > 0)
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.fileCheck,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$excusedCount Excused',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],

          // Progress bar (marked / total)
          if (totalStudents > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalStudents > 0
                    ? (totalStudents - unmarkedCount) / totalStudents
                    : 0.0,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${totalStudents - unmarkedCount} of $totalStudents marked',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBlock({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ============================================================
  // COMPLETION BANNER
  // ============================================================

  Widget _buildCompletionBanner(bool allMarked) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: allMarked ? AppColors.primaryLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: allMarked
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.warningBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            allMarked ? LucideIcons.checkCircle : LucideIcons.alertCircle,
            size: 16,
            color: allMarked ? AppColors.primary : AppColors.warningDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              allMarked
                  ? 'All students marked — ready to review.'
                  : '$unmarkedCount student(s) still need an attendance status.',
              style: TextStyle(
                color: allMarked ? AppColors.primary : AppColors.warningDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPanel() {
    return SurfacePanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.calendarX2,
            size: 20,
            color: AppColors.warningDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _availabilityMessage ?? 'Attendance is unavailable.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _historyMeetingLabel(AttendanceSessionRecord session) {
    final savedLabel = session.meetingLabel.trim();
    if (savedLabel.isNotEmpty) return savedLabel;

    for (final schedule in _schedules) {
      if (session.scheduleId != null && schedule.id == session.scheduleId) {
        return schedule.formattedSummary;
      }
    }
    for (final schedule in _schedules) {
      if (schedule.weekday == session.sessionDate.weekday) {
        return schedule.formattedSummary;
      }
    }
    return 'Scheduled meeting';
  }

  String _historyStatusSummary(Map<String, int>? summary) {
    const labels = {
      'present': 'Present',
      'absent': 'Absent',
      'late': 'Late',
      'excused': 'Excused',
    };
    final parts = <String>[];
    for (final entry in labels.entries) {
      final count = summary?[entry.key] ?? 0;
      if (count > 0) parts.add('${entry.value} $count');
    }
    return parts.isEmpty ? 'No student records' : parts.join(' · ');
  }

  Future<void> _openHistoricalCorrection(
    AttendanceSessionRecord session,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InstructorAttendanceScreen(
          classItem: widget.classItem,
          correctionMode: true,
          correctionDate: session.sessionDate,
          correctionSessionId: session.id,
          scheduleId: session.scheduleId,
          meetingKey: session.meetingKey,
          meetingLabel: session.meetingLabel,
        ),
      ),
    );
    if (result == true && mounted) {
      await _loadStudentsAndAttendance();
      await _refreshAttendanceHistory();
    }
  }

  Widget _buildAttendanceHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance History', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 8),
        Text(
          'Previously recorded meetings for this class.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        FutureBuilder<_AttendanceHistoryData>(
          future: _attendanceHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return AsyncErrorView(
                message: formatAttendanceSessionsError(snapshot.error!),
                onRetry: _refreshAttendanceHistory,
              );
            }

            final history = snapshot.data!;
            if (history.sessions.isEmpty) {
              return const EmptyStateView(
                icon: LucideIcons.calendarClock,
                title: 'No attendance history',
                message:
                    'Saved attendance from previous meetings will appear here.',
              );
            }

            return Column(
              children: history.sessions
                  .map(
                    (session) => _buildHistorySessionCard(
                      session,
                      history.summaries[session.id],
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistorySessionCard(
    AttendanceSessionRecord session,
    Map<String, int>? summary,
  ) {
    final isExpanded = _expandedHistorySessionIds.contains(session.id);
    final detailsFuture = isExpanded
        ? _historyDetailsFutures.putIfAbsent(
            session.id,
            () => AcademicService.getAttendanceSessionRecords(session.id),
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('attendance-history-${session.id}'),
        leading: const Icon(
          LucideIcons.calendarCheck,
          color: AppColors.primary,
          size: 19,
        ),
        title: Text(
          _formatDate(session.sessionDate),
          style: AppTextStyles.cardHeading,
        ),
        subtitle: Text(
          '${_historyMeetingLabel(session)}\n'
          '${_historyStatusSummary(summary)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.meta,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedHistorySessionIds.add(session.id);
            } else {
              _expandedHistorySessionIds.remove(session.id);
            }
          });
        },
        children: detailsFuture == null
            ? const []
            : [
                FutureBuilder<List<AttendanceRecord>>(
                  future: detailsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return AsyncErrorView(
                        message: formatSupabaseError(snapshot.error!),
                        onRetry: () {
                          setState(() {
                            _historyDetailsFutures[session.id] =
                                AcademicService.getAttendanceSessionRecords(
                                  session.id,
                                );
                          });
                        },
                      );
                    }

                    final records = snapshot.data ?? const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SurfacePanel(
                          padding: const EdgeInsets.all(12),
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.eye,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Viewing a past meeting · Read-only',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No student records were found for this session.',
                              style: AppTextStyles.bodySmall,
                            ),
                          )
                        else
                          ...records.map(_buildHistoryRecord),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openHistoricalCorrection(session),
                            icon: const Icon(LucideIcons.filePenLine, size: 16),
                            label: const Text('Correct this session'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
      ),
    );
  }

  Widget _buildHistoryRecord(AttendanceRecord record) {
    final status = _displayStatus(record.status);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(record.studentName, style: AppTextStyles.cardHeading),
      subtitle: record.remarks.trim().isEmpty
          ? Text(record.studentId, style: AppTextStyles.meta)
          : Text('${record.studentId} · ${record.remarks}'),
      trailing: StatusBadge(
        label: status,
        color: _statusFg(status),
        backgroundColor: _statusBg(status),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool allMarked = students.isNotEmpty && unmarkedCount == 0;
    final bool isReadOnlyCurrentSession =
        _isSavedCurrentSession && !widget.correctionMode;
    final isMissedMeetingCorrection =
        widget.correctionMode && widget.correctionSessionId == null;
    final savedMeetingLabel = _existingSession?.meetingLabel.trim() ?? '';
    final providedMeetingLabel = widget.meetingLabel?.trim() ?? '';
    final meetingLabel = savedMeetingLabel.isNotEmpty
        ? savedMeetingLabel
        : providedMeetingLabel.isNotEmpty
        ? providedMeetingLabel
        : _selectedSchedule?.formattedSummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: ResponsiveContainer(
            maxWidth: 920,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                AcademicPageHeader(
                  eyebrow: 'Instructor · Attendance',
                  title: widget.correctionMode
                      ? 'Attendance Correction'
                      : 'Attendance',
                  subtitle: widget.correctionMode
                      ? 'Authorized correction · audit reason required'
                      : 'Record attendance for today’s scheduled meeting',
                  onBack: () => Navigator.pop(context),
                ),

                // CLASS INFORMATION PANEL
                SurfacePanel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(
                          LucideIcons.bookOpen,
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
                              widget.classItem['subject'] ?? '',
                              style: AppTextStyles.cardHeading,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.classItem['code']} · ${widget.classItem['section']}',
                              style: AppTextStyles.meta,
                            ),
                            if (meetingLabel != null &&
                                meetingLabel.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                meetingLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      StatusBadge(
                        label:
                            widget.classItem['students'] ??
                            '$totalStudents students',
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                        icon: LucideIcons.users,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  isMissedMeetingCorrection
                      ? 'Past meeting date'
                      : 'Meeting date',
                  style: AppTextStyles.sectionHeading,
                ),

                const SizedBox(height: 8),

                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: InkWell(
                    onTap: isMissedMeetingCorrection ? selectClassDate : null,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
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
                              '$formattedDate · Manila time',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isMissedMeetingCorrection)
                            const Icon(
                              LucideIcons.chevronDown,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (_loadError != null)
                  AsyncErrorView(
                    message: _loadError!,
                    onRetry: _loadStudentsAndAttendance,
                  )
                else if (!_isAvailable)
                  _buildAvailabilityPanel()
                else ...[
                  if (_sessionStorageError != null) ...[
                    SurfacePanel(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.circleAlert,
                            color: AppColors.warningDark,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _sessionStorageError!,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (students.isEmpty)
                    const EmptyStateView(
                      icon: LucideIcons.users,
                      title: 'No students enrolled',
                      message:
                          'No approved students are enrolled in this course.',
                    )
                  else ...[
                    if (isReadOnlyCurrentSession) ...[
                      SurfacePanel(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  LucideIcons.circleCheck,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Attendance is saved for this meeting. These records are read-only.',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_existingSession != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _openHistoricalCorrection(
                                    _existingSession!,
                                  ),
                                  icon: const Icon(
                                    LucideIcons.filePenLine,
                                    size: 15,
                                  ),
                                  label: const Text('Correct attendance'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.correctionMode) ...[
                      TextFormField(
                        controller: _correctionReasonController,
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Correction reason',
                          hintText: 'Explain why these records need correction',
                          prefixIcon: Icon(LucideIcons.filePenLine),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildSummaryStrip(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isReadOnlyCurrentSession
                              ? 'Saved student attendance'
                              : 'Student attendance',
                          style: AppTextStyles.sectionHeading,
                        ),
                        StatusBadge(
                          label: '$totalStudents students',
                          color: AppColors.primary,
                          backgroundColor: AppColors.primaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (!isReadOnlyCurrentSession) ...[
                      Text(
                        'Tap Present or Absent. Use ··· for Late or Excused.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),
                    ],
                    ...List.generate(
                      students.length,
                      (i) => _buildStudentCard(i),
                    ),
                    if (!isReadOnlyCurrentSession) ...[
                      const SizedBox(height: 16),
                      _buildCompletionBanner(allMarked),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _sessionStorageError == null &&
                                  allMarked &&
                                  (!widget.correctionMode ||
                                      _correctionReasonController.text
                                          .trim()
                                          .isNotEmpty)
                              ? reviewAttendance
                              : null,
                          icon: Icon(
                            allMarked
                                ? LucideIcons.clipboardCheck
                                : LucideIcons.lock,
                            size: 17,
                          ),
                          label: Text(
                            widget.correctionMode
                                ? 'Review correction'
                                : 'Review attendance',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            disabledBackgroundColor: AppColors.surfaceSoft,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: AppColors.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          widget.correctionMode
                              ? 'Changes are saved with the correction reason.'
                              : 'Attendance is not saved until you confirm.',
                          style: AppTextStyles.meta,
                        ),
                      ),
                    ],
                  ],
                ],

                const SizedBox(height: 28),
                _buildAttendanceHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceHistoryData {
  final List<AttendanceSessionRecord> sessions;
  final Map<String, Map<String, int>> summaries;

  const _AttendanceHistoryData({
    required this.sessions,
    required this.summaries,
  });
}
