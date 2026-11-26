part of '../main.dart';

// ============================================================
// DATA MODELS
// ============================================================

class ClassItem {
  final String? id;
  final String code;
  final String name;
  final String instructor;
  final String location;
  final String day;
  final String time;
  final List<ClassMeetingSchedule> schedules;
  final double progress;
  final String section;
  final bool isOfficial;
  final String enrollmentCode;
  final String description;

  const ClassItem({
    this.id,
    required this.code,
    required this.name,
    required this.instructor,
    required this.location,
    required this.day,
    required this.time,
    this.schedules = const [],
    required this.progress,
    this.section = 'Section A',
    this.isOfficial = false,
    this.enrollmentCode = '',
    this.description = '',
  });

  List<ClassMeetingSchedule> get effectiveSchedules {
    if (schedules.isNotEmpty) return schedules;
    return ClassMeetingSchedule.parseLegacy(day, time);
  }

  String get scheduleSummary {
    final list = effectiveSchedules;
    if (list.isNotEmpty) {
      return list.map((s) => s.formattedCompact).join(' · ');
    }
    if (day == 'TBA' && time == 'TBA') return 'Schedule TBA';
    if (day == 'Flexible' && time == 'Flexible') return 'Flexible schedule';
    if (time.contains('·') || time.contains(';')) return time;
    return '$day · $time';
  }

  String get scheduleMultiline {
    final list = effectiveSchedules;
    if (list.isNotEmpty) {
      return list.map((s) => s.formattedSummary).join('\n');
    }
    return scheduleSummary;
  }
}

class TaskItem {
  final String? id;
  final String title;
  final String subject;
  final String description;
  final String category;
  final DateTime? dueAt;
  final String due;
  final String priority;
  bool done;

  TaskItem({
    this.id,
    required this.title,
    required this.subject,
    this.description = '',
    this.category = 'Task',
    this.dueAt,
    required this.due,
    required this.priority,
    this.done = false,
  });
}

class NoticeItem {
  final String? id;
  final String classId;
  final String announcementId;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final String category;
  bool unread;

  NoticeItem({
    this.id,
    this.classId = '',
    this.announcementId = '',
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.category,
    this.unread = true,
  });
}

// ============================================================
// IN-MEMORY STORES (SYNCHRONIZED FROM SUPABASE)
// ============================================================

const List<ClassItem> sampleClasses = [];

class TaskStore {
  static final List<TaskItem> items = [];
}

class NoticeStore {
  static final List<NoticeItem> items = [];
}
