
part of '../main.dart';

// ============================================================
// ISKOLARIUM — DIALOGS AND NAVIGATION COMPONENTS
// ============================================================

// ------------------------------------------------------------
// ADD ITEM DIALOG
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
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final subjectController = TextEditingController();

  String itemType = 'Assignment';

  bool get isTask => widget.currentTab == 3;
  bool get isClass => widget.currentTab == 1;
  bool get isEvent => widget.currentTab == 2;

  String get dialogTitle {
    if (isClass) return 'Add class';
    if (isEvent) return 'Add calendar event';
    return 'Add task';
  }

  String get titleLabel {
    if (isClass) return 'Class name';
    if (isEvent) return 'Event title';
    return 'Task title';
  }

  @override
  void dispose() {
    titleController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final title = titleController.text.trim();
    final subject = subjectController.text.trim();

    // Existing frontend task behavior is preserved.
    if (isTask) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF414852)
              : AppColors.border,
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isClass
                  ? Icons.menu_book_rounded
                  : isEvent
                      ? Icons.calendar_month_rounded
                      : Icons.add_task_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dialogTitle,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTask) ...[
                  const Text(
                    'TASK TYPE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: itemType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: AppColors.study,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Assignment',
                        child: Text('Assignment'),
                      ),
                      DropdownMenuItem(
                        value: 'Quiz',
                        child: Text('Quiz'),
                      ),
                      DropdownMenuItem(
                        value: 'Examination',
                        child: Text('Examination'),
                      ),
                      DropdownMenuItem(
                        value: 'Activity',
                        child: Text('Activity'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => itemType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 17),
                ],
                const Text(
                  'TITLE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: InputDecoration(
                    hintText: titleLabel,
                    counterText: '',
                    prefixIcon: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 17),
                const Text(
                  'SUBJECT OR DETAILS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    hintText: 'Enter subject or additional details',
                    counterText: '',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 28),
                      child: Icon(
                        Icons.subject_rounded,
                        color: AppColors.info,
                      ),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.infoDark,
                        size: 17,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'This is a frontend prototype. Data is temporary and is not saved to a database.',
                          style: TextStyle(
                            color: AppColors.infoDark,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// GLASS NAVIGATION ISLAND — LUCIDE ICONS
// ------------------------------------------------------------

class GlassNavigationIsland extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const GlassNavigationIsland({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color activeBlue = AppColors.primary;
  static const Color inactiveMuted = AppColors.textMuted;

  static const List<IconData> icons = [
    LucideIcons.house,
    LucideIcons.bookOpen,
    LucideIcons.calendarDays,
    LucideIcons.clipboardList,
    LucideIcons.userRound,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final safeIndex = selectedIndex.clamp(0, labels.length - 1);

    final islandColor = theme.colorScheme.surface;
    final border = isDark
        ? const Color(0xFF414852)
        : AppColors.border;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: islandColor.withValues(alpha: isDark ? 0.94 : 0.90),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: border,
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.13 : 0.09,
                  ),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.12 : 0.025,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / labels.length;

                return Stack(
                  children: [
                    // SLIDING ACTIVE BACKGROUND
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: safeIndex * itemWidth,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.22 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(27),
                            border: Border.all(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.20 : 0.10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // NAVIGATION ITEMS
                    Row(
                      children: List.generate(labels.length, (index) {
                        final isSelected = safeIndex == index;

                        return Expanded(
                          child: Semantics(
                            button: true,
                            selected: isSelected,
                            label: labels[index],
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
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        width: 35,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary.withValues(
                                                  alpha: 0.10,
                                                )
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(11),
                                        ),
                                        child: Icon(
                                          icons[index],
                                          size: 21,
                                          color: isSelected
                                              ? activeBlue
                                              : inactiveMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? activeBlue
                                            : inactiveMuted,
                                      ),
                                      child: Text(
                                        labels[index],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      height: 3,
                                      width: isSelected ? 16 : 0,
                                      decoration: BoxDecoration(
                                        color: activeBlue,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ],
                                ),
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

// ------------------------------------------------------------
// ANIMATED OWL MASCOT
// ------------------------------------------------------------

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
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
