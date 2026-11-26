import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/academic_service.dart';
import '../../services/class_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';

enum InstructorNotificationType {
  classReminder,
  enrollmentRequest,
  attendanceUpdate,
}

class InstructorNotificationItem {
  final String id;
  final String title;
  final String details;
  final DateTime timestamp;
  final InstructorNotificationType type;
  final String classId;
  final String? sessionId;

  const InstructorNotificationItem({
    required this.id,
    required this.title,
    required this.details,
    required this.timestamp,
    required this.type,
    required this.classId,
    this.sessionId,
  });

  IconData get icon => switch (type) {
    InstructorNotificationType.classReminder => LucideIcons.calendarDays,
    InstructorNotificationType.enrollmentRequest => LucideIcons.users,
    InstructorNotificationType.attendanceUpdate => LucideIcons.clipboardList,
  };
}

class InstructorNotificationLoadResult {
  final List<InstructorNotificationItem> notifications;
  final String? attendanceWarning;

  const InstructorNotificationLoadResult({
    required this.notifications,
    this.attendanceWarning,
  });
}

class InstructorNotificationService {
  static const int _reminderWindowDays = 7;

  static Future<InstructorNotificationLoadResult> load(
    List<OfficialClassRecord> classes,
  ) async {
    final activeClasses = classes
        .where((record) => !record.isArchived)
        .toList();
    final notifications = buildUpcomingClassReminders(activeClasses);
    if (activeClasses.isEmpty) {
      return InstructorNotificationLoadResult(notifications: notifications);
    }

    final pendingClasses = activeClasses
        .where((record) => record.pendingRequestCount > 0)
        .toList();
    final Future<List<List<EnrollmentRecord>>> pendingRequestsFuture =
        Future.wait<List<EnrollmentRecord>>(
          pendingClasses.map(
            (record) => ClassService.getClassEnrollments(record.id),
          ),
        );
    List<AttendanceSessionRecord> attendanceSessions = const [];
    String? attendanceWarning;
    try {
      attendanceSessions =
          await AcademicService.getRecentInstructorAttendanceSessions(
            classIds: activeClasses.map((record) => record.id).toList(),
          );
    } catch (error) {
      attendanceWarning = formatAttendanceSessionsError(error);
    }

    final pendingRequestsByClass = await pendingRequestsFuture;
    final classesById = {for (final record in activeClasses) record.id: record};

    for (var index = 0; index < pendingClasses.length; index++) {
      final record = pendingClasses[index];
      for (final enrollment in pendingRequestsByClass[index]) {
        if (enrollment.status != 'pending') continue;
        notifications.add(
          InstructorNotificationItem(
            id: 'enrollment:${enrollment.id}',
            title: 'New enrollment request',
            details:
                '${enrollment.studentName} requested to join '
                '${record.className} · ${record.section}.',
            timestamp: enrollment.enrolledAt.toUtc(),
            type: InstructorNotificationType.enrollmentRequest,
            classId: record.id,
          ),
        );
      }
    }

    for (final session in attendanceSessions) {
      final record = classesById[session.classId];
      if (record == null) continue;
      notifications.add(
        InstructorNotificationItem(
          id: 'attendance:${session.id}',
          title: 'Attendance updated',
          details:
              '${record.className} · '
              '${session.meetingLabel.trim().isEmpty ? _formatSessionDate(session.sessionDate) : session.meetingLabel}',
          timestamp: (session.createdAt ?? _manilaMidnight(session.sessionDate))
              .toUtc(),
          type: InstructorNotificationType.attendanceUpdate,
          classId: record.id,
          sessionId: session.id,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    notifications.sort((a, b) {
      final aUpcoming =
          a.type == InstructorNotificationType.classReminder &&
          a.timestamp.isAfter(now);
      final bUpcoming =
          b.type == InstructorNotificationType.classReminder &&
          b.timestamp.isAfter(now);
      if (aUpcoming != bUpcoming) return aUpcoming ? -1 : 1;
      return aUpcoming
          ? a.timestamp.compareTo(b.timestamp)
          : b.timestamp.compareTo(a.timestamp);
    });
    return InstructorNotificationLoadResult(
      notifications: notifications,
      attendanceWarning: attendanceWarning,
    );
  }

  static List<InstructorNotificationItem> buildUpcomingClassReminders(
    List<OfficialClassRecord> classes, {
    DateTime? manilaWallTime,
  }) {
    final now = manilaWallTime ?? _currentManilaWallTime();
    final reminders = <InstructorNotificationItem>[];

    for (final record in classes.where((item) => !item.isArchived)) {
      for (var dayOffset = 0; dayOffset < _reminderWindowDays; dayOffset++) {
        final day = DateTime.utc(now.year, now.month, now.day + dayOffset);
        for (final meeting in record.effectiveSchedules) {
          if (meeting.weekday != day.weekday) continue;

          final meetingWallTime = DateTime.utc(
            day.year,
            day.month,
            day.day,
          ).add(Duration(minutes: meeting.startMinutes));
          if (!meetingWallTime.isAfter(now)) continue;

          final dateId =
              '${day.year}-${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}';
          final meetingId =
              meeting.id ??
              '${meeting.weekday}_${meeting.startMinutes}_${meeting.endMinutes}';
          reminders.add(
            InstructorNotificationItem(
              id: 'class:${record.id}:$meetingId:$dateId',
              title: 'Upcoming class',
              details:
                  '${record.className} · ${record.section} · '
                  '${meeting.formattedTimeRange}',
              timestamp: meetingWallTime.subtract(const Duration(hours: 8)),
              type: InstructorNotificationType.classReminder,
              classId: record.id,
            ),
          );
        }
      }
    }

    reminders.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return reminders;
  }

  static DateTime _currentManilaWallTime() =>
      DateTime.now().toUtc().add(const Duration(hours: 8));

  static DateTime _manilaMidnight(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).subtract(const Duration(hours: 8));

  static String _formatSessionDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

class InstructorNotificationsScreen extends StatefulWidget {
  final List<InstructorNotificationItem> initialNotifications;
  final String? initialAttendanceWarning;
  final bool isLoading;
  final String? loadError;
  final Set<String> readIds;
  final Future<InstructorNotificationLoadResult> Function() onRefresh;
  final ValueChanged<InstructorNotificationLoadResult> onNotificationsChanged;
  final ValueChanged<String> onMarkAsRead;
  final Future<void> Function(InstructorNotificationItem item) onOpen;

  const InstructorNotificationsScreen({
    super.key,
    required this.initialNotifications,
    this.initialAttendanceWarning,
    required this.isLoading,
    required this.loadError,
    required this.readIds,
    required this.onRefresh,
    required this.onNotificationsChanged,
    required this.onMarkAsRead,
    required this.onOpen,
  });

  @override
  State<InstructorNotificationsScreen> createState() =>
      _InstructorNotificationsScreenState();
}

class _InstructorNotificationsScreenState
    extends State<InstructorNotificationsScreen> {
  late List<InstructorNotificationItem> _notifications;
  late Set<String> _readIds;
  late bool _isLoading;
  String? _loadError;
  String? _attendanceWarning;

  @override
  void initState() {
    super.initState();
    _notifications = List.of(widget.initialNotifications);
    _readIds = Set.of(widget.readIds);
    _isLoading = widget.isLoading;
    _loadError = widget.loadError;
    _attendanceWarning = widget.initialAttendanceWarning;
    if (_isLoading && _notifications.isEmpty) {
      unawaited(_reload());
    }
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final result = await widget.onRefresh();
      if (!mounted) return;
      setState(() {
        _notifications = result.notifications;
        _attendanceWarning = result.attendanceWarning;
        _isLoading = false;
        _loadError = null;
      });
      widget.onNotificationsChanged(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = formatSupabaseError(error);
      });
    }
  }

  void _markAsRead(String id) {
    if (!_readIds.add(id)) return;
    setState(() {});
    widget.onMarkAsRead(id);
  }

  Future<void> _open(InstructorNotificationItem item) async {
    _markAsRead(item.id);
    await widget.onOpen(item);
  }

  String _formatTimestamp(DateTime timestamp) {
    final manila = timestamp.toUtc().add(const Duration(hours: 8));
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final today = DateTime.utc(now.year, now.month, now.day);
    final itemDay = DateTime.utc(manila.year, manila.month, manila.day);
    final dateLabel = itemDay == today
        ? 'Today'
        : '${_month(manila.month)} ${manila.day}';
    final hour = manila.hour % 12 == 0 ? 12 : manila.hour % 12;
    final minute = manila.minute.toString().padLeft(2, '0');
    final period = manila.hour >= 12 ? 'PM' : 'AM';
    return '$dateLabel · $hour:$minute $period';
  }

  String _month(int month) => const [
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
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    final upcoming = _notifications
        .where((item) => item.type == InstructorNotificationType.classReminder)
        .toList();
    final activity = _notifications
        .where((item) => item.type != InstructorNotificationType.classReminder)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              ResponsiveContainer(
                maxWidth: 920,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcademicPageHeader(
                      eyebrow: 'Instructor',
                      title: 'Notifications',
                      subtitle: 'Class reminders and student activity',
                      onBack: () => Navigator.pop(context),
                    ),
                    if (_attendanceWarning != null)
                      _buildAttendanceWarning(_attendanceWarning!),
                    if (_isLoading && _notifications.isEmpty)
                      const _NotificationState(
                        icon: LucideIcons.loaderCircle,
                        title: 'Loading notifications',
                        details: 'Checking your classes and recent activity.',
                        showProgress: true,
                      )
                    else if (_loadError != null && _notifications.isEmpty)
                      _NotificationState(
                        icon: LucideIcons.circleAlert,
                        title: 'Could not load notifications',
                        details: _loadError!,
                        actionLabel: 'Try again',
                        onAction: _reload,
                      )
                    else if (_notifications.isEmpty)
                      const _NotificationState(
                        icon: LucideIcons.bell,
                        title: 'You’re all caught up',
                        details: 'Upcoming classes and new student activity will appear here.',
                      )
                    else ...[
                      if (upcoming.isNotEmpty) ...[
                        const _NotificationSectionTitle(
                          title: 'Upcoming classes',
                        ),
                        for (final item in upcoming)
                          _buildNotificationCard(item),
                      ],
                      if (activity.isNotEmpty) ...[
                        _NotificationSectionTitle(
                          title: 'Recent activity',
                          showTopPadding: upcoming.isNotEmpty,
                        ),
                        for (final item in activity)
                          _buildNotificationCard(item),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(InstructorNotificationItem item) {
    final isRead = _readIds.contains(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _open(item),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatTimestamp(item.timestamp),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
          if (!isRead)
            IconButton(
              tooltip: 'Mark as read',
              onPressed: () => _markAsRead(item.id),
              icon: const Icon(
                LucideIcons.circleCheck,
                color: AppColors.primary,
                size: 19,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                LucideIcons.circleCheck,
                color: AppColors.textMuted,
                size: 17,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceWarning(String message) {
    return SurfacePanel(
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
              'Attendance updates are unavailable. $message',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSectionTitle extends StatelessWidget {
  final String title;
  final bool showTopPadding;

  const _NotificationSectionTitle({
    required this.title,
    this.showTopPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, showTopPadding ? 18 : 2, 2, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String details;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NotificationState({
    required this.icon,
    required this.title,
    required this.details,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (showProgress)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, color: AppColors.primary, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            details,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
