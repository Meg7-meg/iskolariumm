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

  const InstructorAttendanceScreen({
    super.key,
    required this.classItem,
    this.scheduleId,
    this.meetingKey,
    this.meetingLabel,
  });

  @override
  State<InstructorAttendanceScreen> createState() =>
      _InstructorAttendanceScreenState();
}

class _InstructorAttendanceScreenState
    extends State<InstructorAttendanceScreen> {
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> students = [];
  bool _isLoading = true;
  String? _loadError;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAttendance();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadStudentsAndAttendance() async {
    final classId = widget.classItem['id'];
    if (classId == null || classId.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Missing class ID.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final enrollments = await ClassService.getClassEnrollments(classId);
      final approved =
          enrollments.where((e) => e.status == 'approved').toList();
      final existing = await AcademicService.getClassAttendance(
        classId: classId,
        date: selectedDate,
        meetingKey: widget.meetingKey,
      );

      final statusByStudent = <String, String>{};
      for (final record in existing) {
        final s = record.status;
        statusByStudent[record.studentId] =
            '${s[0].toUpperCase()}${s.substring(1)}';
      }

      if (!mounted) return;
      setState(() {
        students
          ..clear()
          ..addAll(
            approved.map(
              (e) => {
                'name': e.studentName,
                'id': e.studentId,
                'email': e.studentEmail,
                'status': statusByStudent[e.studentId],
              },
            ),
          );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = formatSupabaseError(e);
      });
    }
  }

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

  int get totalStudents => students.length;

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      await _loadStudentsAndAttendance();
    }
  }

  // ============================================================
  // MARK ATTENDANCE
  // ============================================================

  void updateAttendance(int index, String status) {
    setState(() {
      students[index]['status'] = status;
    });
  }

  // ============================================================
  // NAVIGATE TO REVIEW
  // ============================================================

  Future<void> reviewAttendance() async {
    if (unmarkedCount > 0) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorReviewAttendanceScreen(
          classItem: widget.classItem,
          students: students
              .map((s) => Map<String, dynamic>.from(s))
              .toList(),
          selectedDate: selectedDate,
          scheduleId: widget.scheduleId,
          meetingKey: widget.meetingKey,
          meetingLabel: widget.meetingLabel,
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

            const SizedBox(height: 12),

            // — Action buttons row —
            Row(
              children: [
                // Present button
                Expanded(
                  child: _buildPrimaryButton(
                    label: 'Present',
                    isSelected: status == 'Present',
                    onTap: () => updateAttendance(index, 'Present'),
                  ),
                ),

                const SizedBox(width: 8),

                // Absent button
                Expanded(
                  child: _buildSecondaryButton(
                    label: 'Absent',
                    isSelected: status == 'Absent',
                    onTap: () => updateAttendance(index, 'Absent'),
                  ),
                ),

                const SizedBox(width: 8),

                // More options (Late / Excused)
                _buildMoreButton(index, status),
              ],
            ),
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
            color: isMoreSelected
                ? AppColors.primary
                : AppColors.textSecondary,
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
          color:
              allMarked ? AppColors.primary.withValues(alpha: 0.2) : AppColors.warningBorder,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool allMarked = students.isNotEmpty && unmarkedCount == 0;

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
                  title: 'Take Attendance',
                  subtitle: 'Draft — not yet saved to records',
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
                            if (widget.meetingLabel != null &&
                                widget.meetingLabel!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.meetingLabel!,
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
                        label: widget.classItem['students'] ??
                            '$totalStudents students',
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                        icon: LucideIcons.users,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CLASS DATE SELECTOR
                Text(
                  'Class date',
                  style: AppTextStyles.sectionHeading,
                ),

                const SizedBox(height: 8),

                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: InkWell(
                    onTap: selectClassDate,
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
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
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

                // ATTENDANCE SUMMARY STRIP
                _buildSummaryStrip(),

                const SizedBox(height: 24),

                // STUDENT LIST HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Student attendance',
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

                Text(
                  'Tap Present or Absent. Use ··· for Late or Excused.',
                  style: AppTextStyles.bodySmall,
                ),

                const SizedBox(height: 14),

                // STUDENT CARDS
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
                else if (students.isEmpty)
                  const EmptyStateView(
                    icon: LucideIcons.users,
                    title: 'No students enrolled',
                    message:
                        'No approved students found for this class.',
                  )
                else
                  ...List.generate(
                    students.length,
                    (i) => _buildStudentCard(i),
                  ),

                const SizedBox(height: 16),

                // COMPLETION BANNER
                _buildCompletionBanner(allMarked),

                const SizedBox(height: 16),

                // REVIEW BUTTON
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: allMarked ? reviewAttendance : null,
                    icon: Icon(
                      allMarked
                          ? LucideIcons.clipboardCheck
                          : LucideIcons.lock,
                      size: 17,
                    ),
                    label: Text(
                      allMarked
                          ? 'Review attendance'
                          : 'Review attendance · $unmarkedCount unmarked',
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
                    'Attendance is a draft. Review before confirming.',
                    style: AppTextStyles.meta,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
