
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../src/app_colors.dart';

// ============================================================
// ISKOLARIUM - STUDENT DASHBOARD
// Frontend version using sample data
// ============================================================

class StudentDashboard extends StatelessWidget {
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
    onRefresh();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // HEADER
                  Container(
                    height: 265,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(34),
                        bottomRight: Radius.circular(34),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ISKOLARIUM',
                                      style: TextStyle(
                                        color: Color(0xFFDCE8FF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.2,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      '${getGreeting()}, Student!',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.calendarDays,
                                          size: 14,
                                          color: Color(0xFFDCE8FF),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            getFormattedDate(),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFFDCE8FF),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _DashboardNotificationButton(
                                onPressed: onOpenNotifications,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Stay organized. Stay on track.',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // DASHBOARD CONTENT
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 215,
                      left: 15,
                      right: 15,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(17, 22, 17, 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: darkBlue.withValues(alpha: 0.07),
                            blurRadius: 22,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // OVERVIEW TITLE
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Your Overview',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              Text(
                                'THIS WEEK',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // RESPONSIVE SUMMARY CARDS
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 9.0;
                              final cardWidth =
                                  (constraints.maxWidth - spacing) / 2;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: const _DashboardSummaryCard(
                                      icon: LucideIcons.bookOpen,
                                      value: '5',
                                      label: 'Classes',
                                      accentColor: AppColors.primary,
                                      accentLight: AppColors.primaryLight,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: const _DashboardSummaryCard(
                                      icon: LucideIcons.clipboardList,
                                      value: '3',
                                      label: 'Tasks Due',
                                      accentColor: AppColors.warning,
                                      accentLight: AppColors.warningLight,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DashboardSummaryCard(
                                      icon: LucideIcons.chartNoAxesColumnIncreasing,
                                      value: '92%',
                                      label: 'Attendance',
                                      accentColor: AppColors.success,
                                      accentLight: AppColors.successLight,
                                      onTap: onOpenAttendance,
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
                                      onTap: onOpenScores,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 27),

                          // TODAY'S SCHEDULE
                          _DashboardSectionTitle(
                            title: "Today's Schedule",
                            action: 'See all',
                            onTap: onOpenClasses,
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
                            child: const Column(
                              children: [
                                _DashboardScheduleRow(
                                  time: '9:00',
                                  period: 'AM',
                                  title: 'Database Systems',
                                  details: 'Room 204 · Dr. Anderson',
                                  isHighlighted: true,
                                ),
                                Divider(height: 1, color: border),
                                _DashboardScheduleRow(
                                  time: '1:30',
                                  period: 'PM',
                                  title: 'Web Design',
                                  details: 'Studio 3 · Prof. Green',
                                  isHighlighted: false,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 26),

                          // UPCOMING DEADLINE
                          _DashboardSectionTitle(
                            title: 'Upcoming Deadline',
                            action: 'View tasks',
                            onTap: onOpenTasks,
                          ),
                          const SizedBox(height: 12),
                          _UpcomingDeadlineCard(
                            onTap: onOpenTasks,
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
                            onTap: onOpenStudySessions,
                          ),
                        ],
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
  }
}

// ============================================================
// NOTIFICATION BUTTON
// ============================================================

class _DashboardNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DashboardNotificationButton({
    required this.onPressed,
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
// SCHEDULE ROW
// ============================================================

class _DashboardScheduleRow extends StatelessWidget {
  final String time;
  final String period;
  final String title;
  final String details;
  final bool isHighlighted;

  const _DashboardScheduleRow({
    required this.time,
    required this.period,
    required this.title,
    required this.details,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: StudentDashboard.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  period,
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
            height: 42,
            decoration: BoxDecoration(
              color: isHighlighted
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentDashboard.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentDashboard.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isHighlighted) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'UP NEXT',
                style: TextStyle(
                  color: StudentDashboard.primaryBlue,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// UPCOMING DEADLINE CARD
// ============================================================

class _UpcomingDeadlineCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UpcomingDeadlineCard({
    required this.onTap,
  });

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
                child: const Center(
                  child: Text(
                    'DB',
                    style: TextStyle(
                      color: AppColors.warningDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Normalization Worksheet',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: StudentDashboard.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Database Systems',
                      style: TextStyle(
                        color: StudentDashboard.muted,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          color: AppColors.warning,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Due tomorrow',
                          style: TextStyle(
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
