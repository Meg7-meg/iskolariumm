import 'package:flutter/material.dart';
import 'take_attendance.dart';
import 'enter_scores.dart';

// ============================================================
// INSTRUCTOR DASHBOARD
// ============================================================

class InstructorDashboard extends StatefulWidget {
  final int initialIndex;

  const InstructorDashboard({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<InstructorDashboard> createState() =>
      _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  String searchQuery = '';
  bool showTodayOnly = false;

  // Sample assigned classes
  final List<Map<String, String>> assignedClasses = [
    {
      'subject': 'Database Systems',
      'section': 'Section A',
      'code': 'CS 304',
      'room': 'Room 204',
      'schedule': 'Mon & Wed · 9:00–10:30 AM',
      'students': '5 enrolled students',
      'instructor': 'Dr. Maya Anderson',
    },
    {
      'subject': 'Database Systems',
      'section': 'Section B',
      'code': 'CS 304',
      'room': 'Room 204',
      'schedule': 'Mon & Wed · 11:00 AM–12:30 PM',
      'students': '6 enrolled students',
      'instructor': 'Dr. Maya Anderson',
    },
  ];

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // HOME SCREEN
  Widget buildHomeScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
      children: [
        const Text(
          'Iskolarium · Instructor',
          style: TextStyle(
            color: Color(0xFF1E60D5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Good morning, Dr. MakMak',
          style: TextStyle(
            color: Color(0xFF0F2042),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Monday, September 28, 2026',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 28),

        // SUMMARY CARDS
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                '2',
                'Assigned classes',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildSummaryCard(
                '2',
                'Classes today',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          "Today's assigned classes",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F2042),
          ),
        ),
        const SizedBox(height: 16),

        // ASSIGNED CLASS CARDS
        ...assignedClasses.map((classItem) {
          return buildClassCard(classItem);
        }),

        const SizedBox(height: 18),

        // VIEW ASSIGNED CLASSES BUTTON
        SizedBox(
          height: 58,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                selectedIndex = 1;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E60D5),
              side: const BorderSide(
                color: Color(0xFF1E60D5),
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'View assigned classes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // INFORMATION NOTE
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF2FD),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFD8E5F8)),
          ),
          child: const Text(
            'Your workspace shows only your assigned sections. '
            'Select a class to view its students and official records.',
            style: TextStyle(
              color: Color(0xFF0F2042),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // SUMMARY CARD
  Widget buildSummaryCard(String value, String label) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E5F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E60D5),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

    // ASSIGNED CLASS CARD
  Widget buildClassCard(Map<String, String> classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD8E5F8),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E60D5).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${classItem['subject']} · ${classItem['section']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2042),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${classItem['code']} · ${classItem['room']} · '
            '${classItem['schedule']} · ${classItem['students']}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      showMessage(
                        'Attendance for ${classItem['section']} '
                        'will be available here.',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E60D5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Take attendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const InstructorEnterScoresScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E60D5),
                      side: const BorderSide(
                        color: Color(0xFF1E60D5),
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Enter scores',
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
        ],
      ),
    );
  }

  // CLASSES SCREEN
  Widget buildClassesScreen() {
    // Search and filter the assigned classes
    final filteredClasses = assignedClasses.where((classItem) {
      final searchText = searchQuery.toLowerCase();

      final matchesSearch =
          classItem['subject']!.toLowerCase().contains(searchText) ||
          classItem['code']!.toLowerCase().contains(searchText) ||
          classItem['section']!.toLowerCase().contains(searchText);

      // Sample Today filter: the prototype schedule is Monday.
      final matchesToday = !showTodayOnly ||
          classItem['schedule']!.contains('Mon');

      return matchesSearch && matchesToday;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 30),
      children: [
        // PAGE HEADING
        const Text(
          'Iskolarium · Instructor',
          style: TextStyle(
            color: Color(0xFF1E60D5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        const Row(
          children: [
            Icon(
              Icons.chevron_left,
              size: 28,
              color: Color(0xFF0F2042),
            ),
            SizedBox(width: 5),
            Expanded(
              child: Text(
                'Assigned classes',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2042),
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 38),
          child: Text(
            'Fall semester 2026 · 2 assigned sections',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // SEARCH LABEL
        const Text(
          'Find an assigned class',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F2042),
          ),
        ),
        const SizedBox(height: 10),

        // SEARCH FIELD
        TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search name, code or section',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
            ),
            suffixIcon: const Icon(
              Icons.search,
              color: Color(0xFF1E60D5),
              size: 27,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFD8E5F8),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFF1E60D5),
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ALL / TODAY FILTER
        Container(
          height: 51,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: buildClassFilterButton(
                  label: 'All',
                  isSelected: !showTodayOnly,
                  onTap: () {
                    setState(() {
                      showTodayOnly = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildClassFilterButton(
                  label: 'Today',
                  isSelected: showTodayOnly,
                  onTap: () {
                    setState(() {
                      showTodayOnly = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ASSIGNED CLASS LIST
        if (filteredClasses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 35),
            child: Center(
              child: Text(
                'No assigned classes found.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...filteredClasses.map((classItem) {
            return buildAssignedClassCard(classItem);
          }),
        const SizedBox(height: 4),

        // INFORMATION NOTE
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF2FD),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFD8E5F8)),
          ),
          child: const Text(
            "Assigned-class access only. Other instructors' "
            "classes are not available in this account.",
            style: TextStyle(
              color: Color(0xFF0F2042),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ALL / TODAY FILTER BUTTON
  Widget buildClassFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E60D5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF1E60D5),
                  width: 1.3,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }


    // ASSIGNED CLASS CARD
  Widget buildAssignedClassCard(Map<String, String> classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD8E5F8),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E60D5).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstructorAttendanceScreen(
                classItem: classItem,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SUBJECT AND ARROW
              Row(
                children: [
                  Expanded(
                    child: Text(
                      classItem['subject']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2042),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 27,
                    color: Color(0xFF1E60D5),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // CODE, SECTION AND STUDENTS
              Text(
                '${classItem['code']} · ${classItem['section']} · '
                '${classItem['students']}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              // SCHEDULE
              Text(
                classItem['schedule']!,
                style: const TextStyle(
                  color: Color(0xFF0F2042),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),

              // ROOM AND INSTRUCTOR
              Text(
                '${classItem['room']} · ${classItem['instructor']}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PROFILE SCREEN
  Widget buildProfileScreen() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Instructor Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F2042),
          ),
        ),
        const SizedBox(height: 25),
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFEBF2FD),
          child: Icon(
            Icons.person,
            size: 45,
            color: Color(0xFF1E60D5),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            'Dr. MakMak',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F2042),
            ),
          ),
        ),
        const Center(
          child: Text(
            'Instructor',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 30),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHomeScreen(),
      buildClassesScreen(),
      buildProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFD8E5F8),
            ),
          ),
        ),
        child: NavigationBar(
          height: 78,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFFEBF2FD),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: selectedIndex == 0
                    ? const Color(0xFF1E60D5)
                    : const Color(0xFF94A3B8),
              ),
              selectedIcon: const Icon(
                Icons.home_outlined,
                color: Color(0xFF1E60D5),
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.menu_book_outlined,
                color: selectedIndex == 1
                    ? const Color(0xFF1E60D5)
                    : const Color(0xFF94A3B8),
              ),
              selectedIcon: const Icon(
                Icons.menu_book_outlined,
                color: Color(0xFF1E60D5),
              ),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: selectedIndex == 2
                    ? const Color(0xFF1E60D5)
                    : const Color(0xFF94A3B8),
              ),
              selectedIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF1E60D5),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}