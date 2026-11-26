import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/academic_service.dart';
import '../services/supabase_client_provider.dart';
import 'app_colors.dart';
import 'design_system.dart';

class StudentScoresDisplay extends StatefulWidget {
  const StudentScoresDisplay({super.key});

  @override
  State<StudentScoresDisplay> createState() => _StudentScoresDisplayState();
}

class _StudentScoresDisplayState extends State<StudentScoresDisplay> {
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.textPrimary;
  static const Color background = AppColors.background;
  static const Color textDark = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color green = AppColors.scoreExcellent;
  static const Color orange = AppColors.scoreAverage;
  static const Color red = AppColors.scoreNeedsImprovement;

  bool _isLoading = true;
  String? _error;
  List<ScoreRecord> _allScores = const [];
  List<Map<String, dynamic>> subjects = const [];

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await AcademicService.getStudentScores();
      final byClass = <String, List<ScoreRecord>>{};
      for (final r in records) {
        byClass.putIfAbsent(r.classId, () => []).add(r);
      }

      final grouped = <Map<String, dynamic>>[];
      for (final entry in byClass.entries) {
        final list = entry.value;
        final first = list.first;

        int avgFor(String cat) {
          final items = list.where((r) => r.category == cat).toList();
          if (items.isEmpty) return 0;
          final avg =
              items.fold<double>(0, (s, r) => s + r.percentage) / items.length;
          return avg.round();
        }

        grouped.add({
          'name': first.className.isEmpty ? first.subjectCode : first.className,
          'teacher': first.instructorName.isEmpty
              ? 'Instructor'
              : first.instructorName,
          'quiz': avgFor('quiz'),
          'activity': avgFor('activity'),
          'exam': avgFor('exam'),
        });
      }

      if (!mounted) return;
      setState(() {
        _allScores = records;
        subjects = grouped;
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

  double get averageScore {
    if (_allScores.isEmpty) return 0;
    final total = _allScores.fold<double>(0, (sum, r) => sum + r.percentage);
    return total / _allScores.length;
  }

  Color scoreColor(int score) {
    if (score >= 90) return green;
    if (score >= 80) return primaryBlue;
    if (score >= 75) return orange;
    return red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: textDark, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Grades',
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveContainer(
          maxWidth: 920,
          padding: EdgeInsets.zero,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                )
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: AsyncErrorView(
                      message: _error!,
                      onRetry: _loadScores,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: primaryBlue,
                  onRefresh: _loadScores,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildOverviewCard(),
                      const SizedBox(height: 25),
                      _buildSectionHeader(),
                      const SizedBox(height: 14),
                      if (subjects.isEmpty)
                        const EmptyStateView(
                          icon: LucideIcons.chartNoAxesCombined,
                          title: 'No grades yet',
                          message:
                              'Your recorded scores will appear here when your instructor enters them.',
                        )
                      else
                        ...subjects.map(_buildSubjectCard),
                      const SizedBox(height: 20),
                      _buildInformationNote(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grades',
          style: AppTextStyles.pageTitle,
        ),
        const SizedBox(height: 6),
        Text(
          'Track your quiz, activity, and exam results.',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final average = averageScore.round();

    return SurfacePanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  LucideIcons.chartNoAxesCombined,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Overall Average',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$average%',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 42),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'Average score',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: average / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${subjects.length} subjects • ${_allScores.length} recorded scores',
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Course Performance',
          style: AppTextStyles.sectionHeading,
        ),
        Text(
          '${subjects.length} Subjects',
          style: const TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final int quiz = subject['quiz'];
    final int activity = subject['activity'];
    final int exam = subject['exam'];
    final int average = ((quiz + activity + exam) / 3).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SurfacePanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name'],
                        style: AppTextStyles.cardHeading,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subject['teacher'],
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor(average).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$average%',
                        style: TextStyle(
                          color: scoreColor(average),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text('Average', style: AppTextStyles.meta),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildScoreRow(
              icon: LucideIcons.fileQuestion,
              label: 'Quiz',
              score: quiz,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildScoreRow(
              icon: LucideIcons.clipboardList,
              label: 'Activity',
              score: activity,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildScoreRow(
              icon: LucideIcons.fileText,
              label: 'Exam',
              score: exam,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow({
    required IconData icon,
    required String label,
    required int score,
  }) {
    final color = scoreColor(score);

    return Row(
      children: [
        Icon(icon, size: 17, color: muted),
        const SizedBox(width: 9),
        SizedBox(
          width: 67,
          child: Text(
            label,
          style: AppTextStyles.bodySmall,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 38,
          child: Text(
            '$score%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInformationNote() {
    return SurfacePanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.infoLight,
      borderColor: AppColors.infoBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: primaryBlue, size: 19),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Your scores are view-only. Only your instructor can enter or update your academic scores.',
              style: TextStyle(color: darkBlue, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
