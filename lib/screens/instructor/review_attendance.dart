import 'package:flutter/material.dart';
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

  // COUNT PRESENT STUDENTS
  int get presentCount {
    return students
        .where((student) => student['status'] == 'Present')
        .length;
  }

  // COUNT ABSENT STUDENTS
  int get absentCount {
    return students
        .where((student) => student['status'] == 'Absent')
        .length;
  }

  // COUNT UNMARKED STUDENTS
  int get unmarkedCount {
    return students
        .where((student) => student['status'] == null)
        .length;
  }

  // FORMAT THE SELECTED DATE
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  // SUMMARY CARD
  Widget buildSummaryCard(String value, String label) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF303840),
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF84909D),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STUDENT RECORD ROW
  Widget buildStudentRecord(Map<String, dynamic> student) {
    final status = student['status'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD3DAE0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // STUDENT ICON
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFF1F3F5),
            child: Icon(
              Icons.person_outline,
              color: Color(0xFF303840),
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          // STUDENT NAME AND ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String,
                  style: const TextStyle(
                    color: Color(0xFF303840),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  student['id'] as String,
                  style: const TextStyle(
                    color: Color(0xFF84909D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ATTENDANCE STATUS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              border: Border.all(
                color: const Color(0xFFD3DAE0),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status ?? 'Unmarked',
              style: const TextStyle(
                color: Color(0xFF303840),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SAVE ATTENDANCE MESSAGE
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
          title: const Text('Save attendance'),
          content: const Text(
            'Your attendance has passed the review stage. '
            'However, permanent database saving is not yet '
            'connected in this prototype.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   backgroundColor: Theme.of(context).colorScheme.surface,

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 15, 22, 25),
          children: [

            // PAGE HEADER
            const Text(
              'Iskolarium · Instructor',
              style: TextStyle(
                color: Color(0xFF84909D),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            // TITLE AND BACK ARROW
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 29,
                    color: Color(0xFF303840),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 7),

                const Expanded(
                  child: Text(
                    'Review attendance',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF303840),
                    ),
                  ),
                ),
              ],
            ),

            // DATE AND STATUS
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                '$formattedDate · Not saved yet',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF84909D),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // CLASS INFORMATION CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                border: Border.all(
                  color: const Color(0xFFD3DAE0),
                  width: 1.4,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classItem['subject'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF303840),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${classItem['code']} · '
                    '${classItem['section']} · '
                    '${classItem['students']}',
                    style: const TextStyle(
                      color: Color(0xFF84909D),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // PRESENT, ABSENT, UNMARKED SUMMARY
            Row(
              children: [
                buildSummaryCard(
                  presentCount.toString(),
                  'Present',
                ),
                const SizedBox(width: 10),
                buildSummaryCard(
                  absentCount.toString(),
                  'Absent',
                ),
                const SizedBox(width: 10),
                buildSummaryCard(
                  unmarkedCount.toString(),
                  'Unmarked',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // REVIEW INSTRUCTION
            Text(
              unmarkedCount == 0
                  ? 'All ${students.length} students marked. '
                      'Check each record before saving.'
                  : '$unmarkedCount student(s) still unmarked. '
                      'Go back and complete the attendance.',
              style: const TextStyle(
                color: Color(0xFF303840),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // ALL STUDENT RECORDS
            ...students.map((student) {
              return buildStudentRecord(student);
            }),

            const SizedBox(height: 18),

            // BACK TO EDIT AND SAVE BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () {
                        // Return to attendance screen.
                        // Previous selections are preserved.
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF303840),
                        side: const BorderSide(
                          color: Color(0xFF303840),
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Back to edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        saveAttendance(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF303840),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Save attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // FOOTER NOTE
            const Text(
              'Only your assigned section will be updated. '
              'Saved records can be corrected from history.',
              style: TextStyle(
                color: Color(0xFF84909D),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: NavigationBar(
        height: 78,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        indicatorColor: Colors.transparent,
        selectedIndex: 1,
      onDestinationSelected: (index) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => InstructorDashboard(
        initialIndex: index,
      ),
    ),
  );
},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


