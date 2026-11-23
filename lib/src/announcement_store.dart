
import 'package:flutter/material.dart';

// ============================================================
// SHARED ANNOUNCEMENT MODEL
// ============================================================

class AnnouncementItem {
  final String id;
  final String title;
  final String message;
  final String classCode;
  final String className;
  final String section;
  final String instructor;
  final String time;

  bool unread;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.message,
    required this.classCode,
    required this.className,
    required this.section,
    required this.instructor,
    required this.time,
    this.unread = true,
  });

  IconData get icon => Icons.campaign_outlined;

  String get category => 'Classes';
}

// ============================================================
// SHARED ANNOUNCEMENT STORE
// ============================================================

class AnnouncementStore {
  static final List<AnnouncementItem> items = [];

  static void add(AnnouncementItem announcement) {
    items.insert(0, announcement);
  }

  static void update(AnnouncementItem announcement) {
    final index = items.indexWhere(
      (item) => item.id == announcement.id,
    );

    if (index != -1) {
      items[index] = announcement;
    }
  }

  static void delete(String id) {
    items.removeWhere((item) => item.id == id);
  }
}

// ============================================================
// STUDENT ENROLLMENT MODEL
// ============================================================

class StudentEnrollment {
  final String code;
  final String name;
  final String section;

  const StudentEnrollment({
    required this.code,
    required this.name,
    required this.section,
  });
}

// ============================================================
// SHARED STUDENT ENROLLMENT STORE
// ============================================================

class StudentEnrollmentStore {
  static final List<StudentEnrollment> items = [];

  static void sync(List<StudentEnrollment> enrollments) {
    items
      ..clear()
      ..addAll(enrollments);
  }
}
