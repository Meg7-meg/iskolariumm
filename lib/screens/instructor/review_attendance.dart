import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../src/app_colors.dart';
import 'instructor_dashboard.dart';

// ============================================================
// INSTRUCTOR REVIEW ATTENDANCE SCREEN
// ============================================================

class InstructorReviewAttendanceScreen extends StatelessWidget {
  final Map<String, String> classItem;
  final List<Map<String, dynamic>> students;
  final DateTime selectedDate;

  const InstructorReviewAttendanceScreen({
    super.key,
    required this.classItem,
    required this.students,
    required this.selectedDate,
  });

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;
  static const Color _background = AppColors.background;

  // ============================================================
  // ATTENDANCE COUNTS
  // ============================================================

  int get presentCount =>
      students.where((student) => student['status'] == 'Present').length;

  int get absentCount =>
      students.where((student) => student['status'] == 'Absent').length;

  int get unmarkedCount =>
      students.where((student) => student['status'] == null).length;

  String get formattedDate {
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

    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  // ============================================================
  // ATTENDANCE SUMMARY CARD
  // ============================================================

  Widget buildSummaryCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color lightColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 19,
            ),

            const SizedBox(height: 12),

            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE STATUS COLORS
  // ============================================================

  Color getStatusColor(String? status) {
    switch (status) {
      case 'Present':
        return AppColors.success;

      case 'Absent':
        return AppColors.danger;

      default:
        return AppColors.warningDark;
    }
  }

  Color getStatusBackground(String? status) {
    switch (status) {
      case 'Present':
        return AppColors.successLight;

      case 'Absent':
        return AppColors.dangerLight;

      default:
        return AppColors.warningLight;
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'Present':
        return LucideIcons.checkCircle2;

      case 'Absent':
        return LucideIcons.xCircle;

      default:
        return LucideIcons.circleHelp;
    }
  }

  // ============================================================
  // ATTENDANCE STATUS BADGE
  // ============================================================

  Widget buildStatusBadge(String? status) {
    final Color foregroundColor = getStatusColor(status);
    final Color backgroundColor = getStatusBackground(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: 13,
            color: foregroundColor,
          ),

          const SizedBox(width: 5),

          Text(
            status ?? 'Unmarked',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT RECORD
  // ============================================================

  Widget buildStudentRecord(
    Map<String, dynamic> student,
    int index,
  ) {
    final String? status = student['status'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              LucideIcons.userRound,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String? ?? 'Unknown student',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  student['id'] as String? ?? '',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          buildStatusBadge(status),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION MESSAGE
  // ============================================================

  Widget buildValidationMessage() {
    final bool allMarked = unmarkedCount == 0;

    final Color color =
        allMarked ? AppColors.success : AppColors.warningDark;

    final Color lightColor =
        allMarked ? AppColors.successLight : AppColors.warningLight;

    final Color borderColor =
        allMarked ? AppColors.successBorder : AppColors.warningBorder;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allMarked
                ? LucideIcons.checkCircle2
                : LucideIcons.alertCircle,
            color: color,
            size: 20,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allMarked
                      ? 'Attendance is complete'
                      : 'Attendance is incomplete',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  allMarked
                      ? 'All students have been marked. Please verify the records before proceeding.'
                      : '$unmarkedCount student(s) are still unmarked. Go back and complete their attendance.',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE ATTENDANCE
  // ============================================================

  void saveAttendance(BuildContext context) {
    if (unmarkedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please mark every student before saving.',
          ),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          icon: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.database,
              color: AppColors.primary,
              size: 29,
            ),
          ),

          title: const Text(
            'Database connection pending',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: _navy,
            ),
          ),

          content: const Text(
            'Your attendance entries have been reviewed, but permanent saving to Supabase has not yet been connected to this screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),

          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),

          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CLASS INFORMATION CARD
  // ============================================================

  Widget buildClassInformation() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 17,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: Colors.white,
                  size: 19,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Text(
                  'CLASS INFORMATION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),

              const Icon(
                LucideIcons.clipboardCheck,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            classItem['subject'] ?? 'Class subject',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${classItem['code'] ?? ''} · '
            '${classItem['section'] ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (classItem['students'] != null) ...[
            const SizedBox(height: 13),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.users,
                    color: Colors.white,
                    size: 14,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    classItem['students']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool allMarked = unmarkedCount == 0;

    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            // PAGE LABEL
            const Text(
              'ISKOLARIUM · INSTRUCTOR',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // PAGE HEADER
            Row(
              children: [
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _border,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: _navy,
                        size: 23,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    'Review attendance',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(
                '$formattedDate · Review before confirmation',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // CLASS INFORMATION
            buildClassInformation(),

            const SizedBox(height: 24),

            // ATTENDANCE SUMMARY HEADER
            const Text(
              'Attendance summary',
              style: TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Check the attendance distribution for this class.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 14),

            // SUMMARY CARDS
            Row(
              children: [
                buildSummaryCard(
                  value: presentCount.toString(),
                  label: 'PRESENT',
                  icon: LucideIcons.checkCircle2,
                  color: AppColors.success,
                  lightColor: AppColors.successLight,
                ),

                const SizedBox(width: 9),

                buildSummaryCard(
                  value: absentCount.toString(),
                  label: 'ABSENT',
                  icon: LucideIcons.xCircle,
                  color: AppColors.danger,
                  lightColor: AppColors.dangerLight,
                ),

                const SizedBox(width: 9),

                buildSummaryCard(
                  value: unmarkedCount.toString(),
                  label: 'UNMARKED',
                  icon: LucideIcons.circleHelp,
                  color: AppColors.warningDark,
                  lightColor: AppColors.warningLight,
                ),
              ],
            ),

            const SizedBox(height: 22),

            // STUDENT LIST HEADER
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Student records',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 17,
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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${students.length} students',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            const Text(
              'Review each student and their recorded attendance status.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 15),

            // STUDENT RECORDS
            ...List.generate(
              students.length,
              (index) => buildStudentRecord(
                students[index],
                index,
              ),
            ),

            const SizedBox(height: 8),

            // VALIDATION MESSAGE
            buildValidationMessage(),

            const SizedBox(height: 21),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 53,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.pencil,
                        size: 17,
                      ),
                      label: const Text(
                        'Back to edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SizedBox(
                    height: 53,
                    child: ElevatedButton.icon(
                      onPressed: allMarked
                          ? () => saveAttendance(context)
                          : null,
                      icon: const Icon(
                        LucideIcons.save,
                        size: 17,
                      ),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.disabled,
                        disabledForegroundColor: AppColors.textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),

            // FOOTER NOTE
            const Center(
              child: Text(
                'Please verify all entries before confirming.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),

      // SHARED INSTRUCTOR GLASS NAVIGATION
      bottomNavigationBar: InstructorGlassNavigationIsland(
        selectedIndex: 1,
        onItemSelected: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InstructorDashboard(
                initialIndex: index,
              ),
            ),
          );
        },
      ),
    );
  }
}