part of '../main.dart';

// 3. MAIN NAVIGATION
// ------------------------------------------------------------

class IskolariumShell extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const IskolariumShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<IskolariumShell> createState() => _IskolariumShellState();
}

class _IskolariumShellState extends State<IskolariumShell> {
  int selectedIndex = 0;
  bool showNotifications = false;
  DateTime selectedDate = DateTime.now();

  void refresh() => setState(() {});

  void openNotifications() {
    setState(() => showNotifications = true);
  }

  void closeNotifications() {
    setState(() => showNotifications = false);
  }

  // Opens Study Sessions as a separate page.
  // It does not add another bottom navigation destination.

void openStudySessions() {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => StudySessionsPage(
        onNavigateToTab: (index) {
          Navigator.of(context).pop();

          setState(() {
            selectedIndex = index;
          });
        },
      ),
    ),
  );
}


  // Opens the student's attendance details as a separate page.
  // It does not add another bottom navigation destination.
  void openAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const StudentAttendanceScreen(),
      ),
    );
  }

  // Opens the student's scores as a separate page.
  // It does not add another bottom navigation destination.
  void openScores() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const StudentScoresDisplay(),
      ),
    );
  }

  void openAddDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddItemDialog(
        currentTab: selectedIndex,
        onAdded: () {
          refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to your account.')),
          );
        },
      ),
    );
  }

  void openAddBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2ECFD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add to Iskolarium',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'What would you like to add?',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
                const SizedBox(height: 20),
                _buildAddOption(
                  icon: Icons.menu_book_rounded,
                  title: 'Add Class',
                  subtitle: 'Add a subject and class schedule',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => selectedIndex = 1);
                    openAddDialog();
                  },
                ),
                const SizedBox(height: 10),
                _buildAddOption(
                  icon: Icons.assignment_rounded,
                  title: 'Add Task',
                  subtitle: 'Add an assignment or activity',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showTaskDialog(
                    context,
                    onSaved: refresh,
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildAddOption(
                  icon: Icons.calendar_month_rounded,
                  title: 'Add Event',
                  subtitle: 'Schedule a quiz or examination',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => selectedIndex = 2);
                    openAddDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iceBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      StudentDashboard(
        onOpenClasses: () => setState(() => selectedIndex = 1),
        onOpenTasks: () => setState(() => selectedIndex = 3),
        onOpenNotifications: openNotifications,
        onOpenStudySessions: openStudySessions,
        onOpenAttendance: openAttendance,
        onOpenScores: openScores,
        onRefresh: refresh,
      ),
      ClassesPage(onRefresh: refresh),
      CalendarPage(
        selectedDate: selectedDate,
        onDateChanged: (date) => setState(() => selectedDate = date),
        onAdd: openAddDialog,
      ),
      TasksPage(onRefresh: refresh),
      const ProfilePage(),
    ];

    const destinations = [
      AcademicNavDestination(icon: LucideIcons.layoutDashboard, label: 'Overview'),
      AcademicNavDestination(icon: LucideIcons.bookOpen, label: 'Classes'),
      AcademicNavDestination(icon: LucideIcons.calendarDays, label: 'Calendar'),
      AcademicNavDestination(icon: LucideIcons.checkSquare, label: 'Tasks'),
      AcademicNavDestination(icon: LucideIcons.userRound, label: 'Profile'),
    ];

    return AcademicNavigationShell(
      roleLabel: 'Student Portal',
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        setState(() {
          showNotifications = false;
          selectedIndex = index;
        });
      },
      sidebarAction: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: openAddBottomSheet,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Quick Add'),
        ),
      ),
      floatingActionButton: showNotifications ||
              selectedIndex != 0 ||
              MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop
          ? null
          : FloatingActionButton(
              onPressed: openAddBottomSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: const Icon(LucideIcons.plus, size: 22),
            ),
      body: showNotifications
          ? NotificationsPage(onBack: closeNotifications, onRefresh: refresh)
          : IndexedStack(index: selectedIndex, children: pages),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, 'Home'),
      (Icons.menu_book_outlined, 'Classes'),
      (Icons.calendar_month_outlined, 'Calendar'),
      (Icons.assignment_outlined, 'Tasks'),
      (Icons.person_outline, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: NavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (int i = 0; i < items.length; i++)
            NavigationDestination(
              icon: Icon(items[i].$1, color: selectedIndex == i ? ink : muted),
              label: items[i].$2,
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------