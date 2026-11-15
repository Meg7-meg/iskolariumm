part of '../main.dart';

// 7. CALENDAR SCREEN
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

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekday = monthStart.weekday % 7;
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final monthName = _monthName(selectedDate.month);

    final events = _eventsFor(selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
      children: [
        ScreenHeading(
          title: 'Calendar',
          subtitle: 'Plan classes and deadlines',
          onAction: onAdd,
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                onDateChanged(
                  DateTime(selectedDate.year, selectedDate.month - 1, 1),
                );
              },
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                side: const BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$monthName ${selectedDate.year}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                onDateChanged(
                  DateTime(selectedDate.year, selectedDate.month + 1, 1),
                );
              },
              icon: const Icon(Icons.chevron_right),
              style: IconButton.styleFrom(
                side: const BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlineCard(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            children: [
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          day,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              for (int week = 0; week < 6; week++)
                Row(
                  children: [
                    for (int weekday = 0; weekday < 7; weekday++)
                      Expanded(
                        child: _calendarCell(
                          firstWeekday + week * 7 + weekday - 0,
                          daysInMonth,
                          selectedDate,
                          monthStart,
                          onDateChanged,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        SectionTitle(
          title:
              '${_weekdayName(selectedDate.weekday)}, ${_monthName(selectedDate.month)} ${selectedDate.day}',
          action: '${events.length} items',
        ),
        OutlineCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: events.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No sample events for this date.',
                    style: TextStyle(color: muted),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < events.length; i++) ...[
                      EventRow(
                        time: events[i].$1,
                        title: events[i].$2,
                        location: events[i].$3,
                        type: events[i].$4,
                      ),
                      if (i < events.length - 1)
                        const Divider(height: 1, color: borderColor),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _calendarCell(
    int position,
    int daysInMonth,
    DateTime selected,
    DateTime monthStart,
    ValueChanged<DateTime> onChanged,
  ) {
    final day = position - (monthStart.weekday % 7) + 1;
    final valid = day >= 1 && day <= daysInMonth;
    final isSelected = valid && day == selected.day;
    final eventDay = valid && [8, 14, 17, 22, 26, 27].contains(day);

    return GestureDetector(
      onTap: valid
          ? () => onChanged(DateTime(selected.year, selected.month, day))
          : null,
      child: SizedBox(
        height: 36,
        child: Center(
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valid
                      ? '$day'
                      : day < 1
                      ? '${DateTime(selected.year, selected.month, 0).day + day}'
                      : '${day - daysInMonth}',
                  style: TextStyle(
                    color: !valid
                        ? const Color(0xFFBBC1C7)
                        : isSelected
                        ? Colors.white
                        : ink,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (eventDay)
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : primaryBlue,
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

  List<(String, String, String, String)> _eventsFor(DateTime date) {
    // Demo schedule shown for September 26, 2026.
    if (date.year == 2026 && date.month == 9 && date.day == 26) {
      return [
        ('9:00 AM', 'Database Systems', 'Room 204', 'Class'),
        ('1:30 PM', 'Web Design', 'Studio 3', 'Class'),
        ('6:00 PM', 'Review normalization', 'Library · 45 min', 'Study'),
      ];
    }

    return [];
  }
}

class EventRow extends StatelessWidget {
  final String time;
  final String title;
  final String location;
  final String type;

  const EventRow({
    super.key,
    required this.time,
    required this.title,
    required this.location,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Text(
              time,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  location,
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

// ------------------------------------------------------------
