part of '../main.dart';

// 11. GENERAL ADD-ITEM DIALOG
// ------------------------------------------------------------

class AddItemDialog extends StatefulWidget {
  final int currentTab;
  final VoidCallback onAdded;

  const AddItemDialog({
    super.key,
    required this.currentTab,
    required this.onAdded,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final titleController = TextEditingController();
  final subjectController = TextEditingController();

  String itemType = 'Assignment';

  @override
  void dispose() {
    titleController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.currentTab == 1
            ? 'Add class'
            : widget.currentTab == 2
            ? 'Add calendar event'
            : 'Add task',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.currentTab == 3)
              DropdownButtonFormField<String>(
                initialValue: itemType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'Assignment',
                    child: Text('Assignment'),
                  ),
                  DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                  DropdownMenuItem(
                    value: 'Examination',
                    child: Text('Examination'),
                  ),
                  DropdownMenuItem(value: 'Activity', child: Text('Activity')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => itemType = value);
                },
              ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: widget.currentTab == 1
                    ? 'Class name'
                    : widget.currentTab == 2
                    ? 'Event title'
                    : 'Task title',
              ),
            ),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject or details',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This is a local UI prototype. Classes and calendar events are not saved yet.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = titleController.text.trim();
            final subject = subjectController.text.trim();

            if (title.isEmpty) return;

            if (widget.currentTab == 3) {
              TaskStore.items.insert(
                0,
                TaskItem(
                  title: title,
                  subject: subject.isEmpty ? itemType : subject,
                  due: 'Due date not set',
                  priority: 'Medium',
                ),
              );
            }

            Navigator.pop(context);
            widget.onAdded();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class GlassNavigationIsland extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const GlassNavigationIsland({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color activeBlue = Color(0xFF1E60D5);
  static const Color inactiveMuted = Color(0xFF94A3B8);

  static const List<IconData> icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.calendar_month_rounded,
    Icons.assignment_rounded,
    Icons.person_rounded,
  ];

  static const List<String> labels = [
    'Home',
    'Classes',
    'Calendar',
    'Tasks',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: const Color(0xFFD8E5F8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E60D5).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / labels.length;

                return Stack(
                  children: [
                    // Sliding liquid-style selection background
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeInOutBack,
                      left: selectedIndex * itemWidth,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: activeBlue.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),

                    // Navigation icons and labels
                    Row(
                      children: List.generate(labels.length, (index) {
                        final isSelected = selectedIndex == index;

                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () => onItemSelected(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal: 2,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.12 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      icons[index],
                                      size: 22,
                                      color: isSelected ? activeBlue : inactiveMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected ? activeBlue : inactiveMuted,
                                    ),
                                    child: Text(labels[index]),
                                  ),
                                  const SizedBox(height: 5),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    height: 2,
                                    width: isSelected ? 17 : 0,
                                    decoration: BoxDecoration(
                                      color: darkBg,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedOwlMascot extends StatefulWidget {
  const AnimatedOwlMascot({super.key});

  @override
  State<AnimatedOwlMascot> createState() => _AnimatedOwlMascotState();
}

class _AnimatedOwlMascotState extends State<AnimatedOwlMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/owl.png',
        width: 100,
        height: 100,

        fit: BoxFit.contain,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ------------------------------------------------------------
