part of '../main.dart';

// 9. NOTIFICATIONS SCREEN
// ------------------------------------------------------------

class NotificationsPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const NotificationsPage({
    super.key,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final unreadCount = NoticeStore.items.where((n) => n.unread).length;

    final notices = NoticeStore.items.where((notice) {
      if (filter == 'Unread') return notice.unread;
      if (filter == 'Classes') return notice.category == 'Classes';
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unreadCount unread updates',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mark all as read',
                onPressed: () {
                  setState(() {
                    for (final notice in NoticeStore.items) {
                      notice.unread = false;
                    }
                  });
                  widget.onRefresh();
                },
                icon: const Icon(Icons.done_all_rounded),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: borderColor),
                  shape: const CircleBorder(),
                  fixedSize: const Size(44, 44),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: FilterBar(
            labels: const ['All', 'Unread', 'Classes'],
            selected: filter,
            onSelected: (value) => setState(() => filter = value),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: notices.isEmpty
              ? const Center(child: Text('No notifications found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  itemCount: notices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notice = notices[index];

                    return InkWell(
                      onTap: () {
                        setState(() => notice.unread = false);
                        widget.onRefresh();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: OutlineCard(
                        color: notice.unread ? softGray : Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: iceBlue,
                                border: Border.all(color: borderColor),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(notice.icon, color: primaryBlue, size: 21),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notice.title,
                                    style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    notice.message,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              children: [
                                Text(
                                  notice.time,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (notice.unread)
                                  const CircleAvatar(
                                    radius: 3,
                                    backgroundColor: primaryBlue,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
