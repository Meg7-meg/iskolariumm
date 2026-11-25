import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/academic_service.dart';
import '../../services/class_service.dart';
import '../../services/supabase_client_provider.dart';
import '../../src/app_colors.dart';
import '../../src/design_system.dart';
import 'instructor_dashboard.dart';

// ============================================================
// DESIGN CONSTANTS
// ============================================================

const Color _scoreNavy = AppColors.textPrimary;
const Color _scoreMuted = AppColors.textSecondary;
const Color _scoreBorder = AppColors.border;
const Color _scoreBackground = AppColors.background;

// ============================================================
// INSTRUCTOR ENTER SCORES SCREEN
// ============================================================

class InstructorEnterScoresScreen extends StatefulWidget {
  final Map<String, String>? classItem;
  final String? assignmentId;
  final String? quizId;
  final String? initialTitle;
  final String? initialCategory;
  final double? initialMaxScore;

  const InstructorEnterScoresScreen({
    super.key,
    this.classItem,
    this.assignmentId,
    this.quizId,
    this.initialTitle,
    this.initialCategory,
    this.initialMaxScore,
  });

  @override
  State<InstructorEnterScoresScreen> createState() =>
      _InstructorEnterScoresScreenState();
}

class _InstructorEnterScoresScreenState
    extends State<InstructorEnterScoresScreen> {
  final List<Map<String, dynamic>> students = [];
  final List<TextEditingController> scoreControllers = [];
  List<ClassAssignmentRecord> _tasks = const [];
  List<QuizRecord> _quizzes = const [];
  List<ScoreRecord> _existingScores = const [];
  String? _selectedAssignmentId;
  String? _selectedQuizId;
  bool _isLoading = true;
  String? _loadError;
  String _category = 'assignment';

  final TextEditingController quizTitleController = TextEditingController();
  final TextEditingController maxScoreController =
      TextEditingController(text: '20');

  bool get _hasAnyAssessment => _tasks.isNotEmpty || _quizzes.isNotEmpty;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();
    _selectedAssignmentId = widget.assignmentId;
    _selectedQuizId = widget.quizId;
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _category = widget.initialCategory!.toLowerCase();
    }
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      quizTitleController.text = widget.initialTitle!;
    }
    if (widget.initialMaxScore != null && widget.initialMaxScore! > 0) {
      maxScoreController.text = widget.initialMaxScore!.toStringAsFixed(0);
    }
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final classId = widget.classItem?['id'];
    if (classId == null || classId.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Please open Enter Scores from a specific class.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        ClassService.getClassEnrollments(classId),
        AcademicService.getClassAssignments(classId),
        AcademicService.getClassQuizzes(classId),
        AcademicService.getClassScores(classId),
      ]);

      final enrollments = results[0] as List<EnrollmentRecord>;
      final tasks = results[1] as List<ClassAssignmentRecord>;
      final quizzes = results[2] as List<QuizRecord>;
      final scores = results[3] as List<ScoreRecord>;

      final approved =
          enrollments.where((e) => e.status == 'approved').toList();

      for (final c in scoreControllers) {
        c.dispose();
      }
      scoreControllers.clear();
      students.clear();

      for (final e in approved) {
        students.add({
          'name': e.studentName,
          'id': e.studentId,
          'score': '',
        });
        scoreControllers.add(TextEditingController());
      }

      _tasks = tasks;
      _quizzes = quizzes;
      _existingScores = scores;

      // Auto-select passed task/quiz or first available task/quiz
      if (_selectedAssignmentId != null) {
        final match =
            tasks.where((t) => t.id == _selectedAssignmentId).firstOrNull;
        if (match != null) {
          _applySelectedTask(match);
        } else {
          _selectedAssignmentId = null;
        }
      } else if (_selectedQuizId != null) {
        final match =
            quizzes.where((q) => q.id == _selectedQuizId).firstOrNull;
        if (match != null) {
          _applySelectedQuiz(match);
        } else {
          _selectedQuizId = null;
        }
      }

      if (_selectedAssignmentId == null && _selectedQuizId == null) {
        if (tasks.isNotEmpty) {
          _applySelectedTask(tasks.first);
        } else if (quizzes.isNotEmpty) {
          _applySelectedQuiz(quizzes.first);
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = formatSupabaseError(e);
      });
    }
  }

  void _applySelectedTask(ClassAssignmentRecord task) {
    _selectedAssignmentId = task.id;
    _selectedQuizId = null;
    _category = task.category.toLowerCase();
    quizTitleController.text = task.title;
    final defaultMax = task.maxScore != null && task.maxScore! > 0
        ? task.maxScore!
        : 100.0;

    final matched = _existingScores
        .where((s) =>
            s.assignmentId == task.id ||
            (s.assignmentId == null &&
                s.quizId == null &&
                s.assessmentName.toLowerCase() == task.title.toLowerCase()))
        .toList();

    final maxToUse = matched.isNotEmpty ? matched.first.maxScore : defaultMax;
    maxScoreController.text = maxToUse == maxToUse.roundToDouble()
        ? maxToUse.toStringAsFixed(0)
        : maxToUse.toString();

    _fillStudentControllers(matched);
  }

  void _applySelectedQuiz(QuizRecord quiz) {
    _selectedQuizId = quiz.id;
    _selectedAssignmentId = null;
    _category = 'quiz';
    quizTitleController.text = quiz.title;
    final matched = _existingScores
        .where((s) =>
            s.quizId == quiz.id ||
            (s.assignmentId == null &&
                s.quizId == null &&
                s.assessmentName.toLowerCase() == quiz.title.toLowerCase()))
        .toList();
    final maxToUse =
        matched.isNotEmpty ? matched.first.maxScore : quiz.maxScore;
    maxScoreController.text = maxToUse == maxToUse.roundToDouble()
        ? maxToUse.toStringAsFixed(0)
        : maxToUse.toString();

    _fillStudentControllers(matched);
  }

  void _fillStudentControllers(List<ScoreRecord> matched) {
    final byStudent = {for (final s in matched) s.studentId: s.score};
    for (int i = 0; i < students.length; i++) {
      final sid = students[i]['id'] as String;
      final existing = byStudent[sid];
      scoreControllers[i].text = existing == null
          ? ''
          : (existing == existing.roundToDouble()
              ? existing.toStringAsFixed(0)
              : existing.toString());
    }
  }

  @override
  void dispose() {
    for (final controller in scoreControllers) {
      controller.dispose();
    }

    quizTitleController.dispose();
    maxScoreController.dispose();

    super.dispose();
  }

  // ============================================================
  // SCORE COUNTS
  // ============================================================

  int get recordedCount {
    return scoreControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
  }

  String get _categoryLabel =>
      '${_category[0].toUpperCase()}${_category.substring(1)}';

  String get _formattedToday {
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
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // ============================================================
  // EDIT ASSESSMENT DETAILS
  // ============================================================

  void openEditDetails() {
    String selectedCategory = _category;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Edit Assessment Details',
                style: TextStyle(
                  color: _scoreNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: _scoreInputDecoration(
                      label: 'Category',
                      icon: LucideIcons.tag,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                      DropdownMenuItem(
                        value: 'activity',
                        child: Text('Activity'),
                      ),
                      DropdownMenuItem(value: 'exam', child: Text('Exam')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: quizTitleController,
                    decoration: _scoreInputDecoration(
                      label: 'Assessment title',
                      icon: LucideIcons.fileText,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: maxScoreController,
                    keyboardType: TextInputType.number,
                    decoration: _scoreInputDecoration(
                      label: 'Maximum score',
                      icon: LucideIcons.calculator,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: _scoreMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _category = selectedCategory;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Save details',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openPastAssessments() async {
    final classId = widget.classItem?['id'];
    if (classId == null || classId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<List<ScoreRecord>>(
          future: AcademicService.getClassScores(classId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(formatSupabaseError(snapshot.error!)),
                  ),
                ),
              );
            }
            final records = snapshot.data ?? [];
            final grouped = <String, List<ScoreRecord>>{};
            for (final r in records) {
              final key = '${r.category}::${r.assessmentName}';
              grouped.putIfAbsent(key, () => []).add(r);
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Past Assessments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _scoreNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap an assessment to load its scores into the form.',
                      style: TextStyle(fontSize: 12, color: _scoreMuted),
                    ),
                    const SizedBox(height: 14),
                    if (grouped.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            'No recorded scores for this class yet.',
                            style: TextStyle(color: _scoreMuted),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView(
                          shrinkWrap: true,
                          children: grouped.entries.map((entry) {
                            final first = entry.value.first;
                            final catLabel = first.category.isEmpty
                                ? 'Quiz'
                                : '${first.category[0].toUpperCase()}${first.category.substring(1)}';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: const Icon(
                                  LucideIcons.fileText,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                first.assessmentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _scoreNavy,
                                ),
                              ),
                              subtitle: Text(
                                '$catLabel · Max ${first.maxScore.toStringAsFixed(0)} · ${entry.value.length} recorded',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _scoreMuted,
                                ),
                              ),
                              trailing: const Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                                color: _scoreMuted,
                              ),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                final byStudent = {
                                  for (final s in entry.value)
                                    s.studentId: s.score,
                                };
                                setState(() {
                                  _category = first.category.isEmpty
                                      ? 'quiz'
                                      : first.category.toLowerCase();
                                  quizTitleController.text =
                                      first.assessmentName;
                                  maxScoreController.text =
                                      first.maxScore.toStringAsFixed(0);
                                  for (int i = 0; i < students.length; i++) {
                                    final sid = students[i]['id'] as String;
                                    final existing = byStudent[sid];
                                    scoreControllers[i].text = existing == null
                                        ? ''
                                        : (existing == existing.roundToDouble()
                                            ? existing.toStringAsFixed(0)
                                            : existing.toString());
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // REVIEW SCORES
  // ============================================================

  void openReviewScores() {
    if (_selectedAssignmentId == null && _selectedQuizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an existing task or quiz before entering scores.'),
        ),
      );
      return;
    }

    final maxVal = double.tryParse(maxScoreController.text.trim()) ?? 0;
    if (maxVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum score must be greater than 0.')),
      );
      return;
    }

    final scoreData = <Map<String, String>>[];

    for (int i = 0; i < students.length; i++) {
      final raw = scoreControllers[i].text.trim();
      if (raw.isNotEmpty) {
        final parsed = double.tryParse(raw);
        if (parsed == null || parsed < 0 || parsed > maxVal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid score for ${students[i]['name']}: must be 0 to $maxVal.',
              ),
            ),
          );
          return;
        }
      }
      scoreData.add({
        'name': students[i]['name'] as String,
        'id': students[i]['id'] as String,
        'score': raw,
      });
    }

    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorReviewScoresScreen(
          classId: widget.classItem?['id'] ?? '',
          assignmentId: _selectedAssignmentId,
          quizId: _selectedQuizId,
          category: _category,
          quizTitle: quizTitleController.text,
          maxScore: maxScoreController.text,
          students: scoreData,
        ),
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        _loadStudents();
      }
    });
  }

  // ============================================================
  // SHARED INPUT DECORATION
  // ============================================================

  InputDecoration _scoreInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _scoreMuted,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: AppColors.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: _scoreBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: _scoreBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT SCORE ROW
  // ============================================================

  Widget buildStudentRow(int index) {
    final student = students[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
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

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _scoreNavy,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  student['id'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _scoreMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 76,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: scoreControllers[index],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _scoreNavy,
              ),
              decoration: InputDecoration(
                hintText: '—',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _scoreBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _scoreBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUIZ INFORMATION CARD
  // ============================================================

  Widget buildQuizInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _scoreBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Text(
                  'ASSESSMENT INFORMATION',
                  style: TextStyle(
                    fontSize: 10,
                    color: _scoreMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),

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
                  'NOT SAVED',
                  style: TextStyle(
                    color: AppColors.warningDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            quizTitleController.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _scoreNavy,
            ),
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              const Icon(
                LucideIcons.bookOpen,
                size: 13,
                color: _scoreMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.classItem?['code'] ?? 'Class'} · ${widget.classItem?['section'] ?? 'Section A'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _scoreMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              const Icon(
                LucideIcons.calendarDays,
                size: 13,
                color: _scoreMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '$_categoryLabel · $_formattedToday',
                style: const TextStyle(
                  fontSize: 11,
                  color: _scoreMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calculator,
                  color: AppColors.primary,
                  size: 15,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Maximum score: ${maxScoreController.text}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _scoreNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const Text(
                  'Manual entry',
                  style: TextStyle(
                    fontSize: 10,
                    color: _scoreMuted,
                    fontWeight: FontWeight.w600,
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
  // SCORE INFORMATION
  // ============================================================

  Widget buildScoreInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.infoBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            color: AppColors.infoDark,
            size: 18,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'A blank score means not recorded. A score of 0 is a recorded zero, not a missing entry. Blank scores stay unrecorded.',
              style: TextStyle(
                fontSize: 11,
                height: 1.6,
                color: AppColors.infoDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scoreBackground,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            size: 19,
            color: _scoreNavy,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        titleSpacing: 0,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iskolarium · Instructor',
              style: TextStyle(
                fontSize: 10,
                color: _scoreMuted,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 2),

            Text(
              'Enter Scores',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _scoreNavy,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Past assessments',
            icon: const Icon(
              LucideIcons.history,
              size: 20,
              color: _scoreNavy,
            ),
            onPressed: _openPastAssessments,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
          child: ResponsiveContainer(
            maxWidth: 920,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // STEP INDICATOR
              Row(
                children: [
                  const Icon(
                    LucideIcons.clipboardList,
                    color: AppColors.primary,
                    size: 15,
                  ),

                  const SizedBox(width: 7),

                  const Expanded(
                    child: Text(
                      'Manual entry · Step 2 of 3',
                      style: TextStyle(
                        fontSize: 11,
                        color: _scoreMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Text(
                    '$recordedCount/${students.length} recorded',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: students.isEmpty
                      ? 0
                      : recordedCount / students.length,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (!_hasAnyAssessment)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _scoreBorder),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        LucideIcons.clipboardList,
                        size: 34,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No tasks or quizzes yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _scoreNavy,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create a task, assignment, or quiz in this class before entering scores.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _scoreMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // TASK / QUIZ SELECTOR
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _scoreBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedAssignmentId != null
                          ? 'task:${_selectedAssignmentId!}'
                          : (_selectedQuizId != null
                              ? 'quiz:${_selectedQuizId!}'
                              : null),
                      hint: const Text('Select task or quiz'),
                      items: [
                        ..._tasks.map(
                          (t) => DropdownMenuItem(
                            value: 'task:${t.id}',
                            child: Text(
                              '${t.category}: ${t.title}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _scoreNavy,
                              ),
                            ),
                          ),
                        ),
                        ..._quizzes.map(
                          (q) => DropdownMenuItem(
                            value: 'quiz:${q.id}',
                            child: Text(
                              'Quiz: ${q.title}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _scoreNavy,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          if (val.startsWith('task:')) {
                            final id = val.substring(5);
                            final t = _tasks.where((e) => e.id == id).firstOrNull;
                            if (t != null) _applySelectedTask(t);
                          } else if (val.startsWith('quiz:')) {
                            final id = val.substring(5);
                            final q =
                                _quizzes.where((e) => e.id == id).firstOrNull;
                            if (q != null) _applySelectedQuiz(q);
                          }
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // QUIZ INFORMATION
                buildQuizInformationCard(),
              ],

              const SizedBox(height: 23),

              if (_hasAnyAssessment) ...[

              // STUDENT LIST HEADER
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Student scores',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _scoreNavy,
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

              const SizedBox(height: 5),

              Text(
                'Enter each student\'s score out of ${maxScoreController.text}.',
                style: const TextStyle(
                  fontSize: 11,
                  color: _scoreMuted,
                ),
              ),

              const SizedBox(height: 12),

              // STUDENT SCORE LIST
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _scoreBorder,
                  ),
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _loadError != null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _loadError!,
                              style: const TextStyle(color: _scoreMuted),
                            ),
                          )
                        : students.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No approved students enrolled in this class yet.',
                                  style: TextStyle(
                                    color: _scoreMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ...List.generate(
                                    students.length,
                                    (index) => Column(
                                      children: [
                                        buildStudentRow(index),

                                        if (index != students.length - 1)
                                          const Divider(
                                            height: 1,
                                            color: AppColors.divider,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
              ),

              const SizedBox(height: 15),

              // SCORE INFORMATION
              buildScoreInformation(),

              const SizedBox(height: 20),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 51,
                      child: OutlinedButton.icon(
                        onPressed: openEditDetails,
                        icon: const Icon(
                          LucideIcons.settings2,
                          size: 16,
                        ),
                        label: const Text(
                          'Edit details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(
                            color: AppColors.border,
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
                      height: 51,
                      child: ElevatedButton.icon(
                        onPressed: openReviewScores,
                        icon: const Icon(
                          LucideIcons.clipboardCheck,
                          size: 16,
                        ),
                        label: const Text(
                          'Review scores',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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

              const SizedBox(height: 12),

              Center(
                child: Text(
                  '$recordedCount of ${students.length} scores recorded',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _scoreMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ],
            ],
            ),
          ),
        ),
      ),

      // INSTRUCTOR NAVIGATION
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InstructorDashboard(
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: const _BottomNavItem(
                    icon: LucideIcons.house,
                    label: 'Home',
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InstructorDashboard(
                          initialIndex: 1,
                        ),
                      ),
                    );
                  },
                  child: const _BottomNavItem(
                    icon: LucideIcons.bookOpen,
                    label: 'Classes',
                    selected: true,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InstructorDashboard(
                          initialIndex: 2,
                        ),
                      ),
                    );
                  },
                  child: const _BottomNavItem(
                    icon: LucideIcons.userRound,
                    label: 'Profile',
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

// ============================================================
// INSTRUCTOR REVIEW SCORES SCREEN
// ============================================================

class InstructorReviewScoresScreen extends StatelessWidget {
  final String classId;
  final String? assignmentId;
  final String? quizId;
  final String category;
  final String quizTitle;
  final String maxScore;
  final List<Map<String, String>> students;

  const InstructorReviewScoresScreen({
    super.key,
    required this.classId,
    this.assignmentId,
    this.quizId,
    required this.category,
    required this.quizTitle,
    required this.maxScore,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final recorded = students
        .where((student) => student['score']!.isNotEmpty)
        .length;

    return Scaffold(
      backgroundColor: _scoreBackground,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            size: 19,
            color: _scoreNavy,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Review Scores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _scoreNavy,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // REVIEW HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _scoreBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.clipboardCheck,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),

                        const SizedBox(width: 11),

                        const Expanded(
                          child: Text(
                            'SCORE REVIEW',
                            style: TextStyle(
                              color: _scoreMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

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
                            'NOT SAVED',
                            style: TextStyle(
                              color: AppColors.warningDark,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      quizTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _scoreNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '$recorded of ${students.length} scores recorded',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _scoreMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Maximum score: $maxScore',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _scoreMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // STUDENT RECORDS HEADER
              const Text(
                'Student records',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _scoreNavy,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Review the entered scores before confirming.',
                style: TextStyle(
                  fontSize: 11,
                  color: _scoreMuted,
                ),
              ),

              const SizedBox(height: 13),

              // STUDENT SCORE RECORDS
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _scoreBorder,
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (context, index) {
                      return const Divider(
                        height: 1,
                        color: AppColors.divider,
                      );
                    },
                    itemBuilder: (context, index) {
                      final student = students[index];

                      final String score =
                          student['score']!.isEmpty
                              ? 'Not recorded'
                              : student['score']!;

                      final bool hasScore =
                          student['score']!.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.userRound,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),

                            const SizedBox(width: 11),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _scoreNavy,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    student['id']!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _scoreMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: hasScore
                                    ? AppColors.successLight
                                    : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                score,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: hasScore
                                      ? AppColors.successDark
                                      : AppColors.warningDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // BACK TO EDIT
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.pencil,
                    size: 16,
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
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 9),

              // SAVE SCORES
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () async {
                    if (classId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Missing class ID.')),
                      );
                      return;
                    }

                    final maxVal = double.tryParse(maxScore.trim()) ?? 0;
                    final entries = <String, double>{};
                    for (final s in students) {
                      final raw = (s['score'] ?? '').trim();
                      if (raw.isEmpty) continue;
                      final val = double.tryParse(raw);
                      if (val != null) {
                        entries[s['id']!] = val;
                      }
                    }

                    try {
                      await AcademicService.saveAssessmentScores(
                        classId: classId,
                        assignmentId: assignmentId,
                        quizId: quizId,
                        assessmentName: quizTitle,
                        category: category,
                        maxScore: maxVal,
                        studentScores: entries,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scores saved to Supabase.'),
                        ),
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(formatSupabaseError(e))),
                      );
                    }
                  },
                  icon: const Icon(
                    LucideIcons.save,
                    size: 17,
                  ),
                  label: const Text(
                    'Save scores',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
// INSTRUCTOR BOTTOM NAVIGATION ITEM
// ============================================================

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 19,
          color: color,
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}