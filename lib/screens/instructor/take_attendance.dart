import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../src/app_colors.dart';
import 'review_attendance.dart';
import 'instructor_dashboard.dart';

// ============================================================
// INSTRUCTOR ATTENDANCE SCREEN
// ============================================================

class InstructorAttendanceScreen extends StatefulWidget {
  final Map<String, String> classItem;

  const InstructorAttendanceScreen({
    super.key,
    required this.classItem,
  });

  @override
  State<InstructorAttendanceScreen> createState() =>
      _InstructorAttendanceScreenState();
}

class _InstructorAttendanceScreenState
    extends State<InstructorAttendanceScreen> {
  DateTime selectedDate = DateTime.now();

  // DESIGN TOKENS
  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;
  static const Color _background = AppColors.background;

  // SAMPLE STUDENTS
  final List<Map<String, dynamic>> students = [
    {
      'name': 'Alex Johnson',
      'id': '2023-001',
      'status': 'Absent',
    },
    {
      'name': 'Bea Cruz',
      'id': '2023-002',
      'status': 'Present',
    },
    {
      'name': 'Carlos Reyes',
      'id': '2023-003',
      'status': 'Present',
    },
    {
      'name': 'Dana Santos',
      'id': '2023-004',
      'status': 'Present',
    },
    {
      'name': 'Eli Tan',
      'id': '2023-005',
      'status': null,
    },
  ];

  // ============================================================
  // ATTENDANCE COUNTS
  // ============================================================

  int get presentCount {
    return students
        .where((student) => student['status'] == 'Present')
        .length;
  }

  int get absentCount {
    return students
        .where((student) => student['status'] == 'Absent')
        .length;
  }

  int get unmarkedCount {
    return students
        .where((student) => student['status'] == null)
        .length;
  }

  int get totalStudents => students.length;

  String get formattedDate {
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

    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> selectClassDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
        selectedDate = pickedDate;
      });
    }
  }

  // ============================================================
  // MARK STUDENT ATTENDANCE
  // ============================================================

  void updateAttendance(int index, String status) {
    setState(() {
      students[index]['status'] = status;
    });
  }

  // ============================================================
  // REVIEW ATTENDANCE
  // ============================================================

  void reviewAttendance() {
    if (unmarkedCount > 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorReviewAttendanceScreen(
          classItem: widget.classItem,
          students: students
              .map((student) => Map<String, dynamic>.from(student))
              .toList(),
          selectedDate: selectedDate,
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE STATUS COLORS
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.success;

      case 'Absent':
        return AppColors.danger;

      default:
        return AppColors.warning;
    }
  }

  Color _statusLightColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.successLight;

      case 'Absent':
        return AppColors.dangerLight;

      default:
        return AppColors.warningLight;
    }
  }

  // ============================================================
  // STUDENT ATTENDANCE ROW
  // ============================================================

  Widget buildStudentRow(int index) {
    final student = students[index];
    final String? status = student['status'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: status == null
              ? AppColors.warningBorder
              : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.userRound,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student['id'],
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusLightColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Unmarked',
                    style: TextStyle(
                      color: AppColors.warningDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: buildAttendanceButton(
                  label: 'Present',
                  icon: LucideIcons.check,
                  color: AppColors.success,
                  lightColor: AppColors.successLight,
                  isSelected: status == 'Present',
                  onTap: () {
                    updateAttendance(index, 'Present');
                  },
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: buildAttendanceButton(
                  label: 'Absent',
                  icon: LucideIcons.x,
                  color: AppColors.danger,
                  lightColor: AppColors.dangerLight,
                  isSelected: status == 'Absent',
                  onTap: () {
                    updateAttendance(index, 'Absent');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRESENT / ABSENT BUTTON DESIGN
  // ============================================================

  Widget buildAttendanceButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: isSelected
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(
                icon,
                size: 15,
              ),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                icon,
                size: 15,
              ),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                backgroundColor: lightColor.withValues(alpha: 0.35),
                side: BorderSide(
                  color: color.withValues(alpha: 0.25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // ATTENDANCE SUMMARY CARD
  // ============================================================

  Widget buildAttendanceSummary() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance overview',
            style: TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  value: '$presentCount',
                  label: 'Present',
                  color: AppColors.success,
                  lightColor: AppColors.successLight,
                  icon: LucideIcons.checkCircle,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildSummaryItem(
                  value: '$absentCount',
                  label: 'Absent',
                  color: AppColors.danger,
                  lightColor: AppColors.dangerLight,
                  icon: LucideIcons.xCircle,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildSummaryItem(
                  value: '$unmarkedCount',
                  label: 'Unmarked',
                  color: AppColors.warning,
                  lightColor: AppColors.warningLight,
                  icon: LucideIcons.clock,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                if (presentCount > 0)
                  Expanded(
                    flex: presentCount,
                    child: Container(
                      height: 7,
                      color: AppColors.success,
                    ),
                  ),

                if (absentCount > 0)
                  Expanded(
                    flex: absentCount,
                    child: Container(
                      height: 7,
                      color: AppColors.danger,
                    ),
                  ),

                if (unmarkedCount > 0)
                  Expanded(
                    flex: unmarkedCount,
                    child: Container(
                      height: 7,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          Text(
            '$totalStudents students in this section',
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String value,
    required String label,
    required Color color,
    required Color lightColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
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
            // PAGE HEADER
            const Text(
              'ISKOLARIUM · INSTRUCTOR',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),

            const SizedBox(height: 9),

            Row(
              children: [
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 23,
                        color: _navy,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    'Take attendance',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            const Padding(
              padding: EdgeInsets.only(left: 54),
              child: Text(
                'Manual entry · Draft, not saved',
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // CLASS INFORMATION CARD
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
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
                          'SELECTED CLASS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),

                      const Icon(
                        LucideIcons.shieldCheck,
                        color: Colors.white70,
                        size: 19,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.classItem['subject'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    '${widget.classItem['code']} · '
                    '${widget.classItem['section']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
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
                          widget.classItem['students'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 23),

            // CLASS DATE
            const Text(
              'Class date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),

            const SizedBox(height: 9),

            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: selectClassDate,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 57,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.calendarDays,
                        color: AppColors.primary,
                        size: 21,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      ),

                      const Icon(
                        LucideIcons.chevronDown,
                        color: _muted,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 23),

            // ATTENDANCE SUMMARY
            buildAttendanceSummary(),

            const SizedBox(height: 22),

            // STUDENT LIST HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student attendance',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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
                    '$totalStudents students',
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
              'Choose Present or Absent for every student.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 15),

            // STUDENT LIST
            ...List.generate(
              students.length,
              (index) => buildStudentRow(index),
            ),

            const SizedBox(height: 8),

            // ATTENDANCE COMPLETION STATUS
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: allMarked
                    ? AppColors.successLight
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: allMarked
                      ? AppColors.successBorder
                      : AppColors.warningBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    allMarked
                        ? LucideIcons.checkCircle
                        : LucideIcons.alertCircle,
                    color: allMarked
                        ? AppColors.success
                        : AppColors.warningDark,
                    size: 19,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      allMarked
                          ? 'All students have been marked. You can now review the attendance.'
                          : '$unmarkedCount student(s) still need an attendance status.',
                      style: TextStyle(
                        color: allMarked
                            ? AppColors.successDark
                            : AppColors.warningDark,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 19),

            // REVIEW BUTTON
            SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: allMarked ? reviewAttendance : null,
                icon: Icon(
                  allMarked
                      ? LucideIcons.clipboardCheck
                      : LucideIcons.lock,
                  size: 18,
                ),
                label: Text(
                  allMarked
                      ? 'Review attendance'
                      : 'Review attendance · $unmarkedCount unmarked',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Attendance is currently a draft. Review the list before proceeding to confirmation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.5,
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