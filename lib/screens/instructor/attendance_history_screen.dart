import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/academic_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';
import 'take_attendance.dart';

class InstructorAttendanceHistoryScreen extends StatefulWidget {
  final Map<String, String> classItem;
  final String? initialSessionId;

  const InstructorAttendanceHistoryScreen({
    super.key,
    required this.classItem,
    this.initialSessionId,
  });

  @override
  State<InstructorAttendanceHistoryScreen> createState() =>
      _InstructorAttendanceHistoryScreenState();
}

class _InstructorAttendanceHistoryScreenState
    extends State<InstructorAttendanceHistoryScreen> {
  late Future<List<AttendanceSessionRecord>> _sessionsFuture;
  final Map<String, Future<_AttendanceSessionDetails>> _detailsFutures = {};
  final Set<String> _expandedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
    if (widget.initialSessionId != null) {
      _expandedSessionIds.add(widget.initialSessionId!);
    }
  }

  Future<List<AttendanceSessionRecord>> _loadSessions() async {
    final classId = widget.classItem['id'];
    if (classId == null || classId.isEmpty) {
      throw Exception('Missing class ID.');
    }
    return AcademicService.getClassAttendanceSessions(classId);
  }

  Future<_AttendanceSessionDetails> _loadSessionDetails(
    String sessionId,
  ) async {
    final records = await AcademicService.getAttendanceSessionRecords(
      sessionId,
    );
    final audit = await AcademicService.getAttendanceCorrectionHistory(
      sessionId,
    );
    return _AttendanceSessionDetails(records: records, audit: audit);
  }

  Future<void> _reload() async {
    setState(() {
      _sessionsFuture = _loadSessions();
      _detailsFutures.clear();
    });
    try {
      await _sessionsFuture;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatAttendanceSessionsError(error))),
        );
      }
    }
  }

  Future<void> _openCorrection(AttendanceSessionRecord session) async {
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
    if (result == true && mounted) await _reload();
  }

  Future<void> _recordMissedMeeting() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InstructorAttendanceScreen(
          classItem: widget.classItem,
          correctionMode: true,
        ),
      ),
    );
    if (result == true && mounted) await _reload();
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

  String _formatManilaTimestamp(DateTime date) {
    final manila = date.toUtc().add(const Duration(hours: 8));
    final hour = manila.hour % 12 == 0 ? 12 : manila.hour % 12;
    final minute = manila.minute.toString().padLeft(2, '0');
    final period = manila.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(manila)} · $hour:$minute $period Manila';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              ResponsiveContainer(
                maxWidth: 920,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcademicPageHeader(
                      eyebrow: 'Instructor · Attendance',
                      title: 'Attendance History',
                      subtitle:
                          '${widget.classItem['subject'] ?? 'Class'} · '
                          '${widget.classItem['code'] ?? ''} · '
                          '${widget.classItem['section'] ?? ''}',
                      onBack: () => Navigator.pop(context),
                    ),
                    SurfacePanel(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.history,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Past records remain available here. Corrections and missed meetings require a reason and are audited.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _recordMissedMeeting,
                        icon: const Icon(LucideIcons.calendarPlus, size: 16),
                        label: const Text('Record missed meeting'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Saved sessions', style: AppTextStyles.sectionHeading),
                    const SizedBox(height: 10),
                    FutureBuilder<List<AttendanceSessionRecord>>(
                      future: _sessionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return AsyncErrorView(
                            message: formatAttendanceSessionsError(
                              snapshot.error!,
                            ),
                            onRetry: _reload,
                          );
                        }
                        final sessions = snapshot.data ?? const [];
                        if (sessions.isEmpty) {
                          return const EmptyStateView(
                            icon: LucideIcons.calendarClock,
                            title: 'No attendance history',
                            message: 'Confirmed attendance sessions for this class will appear here.',
                          );
                        }
                        return Column(
                          children: sessions
                              .map(_buildSessionCard)
                              .toList(growable: false),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(AttendanceSessionRecord session) {
    final detailsFuture = _expandedSessionIds.contains(session.id)
        ? _detailsFutures.putIfAbsent(
            session.id,
            () => _loadSessionDetails(session.id),
          )
        : null;
    final label = session.meetingLabel.trim().isEmpty
        ? 'Scheduled meeting'
        : session.meetingLabel;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('attendance-session-${session.id}'),
        initiallyExpanded: session.id == widget.initialSessionId,
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
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.meta,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedSessionIds.add(session.id);
            } else {
              _expandedSessionIds.remove(session.id);
            }
          });
        },
        children: detailsFuture == null
            ? const []
            : [
                FutureBuilder<_AttendanceSessionDetails>(
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
                            _detailsFutures[session.id] = _loadSessionDetails(
                              session.id,
                            );
                          });
                        },
                      );
                    }

                    final details = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (details.records.isEmpty)
                          const Text(
                            'No student records were found for this session.',
                            style: AppTextStyles.bodySmall,
                          )
                        else
                          ...details.records.map(
                            (record) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                record.studentName,
                                style: AppTextStyles.cardHeading,
                              ),
                              subtitle: record.remarks.trim().isEmpty
                                  ? null
                                  : Text('Remark: ${record.remarks}'),
                              trailing: Text(
                                _capitalize(record.status),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        if (details.audit.isNotEmpty) ...[
                          const Divider(color: AppColors.border),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Correction audit',
                              style: AppTextStyles.sectionHeading,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...details.audit.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${entry.studentName}: '
                                '${entry.action == 'missed_meeting' ? 'missed meeting recorded' : 'corrected'}'
                                '${entry.oldStatus == null ? '' : ' (${_capitalize(entry.oldStatus!)} → ${_capitalize(entry.newStatus)})'}'
                                ' · ${entry.reason}\n'
                                'By ${entry.correctedByName} · '
                                '${_formatManilaTimestamp(entry.correctedAt)}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openCorrection(session),
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
}

class _AttendanceSessionDetails {
  final List<AttendanceRecord> records;
  final List<AttendanceCorrectionRecord> audit;

  const _AttendanceSessionDetails({required this.records, required this.audit});
}
