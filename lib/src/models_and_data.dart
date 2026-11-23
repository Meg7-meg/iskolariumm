
part of '../main.dart';

// ============================================================
// SAMPLE DATA MODELS
// ============================================================

class ClassItem {
  final String code;
  final String name;
  final String instructor;
  final String location;
  final String day;
  final String time;
  final double progress;
  final String section;

  const ClassItem({
    required this.code,
    required this.name,
    required this.instructor,
    required this.location,
    required this.day,
    required this.time,
    required this.progress,
    this.section = 'Section A',
  });
}

class TaskItem {
  final String title;
  final String subject;
  final String due;
  final String priority;
  bool done;

  TaskItem({
    required this.title,
    required this.subject,
    required this.due,
    required this.priority,
    this.done = false,
  });
}

class NoticeItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final String category;
  bool unread;

  NoticeItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.category,
    this.unread = true,
  });
}

// ============================================================
// SAMPLE CLASSES
// ============================================================

const List<ClassItem> sampleClasses = [
  ClassItem(
    code: 'CS 304',
    name: 'Data Science',
    instructor: 'Mr. Indico',
    location: 'Room 19',
    day: 'Monday',
    time: '9:00 AM',
    progress: 0.62,
    section: 'Section A',
  ),
  ClassItem(
    code: 'CS 218',
    name: 'Integral Calculus',
    instructor: 'Mrs Consulta',
    location: 'Room 4',
    day: 'Monday',
    time: '1:30 PM',
    progress: 0.50,
    section: 'Section A',
  ),
  ClassItem(
    code: 'MATH 210',
    name: 'Discrete Mathematics',
    instructor: 'Dr. Alog',
    location: 'Gymnasium',
    day: 'Tuesday',
    time: '10:00 AM',
    progress: 0.70,
    section: 'Section A',
  ),
  ClassItem(
    code: 'CS 201',
    name: 'Introduction to Programming',
    instructor: 'Prof. Makmak',
    location: 'Covered court',
    day: 'Wednesday',
    time: '11:30 AM',
    progress: 0.58,
    section: 'Section A',
  ),
];

// ============================================================
// TASK STORE
// ============================================================

class TaskStore {
  static final List<TaskItem> items = [
    TaskItem(
      title: 'Normalization worksheet',
      subject: 'Database Systems',
      due: 'Due tomorrow · 11:59 PM',
      priority: 'High',
    ),
    TaskItem(
      title: 'Mobile app wireframes',
      subject: 'Web Design',
      due: 'Due Sep 29 · 5:00 PM',
      priority: 'Medium',
    ),
    TaskItem(
      title: 'Graph theory proof set',
      subject: 'Discrete Mathematics',
      due: 'Due Oct 1 · 10:00 AM',
      priority: 'High',
    ),
    TaskItem(
      title: 'Linked lists lab',
      subject: 'Programming II',
      due: 'Due Oct 3 · 11:59 PM',
      priority: 'Medium',
    ),
    TaskItem(
      title: 'Read chapter 5',
      subject: 'Database Systems',
      due: 'Completed Sep 24',
      priority: 'Done',
      done: true,
    ),
  ];
}

// ============================================================
// NOTIFICATION STORE
// ============================================================

class NoticeStore {
  static final List<NoticeItem> items = [
    NoticeItem(
      title: 'Assignment due tomorrow',
      message: 'Normalization worksheet is due at 11:59 PM.',
      time: '10 min',
      icon: Icons.assignment_outlined,
      category: 'Classes',
    ),
    NoticeItem(
      title: 'Room changed',
      message: 'Web Design will meet in Studio 5 today.',
      time: '1 hr',
      icon: Icons.location_on_outlined,
      category: 'Classes',
    ),
    NoticeItem(
      title: 'Class announcement',
      message: 'Dr. Anderson shared notes for Module 6.',
      time: 'Yesterday',
      icon: Icons.campaign_outlined,
      category: 'Classes',
      unread: false,
    ),
    NoticeItem(
      title: 'Attendance updated',
      message: 'Your Monday attendance has been recorded.',
      time: 'Sep 24',
      icon: Icons.event_available_outlined,
      category: 'Classes',
      unread: false,
    ),
    NoticeItem(
      title: 'Study reminder',
      message: 'Graph theory study block begins at 6:00 PM.',
      time: 'Sep 23',
      icon: Icons.access_time,
      category: 'Other',
      unread: false,
    ),
  ];
}

// ============================================================
// END OF MODELS AND SAMPLE DATA
// ============================================================
