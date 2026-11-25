import 'supabase_client_provider.dart';

class AttendanceRecord {
  final String id;
  final String classId;
  final String className;
  final String subjectCode;
  final String instructorName;
  final String studentId;
  final String studentName;
  final DateTime attendanceDate;
  final String status; // present, absent, late, excused
  final String? scheduleId;
  final String meetingKey;

  const AttendanceRecord({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectCode,
    required this.instructorName,
    required this.studentId,
    required this.studentName,
    required this.attendanceDate,
    required this.status,
    this.scheduleId,
    this.meetingKey = '',
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final cls = map['classes'];
    final student = map['profiles'];
    final inst = cls is Map ? cls['profiles'] : null;

    return AttendanceRecord(
      id: map['id'].toString(),
      classId: map['class_id'].toString(),
      className: cls is Map ? (cls['class_name'] ?? '').toString() : '',
      subjectCode: cls is Map ? (cls['subject_code'] ?? '').toString() : '',
      instructorName:
          inst is Map ? (inst['full_name'] ?? 'Instructor').toString() : '',
      studentId: map['student_id'].toString(),
      studentName:
          student is Map ? (student['full_name'] ?? 'Student').toString() : '',
      attendanceDate:
          DateTime.tryParse((map['attendance_date'] ?? '').toString()) ??
              DateTime.now(),
      status: (map['status'] ?? 'present').toString().toLowerCase(),
      scheduleId: map['schedule_id']?.toString(),
      meetingKey: (map['meeting_key'] ?? '').toString(),
    );
  }
}

class ScoreRecord {
  final String id;
  final String classId;
  final String className;
  final String subjectCode;
  final String instructorName;
  final String studentId;
  final String studentName;
  final String? assignmentId;
  final String? quizId;
  final String assessmentName;
  final String category; // assignment, activity, project, quiz, exam
  final double score;
  final double maxScore;
  final String status; // pending, released
  final DateTime createdAt;

