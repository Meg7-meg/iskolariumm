part of '../main.dart';

// 6. MY CLASSES SCREEN
// ------------------------------------------------------------

class ClassesPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const ClassesPage({super.key, required this.onRefresh});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  String filter = 'All';
  String search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = sampleClasses.where((item) {
      final matchesSearch = '${item.name} ${item.code} ${item.instructor}'
          .toLowerCase()
          .contains(search.toLowerCase());

      final matchesFilter =
          filter == 'All' ||
          (filter == 'Today' && item.day == 'Monday') ||
          filter == 'This week';

      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        ScreenHeading(
          title: 'My Classes',
          subtitle: 'Fall semester · ${sampleClasses.length} enrolled',
          onAction: () => showClassDialog(context, widget.onRefresh),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: InputDecoration(
              hintText: 'Search classes',
              hintStyle: const TextStyle(color: muted),
              prefixIcon: const Icon(Icons.search, color: muted),
              suffixIcon: const Icon(Icons.tune, color: muted),
              filled: true,
              fillColor: softGray,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: FilterBar(
            labels: const ['All', 'Today', 'This week'],
            selected: filter,
            onSelected: (value) => setState(() => filter = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching classes.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 90),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ClassListCard(item: item);
                  },
                ),
        ),
      ],
    );
  }
}

class ClassListCard extends StatelessWidget {
  final ClassItem item;

  const ClassListCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Navigates to the ClassDetailScreen when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailScreen(classItem: item),
            ),
          );
        },
        child: OutlineCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: iceBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.day} · ${item.time}',
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: muted, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.instructor} · ${item.location}',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 5,
                  backgroundColor: softGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(darkPill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showClassDialog(BuildContext context, VoidCallback onRefresh) {
  final codeController = TextEditingController();
  final nameController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add a class'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeController,
            decoration: const InputDecoration(labelText: 'Course code'),
          ),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Class name'),
          ),
          const SizedBox(height: 8),
          const Text(
            'This demo does not save new classes yet.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onRefresh();
          },
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------
