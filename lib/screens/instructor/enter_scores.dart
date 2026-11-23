import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../src/app_colors.dart';
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
  const InstructorEnterScoresScreen({super.key});

  @override
  State<InstructorEnterScoresScreen> createState() =>
      _InstructorEnterScoresScreenState();
}

class _InstructorEnterScoresScreenState
    extends State<InstructorEnterScoresScreen> {
  // ============================================================
  // SAMPLE STUDENT DATA
  // ============================================================

  final List<Map<String, dynamic>> students = [
    {'name': 'Charlie Mirk', 'id': '2023-001', 'score': '18'},
    {'name': 'Adolf Digler', 'id': '2023-002', 'score': '0'},
    {'name': 'Michael Epstein', 'id': '2023-003', 'score': '22'},
    {'name': 'Dana Santos', 'id': '2023-004', 'score': '16'},
    {'name': 'Eli Tan', 'id': '2023-005', 'score': ''},
  ];

  final List<TextEditingController> scoreControllers = [];

  final TextEditingController quizTitleController =
      TextEditingController(text: 'Quiz 2: Normalization');

  final TextEditingController maxScoreController =
      TextEditingController(text: '20');

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    for (final student in students) {
      scoreControllers.add(
        TextEditingController(
          text: student['score'] as String,
        ),
      );
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

  // ============================================================
  // EDIT QUIZ DETAILS
  // ============================================================

  void openEditDetails() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Edit Quiz Details',
            style: TextStyle(
              color: _scoreNavy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quizTitleController,
                decoration: _scoreInputDecoration(
                  label: 'Quiz title',
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
                setState(() {});
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
  }

  // ============================================================
  // REVIEW SCORES
  // ============================================================

  void openReviewScores() {
    final scoreData = <Map<String, String>>[];

    for (int i = 0; i < students.length; i++) {
      scoreData.add({
        'name': students[i]['name'] as String,
        'id': students[i]['id'] as String,
        'score': scoreControllers[i].text.trim(),
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorReviewScoresScreen(
          quizTitle: quizTitleController.text,
          maxScore: maxScoreController.text,
          students: scoreData,
        ),
      ),
    );
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

          const Row(
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 13,
                color: _scoreMuted,
              ),
              SizedBox(width: 6),
              Text(
                'CS 304 · Section A',
                style: TextStyle(
                  fontSize: 11,
                  color: _scoreMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          const Row(
            children: [
              Icon(
                LucideIcons.calendarDays,
                size: 13,
                color: _scoreMuted,
              ),
              SizedBox(width: 6),
              Text(
                'Quiz · Sep 28, 2026',
                style: TextStyle(
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
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
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

              // QUIZ INFORMATION
              buildQuizInformationCard(),

              const SizedBox(height: 23),

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
                child: Column(
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
  final String quizTitle;
  final String maxScore;
  final List<Map<String, String>> students;

  const InstructorReviewScoresScreen({
    super.key,
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          icon: const Icon(
                            LucideIcons.database,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          title: const Text(
                            'Prototype only',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _scoreNavy,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          content: const Text(
                            'The scores have been reviewed, but they are not saved to a database yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _scoreMuted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Got it',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
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