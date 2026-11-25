import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/academic_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';

// ============================================================
// INSTRUCTOR REVIEW ATTENDANCE SCREEN
// Swiss Design + Modern Minimalist
// ============================================================

class InstructorReviewAttendanceScreen extends StatelessWidget {
  final Map<String, String> classItem;
  final List<Map<String, dynamic>> students;
  final DateTime selectedDate;
  final String? scheduleId;
  final String? meetingKey;
  final String? meetingLabel;

  const InstructorReviewAttendanceScreen({
    super.key,
    required this.classItem,
    required this.students,
    required this.selectedDate,
    this.scheduleId,
    this.meetingKey,
    this.meetingLabel,
  });

  // ============================================================
  // COMPUTED COUNTS
  // ============================================================

  int get presentCount =>
      students.where((s) => s['status'] == 'Present').length;

  int get absentCount =>
      students.where((s) => s['status'] == 'Absent').length;

  int get lateCount =>
      students.where((s) => s['status'] == 'Late').length;

  int get excusedCount =>
      students.where((s) => s['status'] == 'Excused').length;

  int get unmarkedCount =>
      students.where((s) => s['status'] == null).length;

  bool get allMarked => unmarkedCount == 0;

  String get formattedDate {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  // ============================================================
  // STATUS COLORS (monochromatic)
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
  // SAVE ATTENDANCE — Supabase (preserved exactly)
  // ============================================================

  Future<void> saveAttendance(BuildContext context) async {
    if (unmarkedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark every student before saving.'),
        ),
      );
      return;
    }

    final classId = classItem['id'];
    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing class ID.')),
      );
      return;
    }

    final statuses = <String, String>{};
    for (final student in students) {
      final sid = student['id']?.toString() ?? '';
      final status = student['status']?.toString() ?? '';
      if (sid.isNotEmpty && status.isNotEmpty) {
        statuses[sid] = status.toLowerCase();
      }
    }

    try {
      await AcademicService.saveClassAttendance(
        classId: classId,
        date: selectedDate,
        studentStatuses: statuses,
        scheduleId: scheduleId,
        meetingKey: meetingKey,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved to Supabase.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatSupabaseError(e))),
      );
    }
  }

  // ============================================================
  // CLASS INFORMATION PANEL (flat — no gradient)
  // ============================================================

  Widget _buildClassPanel() {
    return SurfacePanel(
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
                  classItem['subject'] ?? 'Class subject',
                  style: AppTextStyles.cardHeading,
                ),
                const SizedBox(height: 2),
                Text(
                  '${classItem['code'] ?? ''} · ${classItem['section'] ?? ''}',
                  style: AppTextStyles.meta,
                ),
                if (meetingLabel != null && meetingLabel!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meetingLabel!,
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
          if (classItem['students'] != null)
            StatusBadge(
              label: classItem['students']!,
              color: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
              icon: LucideIcons.users,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY TABLE (clean 2-column layout)
  // ============================================================

  Widget _buildSummaryTable() {
    return SurfacePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance summary', style: AppTextStyles.cardHeading),
          const SizedBox(height: 14),

          // Primary row: Present + Absent
          Row(
            children: [
              _buildSummaryCell(
                value: '$presentCount',
                label: 'Present',
                valueColor: AppColors.primary,
                isLarge: true,
              ),
              const SizedBox(width: 1),
              _buildSummaryCell(
                value: '$absentCount',
                label: 'Absent',
                valueColor: AppColors.textPrimary,
                isLarge: true,
              ),
            ],
          ),

          const SizedBox(height: 1),

          // Secondary row: Late + Excused
          Row(
            children: [
              _buildSummaryCell(
                value: '$lateCount',
                label: 'Late',
                valueColor: AppColors.textSecondary,
                isLarge: false,
              ),
              const SizedBox(width: 1),
              _buildSummaryCell(
                value: '$excusedCount',
                label: 'Excused',
                valueColor: AppColors.textSecondary,
                isLarge: false,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: students.isNotEmpty
                  ? (students.length - unmarkedCount) / students.length
                  : 0.0,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${students.length} students in this section',
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCell({
    required String value,
    required String label,
    required Color valueColor,
    required bool isLarge,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isLarge ? 14 : 10,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 28 : 20,
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
      ),
    );
  }

  // ============================================================
  // STUDENT RECORD ROW
  // ============================================================

  Widget _buildStudentRecord(Map<String, dynamic> student, int index) {
    final String? status = student['status'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Index number
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              LucideIcons.userRound,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),

          const SizedBox(width: 10),

          // Name + ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String? ?? 'Unknown student',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  // ============================================================
  // VALIDATION BANNER
  // ============================================================

  Widget _buildValidationBanner() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allMarked ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
            color: allMarked ? AppColors.primary : AppColors.warningDark,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allMarked
                      ? 'Attendance complete'
                      : 'Attendance incomplete',
                  style: TextStyle(
                    color:
                        allMarked ? AppColors.primary : AppColors.warningDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  allMarked
                      ? 'All students have been marked. Verify before confirming.'
                      : '$unmarkedCount student(s) are still unmarked. Go back and complete their attendance.',
                  style: TextStyle(
                    color:
                        allMarked ? AppColors.primary : AppColors.warningDark,
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Page header
            ResponsiveContainer(
              maxWidth: 920,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcademicPageHeader(
                    eyebrow: 'Instructor · Attendance',
                    title: 'Review Attendance',
                    subtitle: '$formattedDate · Review before confirmation',
                    onBack: () => Navigator.pop(context),
                  ),

                  // CLASS PANEL
                  _buildClassPanel(),

                  const SizedBox(height: 20),

                  // ATTENDANCE SUMMARY TABLE
                  _buildSummaryTable(),

                  const SizedBox(height: 24),

                  // STUDENT RECORDS HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Student records', style: AppTextStyles.sectionHeading),
                      StatusBadge(
                        label: '${students.length} students',
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Review each student and their recorded attendance status.',
                    style: AppTextStyles.bodySmall,
                  ),

                  const SizedBox(height: 14),

                  // STUDENT LIST
                  ...List.generate(
                    students.length,
                    (i) => _buildStudentRecord(students[i], i),
                  ),

                  const SizedBox(height: 16),

                  // VALIDATION BANNER
                  _buildValidationBanner(),

                  const SizedBox(height: 16),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      // Back to edit
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.pencil, size: 15),
                            label: const Text(
                              'Back to edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.lg),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Confirm save
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: allMarked
                                ? () => saveAttendance(context)
                                : null,
                            icon: const Icon(LucideIcons.save, size: 15),
                            label: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.surfaceSoft,
                              disabledForegroundColor: AppColors.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.lg),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      'Please verify all entries before confirming.',
                      style: AppTextStyles.meta,
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
}
