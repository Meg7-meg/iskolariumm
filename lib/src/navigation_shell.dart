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
  DateTime selectedDate = DateTime(2026, 9, 26);

  void refresh() => setState(() {});

  void openNotifications() {
    setState(() => showNotifications = true);
  }

  void closeNotifications() {
    setState(() => showNotifications = false);
  }

  void openAddDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddItemDialog(
        currentTab: selectedIndex,
        onAdded: () {
          refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to this prototype.')),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DAE0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add to Iskolarium',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF303941),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'What would you like to add?',
                  style: TextStyle(fontSize: 14, color: Color(0xFF7B8792)),
                ),
                const SizedBox(height: 22),
                _buildAddOption(
                  icon: Icons.menu_book_rounded,
                  title: 'Add Class',
                  subtitle: 'Add a subject and class schedule',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => selectedIndex = 1);
                    showClassDialog(context, refresh);
                  },
                ),
                const SizedBox(height: 12),
                _buildAddOption(
                  icon: Icons.assignment_rounded,
                  title: 'Add Task',
                  subtitle: 'Add an assignment or activity',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showTaskDialog(context, refresh);
                  },
                ),
                const SizedBox(height: 12),
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
      color: Theme.of(context).colorScheme.onSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDF1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF303941), size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF303941),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B8792),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA5AF)),
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
        onRefresh: refresh,
      ),
      ClassesPage(onRefresh: refresh),
      CalendarPage(
        selectedDate: selectedDate,
        onDateChanged: (date) => setState(() => selectedDate = date),
        onAdd: openAddDialog,
      ),
      TasksPage(onRefresh: refresh),
      ProfilePage(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        child: showNotifications
            ? NotificationsPage(onBack: closeNotifications, onRefresh: refresh)
            : IndexedStack(index: selectedIndex, children: pages),
      ),
      floatingActionButton: showNotifications || selectedIndex == 4
          ? null
          : FloatingActionButton(
              onPressed: openAddBottomSheet,
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: const Icon(Icons.add, size: 32),
            ),

      bottomNavigationBar: GlassNavigationIsland(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
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
      decoration:BoxDecoration(
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