  const ScoreRecord({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectCode,
    required this.instructorName,
    required this.studentId,
    required this.studentName,
    this.assignmentId,
    this.quizId,
    required this.assessmentName,
    required this.category,
    required this.score,
    required this.maxScore,
    this.status = 'released',
    required this.createdAt,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100.0 : 0.0;

  factory ScoreRecord.fromMap(Map<String, dynamic> map) {
    final cls = map['classes'];
    final student = map['profiles'];
    final inst = cls is Map ? cls['profiles'] : null;

    return ScoreRecord(
      id: map['id'].toString(),
      classId: map['class_id'].toString(),
      className: cls is Map ? (cls['class_name'] ?? '').toString() : '',
      subjectCode: cls is Map ? (cls['subject_code'] ?? '').toString() : '',
      instructorName:
          inst is Map ? (inst['full_name'] ?? 'Instructor').toString() : '',
      studentId: map['student_id'].toString(),
      studentName:
          student is Map ? (student['full_name'] ?? 'Student').toString() : '',
      assignmentId: map['assignment_id']?.toString(),
      quizId: map['quiz_id']?.toString(),
      assessmentName: (map['assessment_name'] ?? '').toString(),
      category: (map['category'] ?? 'quiz').toString().toLowerCase(),
      score: (map['score'] as num?)?.toDouble() ?? 0,
      maxScore: (map['max_score'] as num?)?.toDouble() ?? 100,
      status: (map['status'] ?? 'released').toString().toLowerCase(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class AttendanceSessionRecord {
  final String id;
  final String classId;
  final String? scheduleId;
  final String meetingKey;
  final DateTime sessionDate;
  final String meetingLabel;
  final String room;

  const AttendanceSessionRecord({
    required this.id,
    required this.classId,
    this.scheduleId,
    this.meetingKey = '',
    required this.sessionDate,
    this.meetingLabel = '',
    this.room = '',
  });

  factory AttendanceSessionRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceSessionRecord(
      id: map['id'].toString(),
      classId: map['class_id'].toString(),
      scheduleId: map['schedule_id']?.toString(),
      meetingKey: (map['meeting_key'] ?? '').toString(),
      sessionDate:
          DateTime.tryParse((map['session_date'] ?? '').toString()) ??
              DateTime.now(),
      meetingLabel: (map['meeting_label'] ?? '').toString(),
      room: (map['room'] ?? '').toString(),
    );
  }
}

class AnnouncementRecord {
  final String id;
  final String classId;
  final String instructorId;
  final String className;
  final String subjectCode;
  final String section;
  final String instructorName;
  final String title;
  final String content;
  final bool isArchived;
  final DateTime createdAt;

  const AnnouncementRecord({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.className,
    required this.subjectCode,
    required this.section,
    required this.instructorName,
    required this.title,
    required this.content,
    this.isArchived = false,
    required this.createdAt,
  });

  factory AnnouncementRecord.fromMap(Map<String, dynamic> map) {
    final cls = map['classes'];
    final inst = map['profiles'];

    return AnnouncementRecord(
      id: map['id'].toString(),
      classId: map['class_id'].toString(),
      instructorId: map['instructor_id'].toString(),
      className: cls is Map ? (cls['class_name'] ?? '').toString() : '',
      subjectCode: cls is Map ? (cls['subject_code'] ?? '').toString() : '',
      section: cls is Map ? (cls['section'] ?? 'Section A').toString() : '',
      instructorName:
          inst is Map ? (inst['full_name'] ?? 'Instructor').toString() : '',
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      isArchived: map['is_archived'] == true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class AcademicService {
  const AcademicService._();

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ---------------- ATTENDANCE ----------------

  static Future<List<AttendanceRecord>> getClassAttendance({
    required String classId,
    required DateTime date,
    String? meetingKey,
  }) async {
    final dateStr = _isoDate(date);
    try {
      var query = supabase
          .from('attendance')
          .select(
            '*, profiles!attendance_student_id_fkey(full_name), classes(class_name, subject_code)',
          )
          .eq('class_id', classId)
          .eq('attendance_date', dateStr);

      if (meetingKey != null && meetingKey.isNotEmpty) {
        query = query.eq('meeting_key', meetingKey);
      }

      final rows = await query;
      return List<Map<String, dynamic>>.from(rows)
          .map(AttendanceRecord.fromMap)
          .toList();
    } catch (_) {
      // Fallback if meeting_key column hasn't been migrated yet.
      final rows = await supabase
          .from('attendance')
          .select(
            '*, profiles!attendance_student_id_fkey(full_name), classes(class_name, subject_code)',
          )
          .eq('class_id', classId)
          .eq('attendance_date', dateStr);

      return List<Map<String, dynamic>>.from(rows)
          .map(AttendanceRecord.fromMap)
          .toList();
    }
  }

  /// Returns a map of `'$classId|$meetingKey' -> recordedStudentCount` for [date].
  static Future<Map<String, int>> getAttendanceCountsForDate({
    required List<String> classIds,
    required DateTime date,
  }) async {
    if (classIds.isEmpty) return const {};
    final dateStr = _isoDate(date);
    try {
      final rows = await supabase
          .from('attendance')
          .select('class_id, meeting_key')
          .inFilter('class_id', classIds)
          .eq('attendance_date', dateStr);

      final counts = <String, int>{};
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final cid = row['class_id'].toString();
        final mKey = (row['meeting_key'] ?? '').toString();
        final key = '$cid|$mKey';
        counts[key] = (counts[key] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      // Fallback if meeting_key column hasn't been migrated yet.
      try {
        final rows = await supabase
            .from('attendance')
            .select('class_id')
            .inFilter('class_id', classIds)
            .eq('attendance_date', dateStr);

        final counts = <String, int>{};
        for (final row in List<Map<String, dynamic>>.from(rows)) {
          final cid = row['class_id'].toString();
          final key = '$cid|';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        return counts;
      } catch (_) {
        return const {};
      }
    }
  }

  static Future<void> saveClassAttendance({
    required String classId,
    required DateTime date,
    required Map<String, String> studentStatuses,
    String? scheduleId,
    String? meetingKey,
    String meetingLabel = '',
    String room = '',
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final dateStr = _isoDate(date);
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final mKey = (meetingKey ?? '').trim();
    final schedId =
        (scheduleId != null && scheduleId.trim().isNotEmpty) ? scheduleId.trim() : null;

    if (studentStatuses.isEmpty) return;

    // Prefer atomic transactional RPC when migration 008 is applied.
    try {
      await supabase.rpc(
        'save_attendance_session',
        params: {
          'p_class_id': classId,
          'p_attendance_date': dateStr,
          'p_schedule_id': schedId,
          'p_meeting_key': mKey,
          'p_meeting_label': meetingLabel.trim(),
          'p_room': room.trim(),
          'p_records': studentStatuses.entries
              .map(
                (e) => {
                  'student_id': e.key,
                  'status': e.value.toLowerCase(),
                },
              )
              .toList(),
        },
      );
      return;
    } catch (_) {
      // Fall back to direct upsert if RPC isn't deployed yet.
    }

    final payload = studentStatuses.entries
        .map(
          (entry) => {
            'class_id': classId,
            'student_id': entry.key,
            'marked_by': uid,
            'attendance_date': dateStr,
            'status': entry.value.toLowerCase(),
            'meeting_key': mKey,
            if (schedId != null) 'schedule_id': schedId,
            'updated_at': nowIso,
          },
        )
        .toList();

    try {
      await supabase.from('attendance').upsert(
            payload,
            onConflict: 'class_id,student_id,attendance_date,meeting_key',
          );
    } catch (_) {
      final legacyPayload = studentStatuses.entries
          .map(
            (entry) => {
              'class_id': classId,
              'student_id': entry.key,
              'marked_by': uid,
              'attendance_date': dateStr,
              'status': entry.value.toLowerCase(),
              'updated_at': nowIso,
            },
          )
          .toList();
      await supabase.from('attendance').upsert(
            legacyPayload,
            onConflict: 'class_id,student_id,attendance_date',
          );
    }
  }

  static Future<List<AttendanceSessionRecord>> getClassAttendanceSessions(
    String classId,
  ) async {
    try {
      final rows = await supabase
          .from('attendance_sessions')
          .select('*')
          .eq('class_id', classId)
          .order('session_date', ascending: false);

      return List<Map<String, dynamic>>.from(rows)
          .map(AttendanceSessionRecord.fromMap)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<AttendanceRecord>> getStudentAttendance({
    String? classId,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    var query = supabase
        .from('attendance')
        .select(
          '*, classes(class_name, subject_code, profiles!classes_instructor_id_fkey(full_name))',
        )
        .eq('student_id', uid);

    if (classId != null && classId.isNotEmpty) {
      query = query.eq('class_id', classId);
    }

    final rows = await query.order('attendance_date', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(AttendanceRecord.fromMap)
        .toList();
  }

  // ---------------- SCORES ----------------

  static Future<List<ScoreRecord>> getClassScores(String classId) async {
    final rows = await supabase
        .from('scores')
        .select(
          '*, profiles!scores_student_id_fkey(full_name), classes(class_name, subject_code)',
        )
        .eq('class_id', classId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(ScoreRecord.fromMap)
        .toList();
  }

  static Future<void> saveAssessmentScores({
    required String classId,
    required String assessmentName,
    required String category,
    required double maxScore,
    required Map<String, double> studentScores,
    String? assignmentId,
    String? quizId,
    String status = 'released',
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');
    if (maxScore <= 0) throw Exception('Max score must be greater than 0.');

    final normalizedCategory = category.toLowerCase();
    final trimmedName = assessmentName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Assessment name is required.');
    }

    final payload = <Map<String, dynamic>>[];
    for (final entry in studentScores.entries) {
      if (entry.value < 0 || entry.value > maxScore) {
        throw Exception(
          'Score must be between 0 and $maxScore.',
        );
      }
      payload.add({
        'class_id': classId,
        'student_id': entry.key,
        'instructor_id': uid,
        if (assignmentId != null && assignmentId.isNotEmpty)
          'assignment_id': assignmentId,
        if (quizId != null && quizId.isNotEmpty) 'quiz_id': quizId,
        'assessment_name': trimmedName,
        'category': normalizedCategory,
        'score': entry.value,
        'max_score': maxScore,
        'status': status,
      });
    }

    if (payload.isEmpty) {
      throw Exception('Enter at least one student score before submitting.');
    }

    if ((assignmentId != null && assignmentId.isNotEmpty) ||
        (quizId != null && quizId.isNotEmpty)) {
      try {
        await supabase.rpc(
          'save_assessment_scores',
          params: {
            'p_class_id': classId,
            'p_assessment_name': trimmedName,
            'p_category': normalizedCategory,
            'p_max_score': maxScore,
            'p_assignment_id':
                (assignmentId != null && assignmentId.isNotEmpty)
                    ? assignmentId
                    : null,
            'p_quiz_id':
                (quizId != null && quizId.isNotEmpty) ? quizId : null,
            'p_status': status,
            'p_scores': studentScores.entries
                .map((e) => {'student_id': e.key, 'score': e.value})
                .toList(),
          },
        );
        return;
      } catch (_) {
        // Fallback if RPC isn't applied yet: update existing or insert.
      }
    }

    // Fallback: update existing rows for this assessment+student, insert new ones.
    final existing = await getClassScores(classId);
    final existingByStudent = <String, ScoreRecord>{};
    for (final r in existing) {
      final matchesLink = (assignmentId != null &&
              assignmentId.isNotEmpty &&
              r.assignmentId == assignmentId) ||
          (quizId != null && quizId.isNotEmpty && r.quizId == quizId) ||
          (r.assessmentName.toLowerCase() == trimmedName.toLowerCase() &&
              r.category.toLowerCase() == normalizedCategory);
      if (matchesLink) {
        existingByStudent[r.studentId] = r;
      }
    }

    final toInsert = <Map<String, dynamic>>[];
    for (final entry in studentScores.entries) {
      final prev = existingByStudent[entry.key];
      if (prev != null) {
        await updateScore(
          scoreId: prev.id,
          score: entry.value,
          maxScore: maxScore,
        );
      } else {
        toInsert.add({
          'class_id': classId,
          'student_id': entry.key,
          'instructor_id': uid,
          'assessment_name': trimmedName,
          'category': normalizedCategory,
          'score': entry.value,
          'max_score': maxScore,
        });
      }
    }

    if (toInsert.isNotEmpty) {
      await supabase.from('scores').insert(toInsert);
    }
  }

  static Future<void> updateScore({
    required String scoreId,
    required double score,
    required double maxScore,
  }) async {
    if (score < 0 || score > maxScore) {
      throw Exception('Score must be between 0 and $maxScore.');
    }

    await supabase
        .from('scores')
        .update({
          'score': score,
          'max_score': maxScore,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', scoreId);
  }

  static Future<List<ScoreRecord>> getStudentScores({String? classId}) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    var query = supabase
        .from('scores')
        .select(
          '*, classes(class_name, subject_code, profiles!classes_instructor_id_fkey(full_name))',
        )
        .eq('student_id', uid);

    if (classId != null && classId.isNotEmpty) {
      query = query.eq('class_id', classId);
    }

    final rows = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(ScoreRecord.fromMap)
        .toList();
  }

  // ---------------- ANNOUNCEMENTS ----------------

  static Future<List<AnnouncementRecord>> getInstructorAnnouncements() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('announcements')
        .select(
          '*, classes(class_name, subject_code, section), profiles!announcements_instructor_id_fkey(full_name)',
        )
        .eq('instructor_id', uid)
        .eq('is_archived', false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(AnnouncementRecord.fromMap)
        .toList();
  }

  static Future<AnnouncementRecord> createAnnouncement({
    required String classId,
    required String title,
    required String content,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('announcements')
        .insert({
          'class_id': classId,
          'instructor_id': uid,
          'title': title.trim(),
          'content': content.trim(),
        })
        .select(
          '*, classes(class_name, subject_code, section), profiles!announcements_instructor_id_fkey(full_name)',
        )
        .single();

    return AnnouncementRecord.fromMap(row);
  }

  static Future<AnnouncementRecord> updateAnnouncement({
    required String id,
    required String classId,
    required String title,
    required String content,
  }) async {
    final row = await supabase
        .from('announcements')
        .update({
          'class_id': classId,
          'title': title.trim(),
          'content': content.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select(
          '*, classes(class_name, subject_code, section), profiles!announcements_instructor_id_fkey(full_name)',
        )
        .single();

    return AnnouncementRecord.fromMap(row);
  }

  static Future<void> deleteAnnouncement(String id) async {
    await supabase.from('announcements').delete().eq('id', id);
  }

  static Future<List<AnnouncementRecord>> getStudentAnnouncements() async {
    final rows = await supabase
        .from('announcements')
        .select(
          '*, classes(class_name, subject_code, section), profiles!announcements_instructor_id_fkey(full_name)',
        )
        .eq('is_archived', false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(AnnouncementRecord.fromMap)
        .toList();
  }

  // ---------------- CLASS ASSIGNMENTS ----------------

  /// Returns all non-archived assignments for a specific class.
  static Future<List<ClassAssignmentRecord>> getClassAssignments(
    String classId, {
    bool includeArchived = false,
  }) async {
    var query = supabase
        .from('class_assignments')
        .select('*, classes(class_name, subject_code, section)')
        .eq('class_id', classId);
    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }
    final rows = await query.order('due_at', ascending: true, nullsFirst: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(ClassAssignmentRecord.fromMap)
        .toList();
  }

  /// Returns all non-archived assignments visible to the current student.
  static Future<List<ClassAssignmentRecord>> getStudentAssignments() async {
    final rows = await supabase
        .from('class_assignments')
        .select('*, classes(class_name, subject_code, section)')
        .eq('is_archived', false)
        .order('due_at', ascending: true, nullsFirst: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(ClassAssignmentRecord.fromMap)
        .toList();
  }

  static Future<ClassAssignmentRecord> createClassAssignment({
    required String classId,
    required String title,
    String description = '',
    String category = 'Assignment',
    String priority = 'medium',
    DateTime? dueAt,
    double? maxScore,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final cleanCat = category.trim().isEmpty ? 'Assignment' : category.trim();
    final cleanPriority = priority.trim().isEmpty
        ? 'medium'
        : priority.trim().toLowerCase();

    final basePayload = <String, dynamic>{
      'class_id': classId,
      'created_by': uid,
      'title': title.trim(),
      'description': description.trim(),
      'priority': cleanPriority,
      'due_at': dueAt?.toUtc().toIso8601String(),
    };

    try {
      final row = await supabase
          .from('class_assignments')
          .insert({
            ...basePayload,
            'category': cleanCat,
            'max_score': maxScore,
          })
          .select('*, classes(class_name, subject_code, section)')
          .single();
      return ClassAssignmentRecord.fromMap(row);
    } catch (_) {
      // Fallback if category / max_score columns haven't been added yet.
      final row = await supabase
          .from('class_assignments')
          .insert(basePayload)
          .select('*, classes(class_name, subject_code, section)')
          .single();
      return ClassAssignmentRecord.fromMap(row);
    }
  }

  static Future<ClassAssignmentRecord> updateClassAssignment({
    required String id,
    required String title,
    String description = '',
    String category = 'Assignment',
    String priority = 'medium',
    DateTime? dueAt,
    double? maxScore,
  }) async {
    final cleanCat = category.trim().isEmpty ? 'Assignment' : category.trim();
    final cleanPriority = priority.trim().isEmpty
        ? 'medium'
        : priority.trim().toLowerCase();

    final basePayload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'priority': cleanPriority,
      'due_at': dueAt?.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final row = await supabase
          .from('class_assignments')
          .update({
            ...basePayload,
            'category': cleanCat,
            'max_score': maxScore,
          })
          .eq('id', id)
          .select('*, classes(class_name, subject_code, section)')
          .single();
      return ClassAssignmentRecord.fromMap(row);
    } catch (_) {
      final row = await supabase
          .from('class_assignments')
          .update(basePayload)
          .eq('id', id)
          .select('*, classes(class_name, subject_code, section)')
          .single();
      return ClassAssignmentRecord.fromMap(row);
    }
  }

  static Future<void> archiveClassAssignment(String id, bool isArchived) async {
    await supabase
        .from('class_assignments')
        .update({
          'is_archived': isArchived,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> deleteClassAssignment(String id) async {
    await supabase.from('class_assignments').delete().eq('id', id);
  }

  // ---------------- QUIZZES ----------------

  static Future<List<QuizRecord>> getClassQuizzes(String classId) async {
    try {
      final rows = await supabase
          .from('quizzes')
          .select('*, classes(class_name, subject_code, section)')
          .eq('class_id', classId)
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows)
          .map(QuizRecord.fromMap)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<QuizRecord> createQuiz({
    required String classId,
    required String title,
    String instructions = '',
    double maxScore = 100,
    DateTime? opensAt,
    DateTime? closesAt,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('quizzes')
        .insert({
          'class_id': classId,
          'instructor_id': uid,
          'title': title.trim(),
          'instructions': instructions.trim(),
          'max_score': maxScore,
          'opens_at': opensAt?.toUtc().toIso8601String(),
          'closes_at': closesAt?.toUtc().toIso8601String(),
        })
        .select('*, classes(class_name, subject_code, section)')
        .single();

    return QuizRecord.fromMap(row);
  }

  static Future<QuizRecord> updateQuiz({
    required String id,
    required String title,
    String instructions = '',
    double maxScore = 100,
    DateTime? opensAt,
    DateTime? closesAt,
  }) async {
    final row = await supabase
        .from('quizzes')
        .update({
          'title': title.trim(),
          'instructions': instructions.trim(),
          'max_score': maxScore,
          'opens_at': opensAt?.toUtc().toIso8601String(),
          'closes_at': closesAt?.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('*, classes(class_name, subject_code, section)')
        .single();

    return QuizRecord.fromMap(row);
  }

  static Future<void> deleteQuiz(String id) async {
    await supabase.from('quizzes').delete().eq('id', id);
  }

  // ---------------- LEARNING MATERIALS ----------------

  static Future<List<LearningMaterialRecord>> getClassMaterials(
    String classId,
  ) async {
    try {
      final rows = await supabase
          .from('learning_materials')
          .select('*')
          .eq('class_id', classId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows)
          .map(LearningMaterialRecord.fromMap)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<LearningMaterialRecord> createLearningMaterial({
    required String classId,
    required String title,
    String description = '',
    String? externalUrl,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('learning_materials')
        .insert({
          'class_id': classId,
          'instructor_id': uid,
          'title': title.trim(),
          'description': description.trim(),
          if (externalUrl != null && externalUrl.trim().isNotEmpty)
            'external_url': externalUrl.trim(),
        })
        .select('*')
        .single();

    return LearningMaterialRecord.fromMap(row);
  }

  static Future<void> deleteLearningMaterial(String id) async {
    await supabase.from('learning_materials').delete().eq('id', id);
  }
}

class ClassAssignmentRecord {
  final String id;
  final String classId;
  final String createdBy;
  final String className;
  final String subjectCode;
  final String section;
  final String title;
  final String description;
  final String category;
  final String priority;
  final DateTime? dueAt;
  final double? maxScore;
  final bool isArchived;
  final DateTime createdAt;

  const ClassAssignmentRecord({
    required this.id,
    required this.classId,
    required this.createdBy,
    required this.className,
    required this.subjectCode,
    required this.section,
    required this.title,
    required this.description,
    required this.category,
    this.priority = 'medium',
    this.dueAt,
    this.maxScore,
    this.isArchived = false,
    required this.createdAt,
  });

  factory ClassAssignmentRecord.fromMap(Map<String, dynamic> map) {
    final cls = map['classes'];
    return ClassAssignmentRecord(
      id: map['id'].toString(),
      classId: map['class_id'].toString(),
      createdBy: (map['created_by'] ?? map['instructor_id'] ?? '').toString(),
      className: cls is Map ? (cls['class_name'] ?? '').toString() : '',
      subjectCode: cls is Map ? (cls['subject_code'] ?? '').toString() : '',
      section: cls is Map ? (cls['section'] ?? 'Section A').toString() : '',
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? 'Assignment').toString(),
      priority: (map['priority'] ?? 'medium').toString().toLowerCase(),
      dueAt: DateTime.tryParse((map['due_at'] ?? '').toString())?.toLocal(),
      maxScore: map['max_score'] == null
          ? null
          : double.tryParse(map['max_score'].toString()),
      isArchived: map['is_archived'] == true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class QuizRecord {
  final String id;
  final String classId;
  final String instructorId;
  final String title;
  final String instructions;
  final double maxScore;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final DateTime createdAt;

  const QuizRecord({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.title,
    required this.instructions,
    required this.maxScore,
    this.opensAt,
    this.closesAt,
    required this.createdAt,
  });

  factory QuizRecord.fromMap(Map<String, dynamic> map) {
    return QuizRecord(
      id: map['id'].toString(),
      classId: (map['class_id'] ?? '').toString(),
      instructorId: (map['instructor_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      instructions: (map['instructions'] ?? '').toString(),
      maxScore: double.tryParse((map['max_score'] ?? '100').toString()) ?? 100,
      opensAt: DateTime.tryParse((map['opens_at'] ?? '').toString())?.toLocal(),
      closesAt:
          DateTime.tryParse((map['closes_at'] ?? '').toString())?.toLocal(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class LearningMaterialRecord {
  final String id;
  final String classId;
  final String instructorId;
  final String title;
  final String description;
  final String? externalUrl;
  final DateTime createdAt;

  const LearningMaterialRecord({
    required this.id,
    required this.classId,
    required this.instructorId,
    required this.title,
    required this.description,
    this.externalUrl,
    required this.createdAt,
  });

  factory LearningMaterialRecord.fromMap(Map<String, dynamic> map) {
    return LearningMaterialRecord(
      id: map['id'].toString(),
      classId: (map['class_id'] ?? '').toString(),
      instructorId: (map['instructor_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      externalUrl: map['external_url']?.toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
