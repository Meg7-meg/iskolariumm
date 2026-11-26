import 'supabase_client_provider.dart';

class StudentTaskRecord {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String category;
  final DateTime? dueAt;
  final String priority; // Low, Medium, High
  final bool isCompleted;

  const StudentTaskRecord({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.category,
    required this.dueAt,
    required this.priority,
    required this.isCompleted,
  });

  factory StudentTaskRecord.fromMap(Map<String, dynamic> map) {
    return StudentTaskRecord(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? 'Task').toString(),
      dueAt: map['due_at'] != null
          ? DateTime.tryParse(map['due_at'].toString())?.toLocal()
          : null,
      priority: (map['priority'] ?? 'Medium').toString(),
      isCompleted: map['is_completed'] == true,
    );
  }
}

class StudentEventRecord {
  final String id;
  final String title;
  final String details;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String location;

  const StudentEventRecord({
    required this.id,
    required this.title,
    required this.details,
    required this.startsAt,
    this.endsAt,
    this.location = '',
  });

  factory StudentEventRecord.fromMap(Map<String, dynamic> map) {
    return StudentEventRecord(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      details: (map['details'] ?? '').toString(),
      startsAt:
          DateTime.tryParse((map['starts_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      endsAt: map['ends_at'] != null
          ? DateTime.tryParse(map['ends_at'].toString())?.toLocal()
          : null,
      location: (map['location'] ?? '').toString(),
    );
  }
}

class StudySessionRecord {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime sessionDate;
  final String startTime; // HH:mm
  final int durationMinutes;
  final bool isCompleted;

  const StudySessionRecord({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.sessionDate,
    required this.startTime,
    required this.durationMinutes,
    required this.isCompleted,
  });

  factory StudySessionRecord.fromMap(Map<String, dynamic> map) {
    return StudySessionRecord(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      sessionDate:
          DateTime.tryParse((map['session_date'] ?? '').toString()) ??
          DateTime.now(),
      startTime: (map['start_time'] ?? '09:00').toString(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 60,
      isCompleted: map['is_completed'] == true,
    );
  }
}

class StudentNoteRecord {
  final String id;
  final String? classId;
  final String? personalClassId;
  final String title;
  final String subjectLabel;
  final String content;
  final DateTime? reminderAt;
  final DateTime updatedAt;

  const StudentNoteRecord({
    required this.id,
    this.classId,
    this.personalClassId,
    required this.title,
    required this.subjectLabel,
    required this.content,
    this.reminderAt,
    required this.updatedAt,
  });

  factory StudentNoteRecord.fromMap(Map<String, dynamic> map) {
    return StudentNoteRecord(
      id: map['id'].toString(),
      classId: map['class_id']?.toString(),
      personalClassId: map['personal_class_id']?.toString(),
      title: (map['title'] ?? '').toString(),
      subjectLabel: (map['subject_label'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      reminderAt: map['reminder_at'] != null
          ? DateTime.tryParse(map['reminder_at'].toString())?.toLocal()
          : null,
      updatedAt:
          DateTime.tryParse((map['updated_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}

class StudentNotificationRecord {
  final String id;
  final String title;
  final String message;
  final String category;
  final String classId;
  final String announcementId;
  final DateTime createdAt;
  final DateTime? readAt;

  const StudentNotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.classId = '',
    this.announcementId = '',
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory StudentNotificationRecord.fromMap(Map<String, dynamic> map) {
    return StudentNotificationRecord(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      category: (map['category'] ?? 'Other').toString(),
      classId: map['class_id']?.toString() ?? '',
      announcementId: map['announcement_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'].toString())?.toLocal()
          : null,
    );
  }
}

class OrganizerService {
  const OrganizerService._();

  // ---------------- TASKS ----------------

  static Future<List<StudentTaskRecord>> getTasks() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('student_tasks')
        .select()
        .eq('student_id', uid)
        .order('due_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows)
        .map(StudentTaskRecord.fromMap)
        .toList();
  }

  static Future<StudentTaskRecord> createTask({
    required String title,
    String subject = '',
    String description = '',
    String category = 'Task',
    DateTime? dueAt,
    String priority = 'Medium',
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('student_tasks')
        .insert({
          'student_id': uid,
          'title': title.trim(),
          'subject': subject.trim(),
          'description': description.trim(),
          'category': category.trim().isEmpty ? 'Task' : category.trim(),
          'due_at': dueAt?.toUtc().toIso8601String(),
          'priority': priority,
        })
        .select()
        .single();

    return StudentTaskRecord.fromMap(row);
  }

  static Future<void> updateTask({
    required String id,
    required String title,
    String subject = '',
    String description = '',
    String category = 'Task',
    DateTime? dueAt,
    String priority = 'Medium',
    bool? isCompleted,
  }) async {
    final updates = <String, dynamic>{
      'title': title.trim(),
      'subject': subject.trim(),
      'description': description.trim(),
      'category': category.trim().isEmpty ? 'Task' : category.trim(),
      'due_at': dueAt?.toUtc().toIso8601String(),
      'priority': priority,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (isCompleted != null) {
      updates['is_completed'] = isCompleted;
    }

    await supabase.from('student_tasks').update(updates).eq('id', id);
  }

  static Future<void> toggleTaskCompleted(String id, bool isCompleted) async {
    await supabase
        .from('student_tasks')
        .update({
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> deleteTask(String id) async {
    await supabase.from('student_tasks').delete().eq('id', id);
  }

  // ---------------- EVENTS ----------------

  static Future<List<StudentEventRecord>> getEvents() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('student_events')
        .select()
        .eq('student_id', uid)
        .order('starts_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows)
        .map(StudentEventRecord.fromMap)
        .toList();
  }

  static Future<StudentEventRecord> createEvent({
    required String title,
    String details = '',
    required DateTime startsAt,
    DateTime? endsAt,
    String location = '',
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('student_events')
        .insert({
          'student_id': uid,
          'title': title.trim(),
          'details': details.trim(),
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt?.toUtc().toIso8601String(),
          'location': location.trim(),
        })
        .select()
        .single();

    return StudentEventRecord.fromMap(row);
  }

  static Future<void> deleteEvent(String id) async {
    await supabase.from('student_events').delete().eq('id', id);
  }

  // ---------------- STUDY SESSIONS ----------------

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<List<StudySessionRecord>> getStudySessions() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('study_sessions')
        .select()
        .eq('student_id', uid)
        .order('session_date', ascending: true);

    return List<Map<String, dynamic>>.from(rows)
        .map(StudySessionRecord.fromMap)
        .toList();
  }

  static Future<StudySessionRecord> createStudySession({
    required String title,
    String subject = '',
    String description = '',
    required DateTime sessionDate,
    required String startTime,
    required int durationMinutes,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('study_sessions')
        .insert({
          'student_id': uid,
          'title': title.trim(),
          'subject': subject.trim(),
          'description': description.trim(),
          'session_date': _isoDate(sessionDate),
          'start_time': startTime,
          'duration_minutes': durationMinutes,
        })
        .select()
        .single();

    return StudySessionRecord.fromMap(row);
  }

  static Future<void> updateStudySession({
    required String id,
    required String title,
    String subject = '',
    String description = '',
    required DateTime sessionDate,
    required String startTime,
    required int durationMinutes,
  }) async {
    await supabase
        .from('study_sessions')
        .update({
          'title': title.trim(),
          'subject': subject.trim(),
          'description': description.trim(),
          'session_date': _isoDate(sessionDate),
          'start_time': startTime,
          'duration_minutes': durationMinutes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> toggleStudySessionCompleted(
    String id,
    bool isCompleted,
  ) async {
    await supabase
        .from('study_sessions')
        .update({
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> deleteStudySession(String id) async {
    await supabase.from('study_sessions').delete().eq('id', id);
  }

  // ---------------- NOTES & REMINDERS ----------------

  static Future<List<StudentNoteRecord>> getNotes({
    String? classId,
    String? personalClassId,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    var query = supabase.from('student_notes').select().eq('student_id', uid);

    if (classId != null) {
      query = query.eq('class_id', classId);
    } else if (personalClassId != null) {
      query = query.eq('personal_class_id', personalClassId);
    }

    final rows = await query.order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(StudentNoteRecord.fromMap)
        .toList();
  }

  static Future<StudentNoteRecord> createNote({
    String? classId,
    String? personalClassId,
    String title = '',
    String subjectLabel = '',
    required String content,
    DateTime? reminderAt,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('student_notes')
        .insert({
          'student_id': uid,
          'class_id': classId,
          'personal_class_id': personalClassId,
          'title': title.trim(),
          'subject_label': subjectLabel.trim(),
          'content': content.trim(),
          'reminder_at': reminderAt?.toUtc().toIso8601String(),
        })
        .select()
        .single();

    return StudentNoteRecord.fromMap(row);
  }

  static Future<void> updateNote({
    required String id,
    String? title,
    required String content,
    DateTime? reminderAt,
  }) async {
    await supabase
        .from('student_notes')
        .update({
          if (title != null) 'title': title.trim(),
          'content': content.trim(),
          'reminder_at': reminderAt?.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> deleteNote(String id) async {
    await supabase.from('student_notes').delete().eq('id', id);
  }

  // ---------------- NOTIFICATIONS ----------------

  static Future<List<StudentNotificationRecord>> getNotifications() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('student_notifications')
        .select()
        .eq('student_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(StudentNotificationRecord.fromMap)
        .toList();
  }

  static Stream<List<StudentNotificationRecord>> notificationsStream() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();

    return supabase
        .from('student_notifications')
        .stream(primaryKey: ['id'])
        .eq('student_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(StudentNotificationRecord.fromMap).toList());
  }

  static Future<void> markNotificationRead(String id) async {
    await supabase
        .from('student_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  static Future<void> markAllNotificationsRead() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    await supabase
        .from('student_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('student_id', uid)
        .isFilter('read_at', null);
  }

  static Future<void> deleteNotification(String id) async {
    await supabase.from('student_notifications').delete().eq('id', id);
  }
}
