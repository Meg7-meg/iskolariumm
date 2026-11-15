
import 'package:flutter/material.dart';

// ============================================================
// ISKOLARIUM STUDENT DASHBOARD
// This is the student's homepage and main overview.
// ============================================================

class StudentDashboard extends StatelessWidget {
  final VoidCallback onOpenClasses;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotifications;
  final VoidCallback onRefresh;

  const StudentDashboard({
    super.key,
    required this.onOpenClasses,
    required this.onOpenTasks,
    required this.onOpenNotifications,
    required this.onRefresh,
  });

  // BRAND COLORS

  static const Color navy = Color(0xFF123D70);
  static const Color ink = Color(0xFF303840);
  static const Color muted = Color(0xFF84909D);
  static const Color border = Color(0xFFD3DAE0);
  static const Color softGray = Color(0xFFF1F3F5);
  static const Color background = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            onRefresh();
          },

          color: navy,

          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              22,
              18,
              22,
              100,
            ),

            children: [

              // ==========================================
              // HEADER
              // ==========================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Good morning, Elmeg!',
                          style: TextStyle(
                            color: ink,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Monday, September 26',
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: onOpenNotifications,
                    tooltip: 'Notifications',

                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: ink,
                    ),

                    style: IconButton.styleFrom(
                      side: const BorderSide(
                        color: border,
                      ),
                      shape: const CircleBorder(),
                      fixedSize: const Size(46, 46),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================
              // OWL MASCOT
              // ==========================================

              const Center(
                child: _DashboardOwl(),
              ),

              const SizedBox(height: 18),

              // ==========================================
              // SUMMARY CARDS
              // ==========================================

              const Row(
                children: [

                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.menu_book_outlined,
                      value: '5',
                      label: 'Classes',
                    ),
                  ),

                  SizedBox(width: 9),

                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.assignment_outlined,
                      value: '3',
                      label: 'Tasks Due',
                    ),
                  ),

                  SizedBox(width: 9),

                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.bar_chart_rounded,
                      value: '92%',
                      label: 'Attendance',
                    ),
                  ),
                ],
              ),

              // ==========================================
              // TODAY'S SCHEDULE
              // ==========================================

              _SectionTitle(
                title: "Today's Schedule",
                action: 'See all',
                onTap: onOpenClasses,
              ),

              _OutlineCard(
                child: Column(
                  children: [

                    const _ScheduleRow(
                      time: '9:00',
                      period: 'AM',
                      title: 'Database Systems',
                      details: 'Room 204 · Dr. Anderson',
                      isNow: true,
                    ),

                    const Divider(
                      height: 20,
                      color: border,
                    ),

                    const _ScheduleRow(
                      time: '1:30',
                      period: 'PM',
                      title: 'Web Design',
                      details: 'Studio 3 · Prof. Green',
                      isNow: false,
                    ),
                  ],
                ),
              ),

              // ==========================================
              // UPCOMING DEADLINE
              // ==========================================

              _SectionTitle(
                title: 'Upcoming Deadline',
                action: 'View tasks',
                onTap: onOpenTasks,
              ),

              _OutlineCard(
                color: softGray,

                child: Row(
                  children: [

                    Container(
                      width: 46,
                      height: 46,

                      decoration: BoxDecoration(
                        color: const Color(0xFFE1EAF5),
                        borderRadius: BorderRadius.circular(13),
                      ),

                      child: const Center(
                        child: Text(
                          'DB',
                          style: TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 13),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            'Normalization Worksheet',
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Database Systems · Due tomorrow',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: muted,
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
}

// ============================================================
// DASHBOARD OWL MASCOT
// ============================================================

class _DashboardOwl extends StatelessWidget {
  const _DashboardOwl();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 115,
      child: Image.asset(
        'assets/images/owl.png',
        fit: BoxFit.contain,

        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.pets_rounded,
            size: 75,
            color: Color(0xFF123D70),
          );
        },
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 5,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: const Color(0xFFD3DAE0),
        ),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: const Color(0xFF123D70),
            size: 23,
          ),

          const SizedBox(height: 9),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF303840),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Color(0xFF84909D),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 12,
      ),

      child: Row(
        children: [

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF303840),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          TextButton(
            onPressed: onTap,

            child: Text(
              action,
              style: const TextStyle(
                color: Color(0xFF123D70),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OUTLINE CARD
// ============================================================

class _OutlineCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const _OutlineCard({
    required this.child,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFD3DAE0),
        ),
      ),

      child: child,
    );
  }
}

// ============================================================
// SCHEDULE ROW
// ============================================================

class _ScheduleRow extends StatelessWidget {
  final String time;
  final String period;
  final String title;
  final String details;
  final bool isNow;

  const _ScheduleRow({
    required this.time,
    required this.period,
    required this.title,
    required this.details,
    required this.isNow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        SizedBox(
          width: 58,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF303840),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Text(
                period,
                style: const TextStyle(
                  color: Color(0xFF84909D),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 3,
          height: 43,

          decoration: BoxDecoration(
            color: isNow
                ? const Color(0xFF123D70)
                : const Color(0xFFD3DAE0),

            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF303840),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                details,
                style: const TextStyle(
                  color: Color(0xFF84909D),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        if (isNow)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFE5EFFA),
              borderRadius: BorderRadius.circular(20),
            ),

            child: const Text(
              'NOW',
              style: TextStyle(
                color: Color(0xFF123D70),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
