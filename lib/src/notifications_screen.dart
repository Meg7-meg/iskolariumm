part of '../main.dart';

// ------------------------------------------------------------
// NOTIFICATIONS SCREEN
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

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  // ------------------------------------------------------------
  // STUDENT NOTIFICATIONS
  // ------------------------------------------------------------

  // Legacy notifications remain available.
  // Instructor announcements are included only when the student's
  // enrolled class code AND section match the announcement target.

  List<dynamic> get _studentNotices {
    final enrolledAnnouncements =
        AnnouncementStore.items.where((announcement) {
      return StudentEnrollmentStore.items.any((enrollment) {
        return enrollment.code.trim().toLowerCase() ==
                announcement.classCode.trim().toLowerCase() &&
            enrollment.section.trim().toLowerCase() ==
                announcement.section.trim().toLowerCase();
      });
    }).toList();

    return [
      ...NoticeStore.items,
      ...enrolledAnnouncements,
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _unreadCount =>
      _studentNotices.where((notice) => notice.unread).length;

  // ------------------------------------------------------------
  // MARK ALL AS READ
  // ------------------------------------------------------------

  void _markAllAsRead() {
    if (_unreadCount == 0) return;

    setState(() {
      for (final notice in _studentNotices) {
        notice.unread = false;
      }
    });

    widget.onRefresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // MARK ONE AS READ
  // ------------------------------------------------------------

  void _markAsRead(dynamic notice) {
    if (!notice.unread) return;

    setState(() {
      notice.unread = false;
    });

    widget.onRefresh();
  }

  // ------------------------------------------------------------
  // FILTER NOTIFICATIONS
  // ------------------------------------------------------------

  List<dynamic> get _filteredNotices {
    return _studentNotices.where((notice) {
      final matchesFilter = switch (filter) {
        'Unread' => notice.unread,
        'Classes' => notice.category == 'Classes',
        _ => true,
      };

      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          notice.title.toLowerCase().contains(query) ||
          notice.message.toLowerCase().contains(query) ||
          notice.category.toLowerCase().contains(query) ||
          (notice is AnnouncementItem &&
              (notice.classCode.toLowerCase().contains(query) ||
                  notice.className.toLowerCase().contains(query) ||
                  notice.section.toLowerCase().contains(query)));

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ------------------------------------------------------------
  // OPEN NOTIFICATION DETAILS
  // ------------------------------------------------------------

  Future<void> _openNoticeDetails(dynamic notice) async {
    _markAsRead(notice);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isInstructorAnnouncement =
            notice is AnnouncementItem;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 25),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Container(
                      width: 49,
                      height: 49,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        notice.icon,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NOTIFICATION DETAILS',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              notice.category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext),
                      icon: const Icon(
                        LucideIcons.x,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              notice.time,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // CLASS AND SECTION DETAILS
                        if (isInstructorAnnouncement) ...[
                          const SizedBox(height: 17),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius:
                                  BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TARGET CLASS',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '${notice.classCode} · ${notice.className}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notice.section,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        Container(
                          width: double.infinity,
                          height: 1,
                          color: AppColors.border,
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'MESSAGE',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          notice.message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 25),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Stay updated by checking your notifications regularly.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    height: 1.5,
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

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadCount;
    final totalCount = _studentNotices.length;
    final notices = _filteredNotices;

    return Column(
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 20, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: unreadCount > 0
                                ? AppColors.primary
                                : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          unreadCount == 0
                              ? 'You are all caught up'
                              : '$unreadCount unread ${unreadCount == 1 ? 'update' : 'updates'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // MARK ALL AS READ
              Container(
                decoration: BoxDecoration(
                  color: unreadCount == 0
                      ? AppColors.background
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  tooltip: 'Mark all as read',
                  onPressed:
                      unreadCount == 0 ? null : _markAllAsRead,
                  icon: Icon(
                    LucideIcons.checkCheck,
                    size: 19,
                    color: unreadCount == 0
                        ? AppColors.textMuted
                        : AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // CLOSE BUTTON
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  tooltip: 'Close notifications',
                  onPressed: widget.onBack,
                  icon: const Icon(
                    LucideIcons.x,
                    size: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // NOTIFICATION SUMMARY
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.bell,
                    color: AppColors.primary,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your updates',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '$totalCount ${totalCount == 1 ? 'notification' : 'notifications'} in your inbox',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$unreadCount NEW',
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // SEARCH
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 17),

        // FILTERS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: FilterBar(
            labels: const ['All', 'Unread', 'Classes'],
            selected: filter,
            onSelected: (value) {
              setState(() => filter = value);
            },
          ),
        ),

        const SizedBox(height: 18),

        // NOTIFICATION LIST
        Expanded(
          child: notices.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    0,
                    22,
                    24,
                  ),
                  itemCount: notices.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 11),
                  itemBuilder: (context, index) {
                    final notice = notices[index];

                    return _buildNotificationCard(notice);
                  },
                ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // NOTIFICATION CARD
  // ------------------------------------------------------------

  Widget _buildNotificationCard(dynamic notice) {
    final isInstructorAnnouncement =
        notice is AnnouncementItem;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openNoticeDetails(notice),
        borderRadius: BorderRadius.circular(19),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: notice.unread
                ? AppColors.primaryLight
                : AppColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: notice.unread
                  ? AppColors.border
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOTIFICATION ICON
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: notice.unread
                      ? AppColors.primaryLight
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  notice.icon,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              // NOTIFICATION DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: notice.unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),

                        if (notice.unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      notice.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),

                    // CLASS TARGET LABEL
                    if (isInstructorAnnouncement) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.bookOpen,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${notice.classCode} · ${notice.section}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            notice.category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const Spacer(),

                        const Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          notice.time,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(width: 7),

                        const Icon(
                          LucideIcons.chevronRight,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    String message;

    if (_searchQuery.isNotEmpty) {
      message =
          'Try another keyword to find what you are looking for.';
    } else if (filter == 'Unread') {
      message = 'You have no unread notifications right now.';
    } else if (filter == 'Classes') {
      message = 'There are no class notifications yet.';
    } else {
      message =
          'When something important happens, you will see it here.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
          vertical: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                LucideIcons.bell,
                color: AppColors.primary,
                size: 36,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nothing to see here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),

            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                icon: const Icon(
                  LucideIcons.rotateCcw,
                  size: 15,
                ),
                label: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}