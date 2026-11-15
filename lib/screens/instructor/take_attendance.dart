import 'package:flutter/material.dart';
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

  // Sample class date
  DateTime selectedDate = DateTime(2026, 9, 28);

  // Sample students and their attendance
  // null = not yet marked
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

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[selectedDate.month - 1]} '
        '${selectedDate.day}, ${selectedDate.year}';
  }

  // DATE PICKER
  Future<void> selectClassDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // MARK STUDENT ATTENDANCE
  void updateAttendance(int index, String status) {
    setState(() {
      students[index]['status'] = status;
    });
  }

  // REVIEW ATTENDANCE
  void reviewAttendance() {
  if (unmarkedCount > 0) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InstructorReviewAttendanceScreen(
        classItem: widget.classItem,

        // Send a copy of the student records
        students: students
            .map((student) => Map<String, dynamic>.from(student))
            .toList(),

        selectedDate: selectedDate,
      ),
    ),
  );
}
  // STUDENT ATTENDANCE ROW
  Widget buildStudentRow(int index) {
    final student = students[index];
    final status = student['status'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
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
                  student['name'],
                  style: const TextStyle(
                    color: Color(0xFF303840),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  student['id'],
                  style: const TextStyle(
                    color: Color(0xFF84909D),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // PRESENT BUTTON
          buildAttendanceButton(
            label: 'Present',
            isSelected: status == 'Present',
            onTap: () {
              updateAttendance(index, 'Present');
            },
          ),

          const SizedBox(width: 6),

          // ABSENT BUTTON
          buildAttendanceButton(
            label: 'Absent',
            isSelected: status == 'Absent',
            onTap: () {
              updateAttendance(index, 'Absent');
            },
          ),
        ],
      ),
    );
  }

  // PRESENT / ABSENT BUTTON DESIGN
  Widget buildAttendanceButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 77,
      height: 41,
      child: isSelected
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF303840),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF84909D),
                side: const BorderSide(
                  color: Color(0xFFD3DAE0),
                  width: 1.3,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
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
                    'Take attendance',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF303840),
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.only(left: 38),
              child: Text(
                'Manual entry · Draft, not saved',
                style: TextStyle(
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
                    widget.classItem['subject'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF303840),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.classItem['code']} · '
                    '${widget.classItem['section']} · '
                    '${widget.classItem['students']}',
                    style: const TextStyle(
                      color: Color(0xFF84909D),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // CLASS DATE
            const Text(
              'Class date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF303840),
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: selectClassDate,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                height: 59,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD3DAE0),
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF303840),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF303840),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ATTENDANCE SUMMARY
            Text(
              '$presentCount Present · '
              '$absentCount Absent · '
              '$unmarkedCount Unmarked',
              style: const TextStyle(
                color: Color(0xFF303840),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Choose Present or Absent for every student.',
              style: TextStyle(
                color: Color(0xFF303840),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            // STUDENT LIST
            ...List.generate(
              students.length,
              (index) => buildStudentRow(index),
            ),

            const SizedBox(height: 4),

            // UNMARKED STATUS
            if (unmarkedCount > 0)
              const Text(
                'Unmarked — no selection yet',
                style: TextStyle(
                  color: Color(0xFF303840),
                  fontSize: 14,
                ),
              )
            else
              const Text(
                'All students have been marked.',
                style: TextStyle(
                  color: Color(0xFF303840),
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 18),

            // REVIEW BUTTON
            SizedBox(
              height: 58,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: unmarkedCount == 0
                    ? reviewAttendance
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF303840),
                  disabledBackgroundColor:
                      const Color(0xFFE2E6E9),
                  foregroundColor: Colors.white,
                  disabledForegroundColor:
                      const Color(0xFF303840),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  unmarkedCount == 0
                      ? 'Review attendance'
                      : 'Review attendance · $unmarkedCount unmarked',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // FOOTER NOTE
            Text(
              unmarkedCount > 0
                  ? 'Review becomes available after every student '
                      'is marked. The next state shows all students '
                      'with their attendance status.'
                  : 'All students are marked. You can now review '
                      'the attendance before confirming.',
              style: const TextStyle(
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