part of '../main.dart';

// 8. TASKS SCREEN
// ------------------------------------------------------------

class TasksPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const TasksPage({super.key, required this.onRefresh});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String filter = 'All';
  bool sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final tasks = TaskStore.items.where((task) {
      if (filter == 'Upcoming') return !task.done;
      if (filter == 'Done') return task.done;
      return true;
    }).toList();

    if (sortAscending) {
      tasks.sort(
        (a, b) => a.done == b.done
            ? 0
            : a.done
            ? 1
            : -1,
      );
    } else {
      tasks.sort((a, b) => a.title.compareTo(b.title));
    }

    final dueCount = TaskStore.items.where((task) => !task.done).length;

    return Column(
      children: [
        ScreenHeading(
          title: 'Tasks',
          subtitle: '$dueCount due this week',
          onAction: () => showTaskDialog(context, () => setState(() {})),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: FilterBar(
            labels: const ['All', 'Upcoming', 'Done'],
            selected: filter,
            onSelected: (value) => setState(() => filter = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${tasks.length} assignments',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => sortAscending = !sortAscending),
                icon: const Icon(Icons.swap_vert, size: 17),
                label: const Text('Sort'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: muted,
                  side: const BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks in this category.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 90),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return TaskCard(
                      task: task,
                      onChanged: (value) {
                        setState(() => task.done = value ?? false);
                        widget.onRefresh();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool?> onChanged;

  const TaskCard({super.key, required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      color: task.done ? softGray : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.done,
            onChanged: onChanged,
            activeColor: primaryBlue,
            side: const BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.done ? muted : ink,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.subject,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: muted, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.due,
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          PriorityPill(priority: task.done ? 'Done' : task.priority),
        ],
      ),
    );
  }
}

class PriorityPill extends StatelessWidget {
  final String priority;

  const PriorityPill({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final high = priority == 'High';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: high ? primaryBlue : iceBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: high ? Colors.white : primaryBlue,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void showTaskDialog(BuildContext context, VoidCallback onAdded) {
  final titleController = TextEditingController();
  final subjectController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Task title'),
          ),
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (titleController.text.trim().isEmpty) return;

            TaskStore.items.insert(
              0,
              TaskItem(
                title: titleController.text.trim(),
                subject: subjectController.text.trim().isEmpty
                    ? 'General'
                    : subjectController.text.trim(),
                due: 'Due date not set',
                priority: 'Medium',
              ),
            );

            Navigator.pop(dialogContext);
            onAdded();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------
