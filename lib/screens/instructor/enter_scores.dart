import 'package:flutter/material.dart';
import 'instructor_dashboard.dart';


class InstructorEnterScoresScreen extends StatefulWidget {
  const InstructorEnterScoresScreen({super.key});

  @override
  State<InstructorEnterScoresScreen> createState() =>
      _InstructorEnterScoresScreenState();
}

class _InstructorEnterScoresScreenState
    extends State<InstructorEnterScoresScreen> {
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

  @override
  void initState() {
    super.initState();

    for (final student in students) {
      scoreControllers.add(
        TextEditingController(text: student['score'] as String),
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

  int get recordedCount {
    return scoreControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
  }

  void openEditDetails() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Quiz Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quizTitleController,
                decoration: const InputDecoration(
                  labelText: 'Quiz title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum score',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {});
              },
              child: const Text('Save details'),
            ),
          ],
        );
      },
    );
  }

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

  Widget buildStudentRow(int index) {
    final student = students[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF59636E),
              size: 21,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF303840),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  student['id'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF84909D),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 72,
            height: 39,
            child: TextField(
              controller: scoreControllers[index],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '—',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFD3DAE0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFD3DAE0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFF303840),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF303840),
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
                color: Color(0xFF84909D),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Enter Scores',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF303840),
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manual entry · Step 2 of 3 · Not saved',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF84909D),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFD3DAE0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quizTitleController.text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF303840),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'CS 304 · Section A · Quiz · Sep 28, 2026',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF84909D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Maximum score: ${maxScoreController.text} · Manual entry',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF84909D),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                '${students.length} enrolled students · Score / ${maxScoreController.text}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF303840),
                ),
              ),

              const SizedBox(height: 8),

              ...List.generate(
                students.length,
                (index) => Column(
                  children: [
                    buildStudentRow(index),
                    const Divider(
                      height: 1,
                      color: Color(0xFFE5E8EB),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  '— = blank / not recorded. A score of 0 is a recorded zero, not a missing entry. Blank scores stay unrecorded.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: Color(0xFF84909D),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: openEditDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF303840),
                        side: const BorderSide(
                          color: Color(0xFF84909D),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Edit details',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: openReviewScores,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF303840),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Review scores',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  '$recordedCount of ${students.length} scores recorded',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF84909D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E8EB)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 55,
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
      icon: Icons.home_outlined,
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
            icon: Icons.menu_book_outlined,
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
            icon: Icons.person_outline,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Scores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF303840),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quizTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$recorded of ${students.length} scores recorded · Maximum: $maxScore',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF84909D),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final student = students[index];
                  final score = student['score']!.isEmpty
                      ? 'Not recorded'
                      : student['score']!;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      student['name']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      student['id']!,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      score,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF303840),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to edit'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF303840),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Prototype only'),
                      content: const Text(
                        'The scores have been reviewed, but they are not saved to a database yet.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Save scores'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        ? const Color(0xFF303840)
        : const Color(0xFF84909D);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
