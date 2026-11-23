part of '../main.dart';

// ------------------------------------------------------------
// ISKOLARIUM - CALENDAR SCREEN
// Refined Blue and White Academic Calendar
// ------------------------------------------------------------

class CalendarPage extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onAdd;

  const CalendarPage({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onAdd,
  });

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _background = AppColors.background;
  static const Color _lightBlue = AppColors.primaryLight;
  static const Color _border = AppColors.border;

  static BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    );

    final firstWeekday = monthStart.weekday % 7;

    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    final weekCount = (firstWeekday + daysInMonth + 6) ~/ 7;
    final events = _eventsFor(selectedDate);

    return Container(
      color: _background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 105),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMonthNavigation(),
          const SizedBox(height: 15),
          _buildCalendarGrid(
            firstWeekday,
            daysInMonth,
            weekCount,
          ),
          const SizedBox(height: 25),
          _buildAgendaHeader(events.length),
          const SizedBox(height: 13),
          _buildAgenda(context, events),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(
                  color: _darkBlue,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Plan classes and deadlines',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 11),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                LucideIcons.plus,
                color: _blue,
                size: 23,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // MONTH NAVIGATION
  // ------------------------------------------------------------

  Widget _buildMonthNavigation() {
    return Row(
      children: [
        _monthNavButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            onDateChanged(
              DateTime(
                selectedDate.year,
                selectedDate.month - 1,
                1,
              ),
            );
          },
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${_monthName(selectedDate.month)} ${selectedDate.year}',
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'MONTHLY OVERVIEW',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  final today = DateTime.now();
                  onDateChanged(
                    DateTime(today.year, today.month, today.day),
                  );
                },
                child: const Text(
                  'Go to today',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        _monthNavButton(
          icon: LucideIcons.chevronRight,
          onTap: () {
            onDateChanged(
              DateTime(
                selectedDate.year,
                selectedDate.month + 1,
                1,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _monthNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _darkBlue,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CALENDAR GRID
  // ------------------------------------------------------------

  Widget _buildCalendarGrid(
    int firstWeekday,
    int daysInMonth,
    int weekCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 13),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          for (int week = 0; week < weekCount; week++)
            Row(
              children: [
                for (int weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: _calendarCell(
                      firstWeekday + week * 7 + weekday,
                      firstWeekday,
                      daysInMonth,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CALENDAR DAY CELL
  // ------------------------------------------------------------

  Widget _calendarCell(
    int position,
    int firstWeekday,
    int daysInMonth,
  ) {
    final day = position - firstWeekday + 1;
    final valid = day >= 1 && day <= daysInMonth;

    if (!valid) {
      return const SizedBox(height: 48);
    }

    final currentDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      day,
    );

    final isSelected = _sameDate(currentDate, selectedDate);

    final today = DateTime.now();
    final isToday = _sameDate(currentDate, today);

    final eventCount = _eventsFor(currentDate).length;
    final hasEvent = eventCount > 0;

    return GestureDetector(
      onTap: () => onDateChanged(currentDate),
      child: SizedBox(
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 35,
            height: 39,
            decoration: BoxDecoration(
              color: isSelected ? _blue : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: isToday && !isSelected
                  ? Border.all(color: _blue, width: 1.2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Colors.white : _darkBlue,
                    fontSize: 12,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: hasEvent ? 5 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasEvent
                        ? (isSelected ? Colors.white : _blue)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

    // ------------------------------------------------------------
  // PARSE TASK DUE DATE
  // ------------------------------------------------------------

  DateTime? _parseTaskDate(String due) {
    final cleaned = due.trim();

    if (cleaned.isEmpty) return null;

    final isoDate = DateTime.tryParse(cleaned);

    if (isoDate != null) {
      return DateTime(
        isoDate.year,
        isoDate.month,
        isoDate.day,
      );
    }

    final match = RegExp(
      r'(?:Due\s+)?([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})',
      caseSensitive: false,
    ).firstMatch(cleaned);

    if (match == null) return null;

    const months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    final monthName = match.group(1)?.toLowerCase();
    final month = months[monthName];

    final day = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');

    if (month == null || day == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);

    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      return null;
    }

    return parsed;
  }

  // ------------------------------------------------------------
  // AGENDA HEADER
  // ------------------------------------------------------------

  Widget _buildAgendaHeader(int eventCount) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_weekdayName(selectedDate.weekday)}, '
            '${_monthName(selectedDate.month)} ${selectedDate.day}',
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$eventCount ${eventCount == 1 ? 'item' : 'items'}',
            style: const TextStyle(
              color: _blue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // AGENDA LIST
  // ------------------------------------------------------------

  Widget _buildAgenda(
    BuildContext context,
    List<(String, String, String, String)> events,
  ) {
    return Container(
      decoration: _cardDecoration,
      child: events.isEmpty
          ? _buildEmptyAgenda()
          : Column(
              children: [
                for (int i = 0; i < events.length; i++) ...[
                  EventRow(
                    time: events[i].$1,
                    title: events[i].$2,
                    location: events[i].$3,
                    type: events[i].$4,
                    onTap: () => _showEventDetails(
                      context,
                      events[i],
                    ),
                  ),
                  if (i < events.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Divider(
                        height: 1,
                        color: _border,
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // EVENT DETAILS
  // ------------------------------------------------------------

  void _showEventDetails(
    BuildContext context,
    (String, String, String, String) event,
  ) {
    final isCompleted = event.$4 == 'Completed';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _lightBlue,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        LucideIcons.calendarDays,
                        color: _blue,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Agenda details',
                        style: TextStyle(
                          color: _darkBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.x,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  event.$2,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _detailRow(
                  LucideIcons.calendar,
                  'Date',
                  '${_monthName(selectedDate.month)} '
                      '${selectedDate.day}, ${selectedDate.year}',
                ),
                const SizedBox(height: 13),
                _detailRow(
                  LucideIcons.clock,
                  'Schedule',
                  event.$1,
                ),
                const SizedBox(height: 13),
                _detailRow(
                  LucideIcons.bookOpen,
                  'Subject',
                  event.$3,
                ),
                const SizedBox(height: 13),
                _detailRow(
                  LucideIcons.tag,
                  'Category',
                  event.$4 == 'Completed'
                      ? 'Assignment'
                      : event.$4,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successLight
                        : _lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted
                            ? LucideIcons.circleCheck
                            : LucideIcons.info,
                        size: 17,
                        color: isCompleted
                            ? AppColors.successDark
                            : _blue,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          isCompleted
                              ? 'You have completed this task.'
                              : 'Remember to complete this task before its due date.',
                          style: TextStyle(
                            color: isCompleted
                                ? AppColors.successDark
                                : _blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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

    Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: _muted,
          size: 17,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // EMPTY AGENDA
  // ------------------------------------------------------------

  Widget _buildEmptyAgenda() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              LucideIcons.calendarCheck,
              color: _blue,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'No tasks scheduled',
            style: TextStyle(
              color: _darkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your schedule is clear for this day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              LucideIcons.plus,
              size: 15,
            ),
            label: const Text(
              'Add an item',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: _blue,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TASK EVENTS FOR SELECTED DATE
  // ------------------------------------------------------------

  List<(String, String, String, String)> _eventsFor(
    DateTime date,
  ) {
    final events = <(String, String, String, String)>[];

    for (final task in TaskStore.items) {
      final taskDate = _parseTaskDate(task.due);

      if (taskDate == null) continue;
      if (!_sameDate(taskDate, date)) continue;

      events.add((
        'All day',
        task.title,
        task.subject,
        task.done ? 'Completed' : 'Assignment',
      ));
    }

    return events;
  }

  // ------------------------------------------------------------
  // DATE COMPARISON
  // ------------------------------------------------------------

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

// ------------------------------------------------------------
// EVENT ROW
// ------------------------------------------------------------

class EventRow extends StatelessWidget {
  final String time;
  final String title;
  final String location;
  final String type;
  final VoidCallback? onTap;

  const EventRow({
    super.key,
    required this.time,
    required this.title,
    required this.location,
    required this.type,
    this.onTap,
  });

  static const Color _blue = AppColors.primary;
  static const Color _darkBlue = AppColors.navy;
  static const Color _muted = AppColors.textSecondary;
  static const Color _lightBlue = AppColors.primaryLight;

  @override
  Widget build(BuildContext context) {
    final isCompleted = type == 'Completed';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  time,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCompleted ? _muted : _darkBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.bookOpen,
                          size: 11,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.successDark
                        : AppColors.warningDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                LucideIcons.chevronRight,
                color: _muted,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// DATE HELPERS
// ------------------------------------------------------------

String _monthName(int month) {
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

  return months[month - 1];
}

String _weekdayName(int weekday) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return days[weekday - 1];
}