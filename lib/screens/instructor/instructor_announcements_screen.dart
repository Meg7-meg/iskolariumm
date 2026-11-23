import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../src/app_colors.dart';
import '../../src/announcement_store.dart';

// ============================================================
// INSTRUCTOR ANNOUNCEMENTS SCREEN
// ============================================================

class InstructorAnnouncementsPage extends StatefulWidget {
  final List<Map<String, String>> assignedClasses;

  const InstructorAnnouncementsPage({
    super.key,
    required this.assignedClasses,
  });

  @override
  State<InstructorAnnouncementsPage> createState() =>
      _InstructorAnnouncementsPageState();
}

class _InstructorAnnouncementsPageState
    extends State<InstructorAnnouncementsPage> {
  static const Color _blue = AppColors.primary;
  static const Color _navy = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;
  static const Color _background = AppColors.background;

  String searchQuery = '';

  List<Map<String, String>> get availableClasses =>
      widget.assignedClasses;

  // ============================================================
  // HELPERS
  // ============================================================

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    bool alignLabelWithHint = false,
    int? counterMaxLength,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: AppColors.primary,
              size: 19,
            ),
      alignLabelWithHint: alignLabelWithHint,
      counterText: counterMaxLength == null ? null : '',
      filled: true,
      fillColor: AppColors.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // ANNOUNCEMENT FORM
  // ============================================================

  void openAnnouncementForm({
    AnnouncementItem? existing,
  }) {
    final titleController = TextEditingController(
      text: existing?.title ?? '',
    );

    final messageController = TextEditingController(
      text: existing?.message ?? '',
    );

    String? selectedClass;

    if (existing != null) {
      final index = availableClasses.indexWhere(
        (item) =>
            item['code'] == existing.classCode &&
            item['section'] == existing.section,
      );

      if (index != -1) {
        selectedClass = index.toString();
      }
    } else if (availableClasses.isNotEmpty) {
      selectedClass = '0';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                22,
                10,
                22,
                8,
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
                    child: const Icon(
                      LucideIcons.megaphone,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      existing == null
                          ? 'Create announcement'
                          : 'Edit announcement',
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CLASS AND SECTION
                    const Text(
                      'Target class and section',
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Select a class',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.bookOpen,
                          color: AppColors.primary,
                          size: 19,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: List.generate(
                        availableClasses.length,
                        (index) {
                          final item = availableClasses[index];

                          return DropdownMenuItem<String>(
                            value: index.toString(),
                            child: Text(
                              '${item['code']} · ${item['section']}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedClass = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    // ANNOUNCEMENT TITLE
                    const Text(
                      'Announcement title',
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: titleController,
                      maxLength: 80,
                      decoration: _inputDecoration(
                        hint: 'Enter announcement title',
                        icon: LucideIcons.fileText,
                        counterMaxLength: 80,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ANNOUNCEMENT MESSAGE
                    const Text(
                      'Message',
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: messageController,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 1000,
                      decoration: _inputDecoration(
                        hint: 'Write your announcement here...',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // TARGETING INFORMATION
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.infoBorder,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.info,
                            color: AppColors.infoDark,
                            size: 17,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This announcement will be directed to students enrolled in the selected class and section.',
                              style: TextStyle(
                                color: AppColors.infoDark,
                                fontSize: 11,
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
              actionsPadding: const EdgeInsets.fromLTRB(
                18,
                5,
                18,
                18,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                              color: AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final title =
                                titleController.text.trim();

                            final message =
                                messageController.text.trim();

                            if (title.isEmpty || message.isEmpty) {
                              showMessage(
                                'Please complete the title and message.',
                              );
                              return;
                            }

                            if (selectedClass == null) {
                              showMessage(
                                'Please select a class and section.',
                              );
                              return;
                            }

                            final index =
                                int.tryParse(selectedClass!);

                            if (index == null ||
                                index < 0 ||
                                index >= availableClasses.length) {
                              showMessage(
                                'Please select a valid class and section.',
                              );
                              return;
                            }

                            final target = availableClasses[index];

                            final announcement = AnnouncementItem(
                              id: existing?.id ??
                                  DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                              title: title,
                              message: message,
                              classCode: target['code'] ?? '',
                              className: target['subject'] ?? '',
                              section: target['section'] ?? '',
                              instructor: target['instructor'] ?? '',
                              time: existing?.time ?? 'Just now',
                              unread: true,
                            );

                            if (existing == null) {
                              AnnouncementStore.add(announcement);
                            } else {
                              AnnouncementStore.update(announcement);
                            }

                            Navigator.pop(dialogContext);

                            refresh();

                            showMessage(
                              existing == null
                                  ? 'Announcement published successfully.'
                                  : 'Announcement updated successfully.',
                            );
                          },
                          icon: Icon(
                            existing == null
                                ? LucideIcons.send
                                : LucideIcons.save,
                            size: 15,
                          ),
                          label: Text(
                            existing == null ? 'Publish' : 'Save',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      messageController.dispose();
    });
  }

  // ============================================================
  // DELETE ANNOUNCEMENT
  // ============================================================

  void confirmDelete(AnnouncementItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
          icon: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              LucideIcons.trash2,
              color: AppColors.danger,
              size: 24,
            ),
          ),
          title: const Text(
            'Delete announcement?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          content: const Text(
            'This announcement will be removed from the announcement list.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AnnouncementStore.delete(item.id);

                      Navigator.pop(dialogContext);

                      refresh();

                      showMessage('Announcement deleted.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SEARCH AND FILTER
  // ============================================================

  List<AnnouncementItem> get filteredAnnouncements {
    final query = searchQuery.trim().toLowerCase();

    final announcements = AnnouncementStore.items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query) ||
          item.classCode.toLowerCase().contains(query) ||
          item.className.toLowerCase().contains(query) ||
          item.section.toLowerCase().contains(query);
    }).toList();

    announcements.sort(
      (a, b) => b.id.compareTo(a.id),
    );

    return announcements;
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search announcements...',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          LucideIcons.search,
          color: AppColors.textSecondary,
          size: 19,
        ),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                  });
                },
                icon: const Icon(
                  LucideIcons.x,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ANNOUNCEMENT CARD
  // ============================================================

  Widget buildAnnouncementCard(AnnouncementItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.megaphone,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.35,
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
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${item.classCode} · ${item.section}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                tooltip: 'Announcement options',
                icon: const Icon(
                  LucideIcons.ellipsis,
                  color: AppColors.textSecondary,
                  size: 21,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    openAnnouncementForm(existing: item);
                  } else if (value == 'delete') {
                    confirmDelete(item);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Edit announcement',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 17,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete announcement',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          // MESSAGE
          Text(
            item.message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 15),

          const Divider(
            color: AppColors.divider,
            height: 1,
          ),

          const SizedBox(height: 12),

          // CARD FOOTER
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 14,
                color: AppColors.textMuted,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  item.time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Icon(
                LucideIcons.users,
                size: 14,
                color: AppColors.textMuted,
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  item.section,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmptyState() {
    final bool isSearching = searchQuery.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                isSearching
                    ? LucideIcons.searchX
                    : LucideIcons.megaphone,
                color: AppColors.primary,
                size: 34,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              isSearching
                  ? 'No results found'
                  : 'No announcements yet',
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSearching
                  ? 'Try searching with a different title, message, class, or section.'
                  : 'Create an announcement to share important updates with one of your assigned classes.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.6,
              ),
            ),

            if (!isSearching && availableClasses.isNotEmpty) ...[
              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed: () => openAnnouncementForm(),
                icon: const Icon(
                  LucideIcons.plus,
                  size: 16,
                ),
                label: const Text(
                  'Create announcement',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final announcements = filteredAnnouncements;

    return Container(
      color: _background,
      child: Column(
        children: [
          // TOP CONTROLS
          Padding(
            padding: const EdgeInsets.fromLTRB(
              17,
              18,
              17,
              12,
            ),
            child: Column(
              children: [
                // CREATE ANNOUNCEMENT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton.icon(
                    onPressed: availableClasses.isEmpty
                        ? null
                        : () => openAnnouncementForm(),
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 19,
                    ),
                    label: const Text(
                      'Create announcement',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.disabled,
                      disabledForegroundColor: AppColors.textSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // SEARCH FIELD
                buildSearchField(),

                const SizedBox(height: 12),

                // ANNOUNCEMENT COUNT
                Row(
                  children: [
                    const Icon(
                      LucideIcons.megaphone,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        '${announcements.length} announcement${announcements.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    if (searchQuery.isNotEmpty)
                      Text(
                        'Filtered results',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ANNOUNCEMENT LIST
          Expanded(
            child: announcements.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      17,
                      5,
                      17,
                      25,
                    ),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      return buildAnnouncementCard(
                        announcements[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}