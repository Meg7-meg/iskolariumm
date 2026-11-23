
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StudentScoresDisplay extends StatelessWidget {
  const StudentScoresDisplay({super.key});

  static const Color primaryBlue = Color(0xFF3678D4);
  static const Color darkBlue = Color(0xFF245A9E);
  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263445);
  static const Color muted = Color(0xFF84909D);
  static const Color border = Color(0xFFE6ECF3);
  static const Color green = Color(0xFF20A477);
  static const Color orange = Color(0xFFE99A35);
  static const Color red = Color(0xFFE05B5B);

  final List<Map<String, dynamic>> subjects = const [
    {
      'name': 'Data Science',
      'teacher': 'Mr. Indico',
      'quiz': 92,
      'activity': 95,
      'exam': 90,
    },
    {
      'name': 'Integral Calculus',
      'teacher': 'Mrs. Consulta',
      'quiz': 88,
      'activity': 91,
      'exam': 85,
    },
    {
      'name': 'Discrete Mathematics',
      'teacher': 'Dr. Alog',
      'quiz': 90,
      'activity': 87,
      'exam': 89,
    },
    {
      'name': 'Introduction to Programming',
      'teacher': 'Prof. Makmak',
      'quiz': 95,
      'activity': 93,
      'exam': 96,
    },
  ];

  double get averageScore {
    final total = subjects.fold<double>(
      0,
      (sum, subject) =>
          sum +
          (subject['quiz'] as int) +
          (subject['activity'] as int) +
          (subject['exam'] as int),
    );

    return total / (subjects.length * 3);
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
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: textDark,
            size: 21,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Scores',
          style: TextStyle(
            color: textDark,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            _buildHeader(),
            const SizedBox(height: 22),
            _buildOverviewCard(),
            const SizedBox(height: 25),
            _buildSectionHeader(),
            const SizedBox(height: 14),
            ...subjects.map(_buildSubjectCard),
            const SizedBox(height: 20),
            _buildInformationNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Academic Performance',
          style: TextStyle(
            color: textDark,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track your quiz, activity, and exam results.',
          style: TextStyle(
            color: muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final average = averageScore.round();

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.18),
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
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.chartNoAxesCombined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Overall Average',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$average%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 43,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'Average score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: average / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${subjects.length} subjects • ${subjects.length * 3} recorded scores',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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
          'Subject Scores',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject['teacher'],
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: scoreColor(average).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
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
                    const Text(
                      'Average',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          _buildScoreRow(
            icon: LucideIcons.fileQuestion,
            label: 'Quiz',
            score: quiz,
          ),
          const SizedBox(height: 15),
          _buildScoreRow(
            icon: LucideIcons.clipboardList,
            label: 'Activity',
            score: activity,
          ),
          const SizedBox(height: 15),
          _buildScoreRow(
            icon: LucideIcons.fileText,
            label: 'Exam',
            score: exam,
          ),
        ],
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
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFDCE9F8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            color: primaryBlue,
            size: 19,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Your scores are view-only. Only your instructor can enter or update your academic scores.',
              style: TextStyle(
                color: darkBlue,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
