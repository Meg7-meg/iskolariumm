
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/academic_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.navy;
  static const Color background = AppColors.background;
  static const Color muted = AppColors.textSecondary;
  static const Color border = AppColors.border;
  static const Color lightBlue = Color(0xFFEBF2FE);
  static const Color green = Color(0xFF16A36A);
  static const Color red = Color(0xFFE05252);

  bool _isLoading = true;
  String? _error;
  List<_SubjectAttendance> _subjects = const [];
  int _totalPresent = 0;
  int _totalAbsent = 0;
  int _overallPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await AcademicService.getStudentAttendance();
      final byClass = <String, List<AttendanceRecord>>{};
      for (final r in records) {
        byClass.putIfAbsent(r.classId, () => []).add(r);
      }

      int totalPresent = 0;
      int totalAbsent = 0;
      final grouped = <_SubjectAttendance>[];

      for (final entry in byClass.entries) {
        final list = entry.value;
        final first = list.first;
        final present = list
            .where((r) => r.status == 'present' || r.status == 'late')
            .length;
        final absent = list.where((r) => r.status == 'absent').length;
        final total = list.length;
        final pct = total > 0 ? ((present / total) * 100).round() : 0;

        totalPresent += present;
        totalAbsent += absent;

        grouped.add(
          _SubjectAttendance(
            name: first.className.isEmpty ? first.subjectCode : first.className,
            instructor: first.instructorName.isEmpty
                ? 'Instructor'
                : first.instructorName,
            present: present,
            absent: absent,
            percentage: pct,
          ),
        );
      }

      final totalAll = records.length;
      final overall = totalAll > 0 ? ((totalPresent / totalAll) * 100).round() : 0;

      if (!mounted) return;
      setState(() {
        _subjects = grouped;
        _totalPresent = totalPresent;
        _totalAbsent = totalAbsent;
        _overallPercent = overall;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = formatSupabaseError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 920,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _loadAttendance,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: primaryBlue,
                          onRefresh: _loadAttendance,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewCard(),
                                const SizedBox(height: 22),
                                _buildSummaryCards(),
                                const SizedBox(height: 28),
                                _buildSectionHeader(
                                  'Subject Attendance',
                                  'Your attendance per subject',
                                ),
                                const SizedBox(height: 14),
                                if (_subjects.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: border),
                                    ),
                                    child: const Text(
                                      'No attendance records yet. Records marked by your instructors will appear here.',
                                      style: TextStyle(color: muted, fontSize: 13),
                                    ),
                                  )
                                else
                                  ..._subjects.map(
                                    (subject) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildSubjectCard(subject),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                _buildSectionHeader(
                                  'Attendance Information',
                                  'Important reminders',
                                ),
                                const SizedBox(height: 14),
                                _buildInformationCard(),
                              ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: darkBlue,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkBlue,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Monitor your class attendance',
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              LucideIcons.calendarDays,
              color: primaryBlue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A56DB),
            Color(0xFF3478EF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overall Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      color: Colors.white,
                      size: 13,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Good standing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_overallPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your current attendance rate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: 0.92,
                        strokeWidth: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.22),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: Colors.white,
                  size: 17,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Keep attending your classes to maintain your attendance rate.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.checkCircle2,
            title: 'Present',
            value: '$_totalPresent',
            subtitle: 'Classes attended',
            color: green,
            iconBackground: const Color(0xFFE7F8EF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.xCircle,
            title: 'Absent',
            value: '$_totalAbsent',
            subtitle: 'Classes missed',
            color: red,
            iconBackground: const Color(0xFFFFEEEE),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: muted,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(_SubjectAttendance subject) {
    final Color progressColor =
        subject.percentage >= 90 ? green : primaryBlue;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.instructor,
                      style: const TextStyle(
                        fontSize: 10,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${subject.percentage}%',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: subject.percentage / 100,
              minHeight: 7,
              backgroundColor: lightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _attendanceLegend(
                color: green,
                label: '${subject.present} Present',
              ),
              const SizedBox(width: 16),
              _attendanceLegend(
                color: red,
                label: '${subject.absent} Absent',
              ),
              const Spacer(),
              const Text(
                'View only',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceLegend({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.lightbulb,
            color: primaryBlue,
            size: 21,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Reminder',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your attendance records are provided by your instructor. '
                  'If you notice an incorrect record, contact your instructor '
                  'for verification.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAttendance {
  final String name;
  final String instructor;
  final int present;
  final int absent;
  final int percentage;

  const _SubjectAttendance({
    required this.name,
    required this.instructor,
    required this.present,
    required this.absent,
    required this.percentage,
  });
}
