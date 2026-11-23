import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../src/app_colors.dart';

import 'take_attendance.dart';
import 'enter_scores.dart';
import 'instructor_profile.dart';
import 'instructor_announcements_screen.dart';

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
  // DESIGN TOKENS — SHARED ISKOLARIUM PALETTE
  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;
  static const Color _bg = AppColors.background;
  static const Color _ice = AppColors.primaryLight;

  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, 3);
  }

  String searchQuery = '';
  bool showTodayOnly = false;

  // SAMPLE ASSIGNED CLASSES
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

  String _formattedToday() {
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // ============================================================
  // LAYERED PAGE WRAPPERS
  // ============================================================

  Widget buildHomeScreen() {
    return _buildLayeredPage(
      eyebrow: 'INSTRUCTOR WORKSPACE',
      title: 'Welcome back, Dr. MakMak',
      subtitle: 'Your classes and teaching activities',
      child: _buildHomeContent(),
    );
  }

  Widget buildClassesScreen() {
    return _buildLayeredPage(
      eyebrow: 'YOUR TEACHING SPACE',
      title: 'Assigned Classes',
      subtitle: 'Manage your assigned subjects and sections',
      child: _buildClassesContent(),
    );
  }

  Widget buildAnnouncementsScreen() {
    return _buildLayeredPage(
      eyebrow: 'CLASS COMMUNICATION',
      title: 'Announcements',
      subtitle: 'Share updates with a specific class or section',
      child: InstructorAnnouncementsPage(
        assignedClasses: assignedClasses,
      ),
    );
  }

  Widget _buildLayeredPage({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // BLUE HEADER
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 235,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // WHITE CONTENT PANEL
                Positioned(
                  top: 166,
                  left: 15,
                  right: 15,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.07),
                          blurRadius: 22,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HOME SCREEN
  // ============================================================

  Widget _buildHomeContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 30),
      children: [
        Text(
          _formattedToday(),
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 22),

        // SUMMARY CARDS
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                '2',
                'Assigned classes',
                LucideIcons.bookOpen,
                accentColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildSummaryCard(
                '2',
                'Classes today',
                LucideIcons.calendarDays,
                accentColor: AppColors.info,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "Today's assigned classes",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => selectedIndex = 1);
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...assignedClasses.map(
          (classItem) => buildClassCard(classItem),
        ),

        const SizedBox(height: 14),

        // VIEW CLASSES BUTTON
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => selectedIndex = 1);
            },
            icon: const Icon(
              LucideIcons.bookOpen,
              size: 19,
            ),
            label: const Text(
              'View assigned classes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _blue,
              side: const BorderSide(
                color: _blue,
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // INFORMATION NOTE
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.info,
                color: _blue,
                size: 20,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Your workspace shows only your assigned sections. '
                  'Select a class to view its students and official records.',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget buildSummaryCard(
    String value,
    String label,
    IconData icon, {
    Color accentColor = AppColors.primary,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME CLASS CARD
  // ============================================================

  Widget buildClassCard(Map<String, String> classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.045),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _ice,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: _blue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem['subject']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${classItem['code']} · ${classItem['section']}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: _blue,
                size: 21,
              ),
            ],
          ),

          const SizedBox(height: 15),

          _classInfoRow(
            LucideIcons.clock,
            classItem['schedule']!,
          ),

          const SizedBox(height: 8),

          _classInfoRow(
            LucideIcons.mapPin,
            classItem['room']!,
          ),

          const SizedBox(height: 8),

          _classInfoRow(
            LucideIcons.users,
            classItem['students']!,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InstructorAttendanceScreen(
                            classItem: classItem,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
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
                      foregroundColor: _blue,
                      side: const BorderSide(color: _blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enter scores',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

  Widget _classInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: _muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CLASSES SCREEN
  // ============================================================

  Widget _buildClassesContent() {
    final filteredClasses = assignedClasses.where((classItem) {
      final searchText = searchQuery.toLowerCase();

      final matchesSearch =
          classItem['subject']!.toLowerCase().contains(searchText) ||
          classItem['code']!.toLowerCase().contains(searchText) ||
          classItem['section']!.toLowerCase().contains(searchText);

      final matchesToday =
          !showTodayOnly || classItem['schedule']!.contains('Mon');

      return matchesSearch && matchesToday;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 30),
      children: [
        const SizedBox(height: 5),

        // SEARCH FIELD
        TextField(
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Search name, code or section',
            hintStyle: const TextStyle(
              color: _muted,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              LucideIcons.search,
              color: _muted,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: _blue,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // FILTER
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _ice,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: buildClassFilterButton(
                  label: 'All classes',
                  isSelected: !showTodayOnly,
                  onTap: () => setState(() => showTodayOnly = false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: buildClassFilterButton(
                  label: 'Today',
                  isSelected: showTodayOnly,
                  onTap: () => setState(() => showTodayOnly = true),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your classes',
              style: TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${filteredClasses.length} sections',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (filteredClasses.isEmpty)
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Column(
              children: [
                Icon(
                  LucideIcons.searchX,
                  color: _muted,
                  size: 32,
                ),
                SizedBox(height: 10),
                Text(
                  'No assigned classes found.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredClasses.map(
            (classItem) => buildAssignedClassCard(classItem),
          ),

        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.shieldCheck,
                color: _blue,
                size: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Assigned-class access only. Other instructors' "
                  "classes are not available in this account.",
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CLASS FILTER BUTTON
  // ============================================================

  Widget buildClassFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _blue : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _muted,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGNED CLASS CARD
  // ============================================================

  Widget buildAssignedClassCard(Map<String, String> classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _ice,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.bookOpen,
                      color: _blue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classItem['subject']!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${classItem['code']} · ${classItem['section']}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: _blue,
                    size: 21,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              _classInfoRow(
                LucideIcons.clock,
                classItem['schedule']!,
              ),

              const SizedBox(height: 8),

              _classInfoRow(
                LucideIcons.mapPin,
                classItem['room']!,
              ),

              const SizedBox(height: 8),

              _classInfoRow(
                LucideIcons.users,
                classItem['students']!,
              ),

              const SizedBox(height: 8),

              _classInfoRow(
                LucideIcons.userRound,
                classItem['instructor']!,
              ),

              const SizedBox(height: 13),

              const Divider(color: _border, height: 1),

              const SizedBox(height: 12),

              const Row(
                children: [
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 16,
                    color: _blue,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Open class workspace',
                    style: TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHomeScreen(),
      buildClassesScreen(),
      buildAnnouncementsScreen(),
      const InstructorProfile(),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),

      // FLOATING GLASS NAVIGATION
      bottomNavigationBar: InstructorGlassNavigationIsland(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          setState(() => selectedIndex = index);
        },
      ),
    );
  }
}

// ============================================================
// INSTRUCTOR GLASS NAVIGATION ISLAND
// ============================================================

class InstructorGlassNavigationIsland extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const InstructorGlassNavigationIsland({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color _blue = AppColors.primary;
  static const Color _muted = AppColors.textSecondary;

  static const List<_InstructorNavItem> _items = [
    _InstructorNavItem(
      icon: LucideIcons.house,
      label: 'Home',
    ),
    _InstructorNavItem(
      icon: LucideIcons.bookOpen,
      label: 'Classes',
    ),
    _InstructorNavItem(
      icon: LucideIcons.megaphone,
      label: 'Announcements',
    ),
    _InstructorNavItem(
      icon: LucideIcons.userRound,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: List.generate(
                    _items.length,
                    (index) {
                      final item = _items[index];
                      final isSelected = selectedIndex == index;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 6,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onItemSelected(index),
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 250,
                                ),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.border,
                                          width: 0.8,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.08 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 22,
                                        color: isSelected
                                            ? _blue
                                            : _muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        color: isSelected
                                            ? _blue
                                            : _muted,
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INSTRUCTOR NAVIGATION ITEM
// ============================================================

class _InstructorNavItem {
  final IconData icon;
  final String label;

  const _InstructorNavItem({
    required this.icon,
    required this.label,
  });
}