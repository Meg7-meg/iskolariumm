import 'dart:math';
import 'supabase_client_provider.dart';

enum MeetingLocationType {
  online,
  roomNumber,
  tba;

  String get label => switch (this) {
        MeetingLocationType.online => 'Online',
        MeetingLocationType.roomNumber => 'Room Number',
        MeetingLocationType.tba => 'TBA',
      };

  static MeetingLocationType fromRoom(String room) {
    final normalized = room.trim().toLowerCase();
    if (normalized == 'online') return MeetingLocationType.online;
    if (normalized == 'tba') return MeetingLocationType.tba;
    return MeetingLocationType.roomNumber;
  }
}

class ClassMeetingSchedule {
  final String? id;
  final String? classId;
  final String dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String room;

  const ClassMeetingSchedule({
    this.id,
    this.classId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.room = '',
  });

  MeetingLocationType get locationType => MeetingLocationType.fromRoom(room);

  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  int get weekday {
    final idx = daysOfWeek.indexWhere(
      (d) => d.toLowerCase() == dayOfWeek.trim().toLowerCase(),
    );
    return idx >= 0 ? idx + 1 : 1;
  }

  String get shortDay =>
      dayOfWeek.length >= 3 ? dayOfWeek.substring(0, 3) : dayOfWeek;

  bool get isValidTimeOrder => endMinutes > startMinutes;

  bool overlapsWith(ClassMeetingSchedule other) {
    if (dayOfWeek.toLowerCase() != other.dayOfWeek.toLowerCase()) return false;
    return startMinutes < other.endMinutes && other.startMinutes < endMinutes;
  }

  String get formattedStartTime => formatMinutes(startMinutes);
  String get formattedEndTime => formatMinutes(endMinutes);
  String get formattedTimeRange => '$formattedStartTime - $formattedEndTime';
  String get formattedSummary {
    final trimmedRoom = room.trim();
    return trimmedRoom.isEmpty
        ? '$dayOfWeek — $formattedTimeRange'
        : '$dayOfWeek — $formattedTimeRange · $trimmedRoom';
  }

  String get formattedCompact {
    final trimmedRoom = room.trim();
    return trimmedRoom.isEmpty
        ? '$shortDay · $formattedTimeRange'
        : '$shortDay · $formattedTimeRange ($trimmedRoom)';
  }

  String get startTimeSql => _minutesToSqlTime(startMinutes);
  String get endTimeSql => _minutesToSqlTime(endMinutes);

  ClassMeetingSchedule copyWith({
    String? id,
    String? classId,
    String? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    String? room,
  }) {
    return ClassMeetingSchedule(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      room: room ?? this.room,
    );
  }

  Map<String, dynamic> toInsertMap(String targetClassId) {
    return {
      'class_id': targetClassId,
      'day_of_week': normalizeDay(dayOfWeek) ?? 'Monday',
      'start_time': startTimeSql,
      'end_time': endTimeSql,
      'room': room.trim(),
    };
  }

  factory ClassMeetingSchedule.fromMap(Map<String, dynamic> map) {
    return ClassMeetingSchedule(
      id: map['id']?.toString(),
      classId: map['class_id']?.toString(),
      dayOfWeek: normalizeDay((map['day_of_week'] ?? '').toString()) ?? 'Monday',
      startMinutes: _parseSqlTime((map['start_time'] ?? '').toString()) ?? 8 * 60,
      endMinutes: _parseSqlTime((map['end_time'] ?? '').toString()) ?? 9 * 60,
      room: (map['room'] ?? '').toString(),
    );
  }

  static String formatMinutes(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, 23 * 60 + 59);
    final hour24 = clamped ~/ 60;
    final minute = clamped % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minStr $period';
  }

  static String _minutesToSqlTime(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, 23 * 60 + 59);
    final h = (clamped ~/ 60).toString().padLeft(2, '0');
    final m = (clamped % 60).toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  static int? _parseSqlTime(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h * 60 + m).clamp(0, 23 * 60 + 59);
  }

  static String? normalizeDay(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return null;
    for (final d in daysOfWeek) {
      if (lower == d.toLowerCase() || lower == d.toLowerCase().substring(0, 3)) {
        return d;
      }
    }
    return null;
  }

  static List<ClassMeetingSchedule> sortSchedules(
    List<ClassMeetingSchedule> items,
  ) {
    final copy = List<ClassMeetingSchedule>.from(items);
    copy.sort((a, b) {
      final dayCmp = a.weekday.compareTo(b.weekday);
      if (dayCmp != 0) return dayCmp;
      return a.startMinutes.compareTo(b.startMinutes);
    });
    return copy;
  }

  static String encodeScheduleDay(List<ClassMeetingSchedule> schedules) {
    if (schedules.isEmpty) return '';
    final sorted = sortSchedules(schedules);
    final seen = <String>{};
    final orderedDays = <String>[];
    for (final s in sorted) {
      if (seen.add(s.dayOfWeek)) {
        orderedDays.add(s.dayOfWeek);
      }
    }
    return orderedDays.join(', ');
  }

  static String encodeScheduleTime(List<ClassMeetingSchedule> schedules) {
    if (schedules.isEmpty) return '';
    final sorted = sortSchedules(schedules);
    if (sorted.length == 1) {
      return sorted.first.formattedTimeRange;
    }
    return sorted.map((s) {
      final r = s.room.trim();
      return r.isEmpty
          ? '${s.shortDay} ${s.formattedTimeRange}'
          : '${s.shortDay} ${s.formattedTimeRange} @ $r';
    }).join(' · ');
  }

  static String encodeRoomSummary(List<ClassMeetingSchedule> schedules) {
    if (schedules.isEmpty) return '';
    final sorted = sortSchedules(schedules);
    final seen = <String>{};
    final rooms = <String>[];
    for (final s in sorted) {
      final r = s.room.trim();
      if (r.isNotEmpty && seen.add(r.toLowerCase())) {
        rooms.add(r);
      }
    }
    return rooms.join(', ');
  }

  static String? validateSchedules(
    List<ClassMeetingSchedule> schedules, {
    bool requireAtLeastOne = true,
  }) {
    if (requireAtLeastOne && schedules.isEmpty) {
      return 'Add at least one weekly meeting schedule.';
    }
    for (var i = 0; i < schedules.length; i++) {
      final current = schedules[i];
      if (!current.isValidTimeOrder) {
        return 'End time must be later than start time (${current.dayOfWeek}).';
      }
      if (current.room.trim().isEmpty) {
        return 'Select Online, TBA, or enter a room for ${current.dayOfWeek}.';
      }
      for (var j = i + 1; j < schedules.length; j++) {
        final other = schedules[j];
        if (current.overlapsWith(other)) {
          return '${current.dayOfWeek} has duplicate or overlapping meeting times.';
        }
      }
    }
    return null;
  }

  static int? rowValidationIndexError(
    List<ClassMeetingSchedule> schedules,
    int index,
  ) {
    if (index < 0 || index >= schedules.length) return null;
    final current = schedules[index];
    if (!current.isValidTimeOrder) return 1;
    for (var j = 0; j < schedules.length; j++) {
      if (j != index && current.overlapsWith(schedules[j])) {
        return 2;
      }
    }
    if (current.room.trim().isEmpty) return 3;
    return null;
  }

  static String? rowErrorText(
    List<ClassMeetingSchedule> schedules,
    int index,
  ) {
    final code = rowValidationIndexError(schedules, index);
    if (code == 1) return 'End time must be later than start time.';
    if (code == 2) {
      return 'Overlaps or duplicates another ${schedules[index].dayOfWeek} meeting.';
    }
    if (code == 3) {
      return 'Select Online, TBA, or enter a room name/number.';
    }
    return null;
  }

  static List<ClassMeetingSchedule> parseLegacy(
    String scheduleDay,
    String scheduleTime, {
    String defaultRoom = '',
  }) {
    final timeTrimmed = scheduleTime.trim();
    final dayTrimmed = scheduleDay.trim();
    final fallbackRoom =
        defaultRoom.trim() == 'Not specified' ? '' : defaultRoom.trim();
    if (timeTrimmed.isEmpty && dayTrimmed.isEmpty) return const [];

    // Check if scheduleTime encodes per-day segments like
    // "Mon 8:00 AM - 10:00 AM @ Room 301 · Wed 1:00 PM - 3:00 PM @ Lab 2"
    if (timeTrimmed.contains('·') || timeTrimmed.contains(';')) {
      final segments = timeTrimmed
          .split(RegExp(r'[·;]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final parsed = <ClassMeetingSchedule>[];
      for (final seg in segments) {
        final match = RegExp(
          r'^(Mon|Monday|Tue|Tuesday|Wed|Wednesday|Thu|Thursday|Fri|Friday|Sat|Saturday|Sun|Sunday)\s+(.+)$',
          caseSensitive: false,
        ).firstMatch(seg);
        if (match != null) {
          final day = normalizeDay(match.group(1) ?? '');
          var rest = (match.group(2) ?? '').trim();
          var segRoom = fallbackRoom;
          final atIdx = rest.indexOf('@');
          if (atIdx >= 0) {
            segRoom = rest.substring(atIdx + 1).trim();
            rest = rest.substring(0, atIdx).trim();
          }
          final range = _parseTimeRange(rest);
          if (day != null && range != null) {
            parsed.add(
              ClassMeetingSchedule(
                dayOfWeek: day,
                startMinutes: range.$1,
                endMinutes: range.$2,
                room: segRoom,
              ),
            );
          }
        }
      }
      if (parsed.isNotEmpty) return sortSchedules(parsed);
    }

    // Parse day list (e.g. "Monday, Wednesday", "Mon & Wed", "MWF", "TTh")
    final days = _parseDaysString(dayTrimmed);
    if (days.isEmpty) return const [];
    final range = _parseTimeRange(timeTrimmed) ?? (8 * 60, 9 * 60);
    return sortSchedules(
      days
          .map(
            (d) => ClassMeetingSchedule(
              dayOfWeek: d,
              startMinutes: range.$1,
              endMinutes: range.$2,
              room: fallbackRoom,
            ),
          )
          .toList(),
    );
  }

  static List<String> _parseDaysString(String raw) {
    if (raw.trim().isEmpty) return const [];
    final found = <String>[];
    final lower = raw.toLowerCase();

    for (final d in daysOfWeek) {
      final full = d.toLowerCase();
      final short3 = full.substring(0, 3);
      if (RegExp('\\b($full|$short3)\\b').hasMatch(lower)) {
        if (!found.contains(d)) found.add(d);
      }
    }
    if (found.isNotEmpty) return found;

    // Shorthand patterns like MWF, TTh
    if (lower.contains('mwf')) {
      return const ['Monday', 'Wednesday', 'Friday'];
    }
    if (lower.contains('tth')) {
      return const ['Tuesday', 'Thursday'];
    }
    return const [];
  }

  static (int, int)? _parseTimeRange(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split(RegExp(r'\s*[-–—to]+\s*', caseSensitive: false));
    if (parts.length != 2) return null;

    final endPeriodMatch =
        RegExp(r'\b(AM|PM)\b', caseSensitive: false).firstMatch(parts[1]);
    final fallbackPeriod = endPeriodMatch?.group(1);

    final start = _parseSingleTime(parts[0], fallbackPeriod: fallbackPeriod);
    final end = _parseSingleTime(parts[1]);
    if (start == null || end == null || end <= start) return null;
    return (start, end);
  }

  static int? _parseSingleTime(String raw, {String? fallbackPeriod}) {
    final match = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (hour == null || minute < 0 || minute > 59) return null;

    final period = (match.group(3) ?? fallbackPeriod)?.toUpperCase();
    if (period == 'AM') {
      if (hour == 12) hour = 0;
    } else if (period == 'PM') {
      if (hour < 12) hour += 12;
    }
    if (hour < 0 || hour > 23) return null;
    return hour * 60 + minute;
  }
}

class OfficialClassRecord {
  final String id;
  final String className;
  final String subjectCode;
  final String section;
  final String academicYear;
  final String program;
  final String room;
  final String scheduleDay;
  final String scheduleTime;
  final List<ClassMeetingSchedule> schedules;
  final String description;
  final String enrollmentCode;
  final String instructorId;
  final String instructorName;
  final bool isArchived;
  final int approvedStudentCount;
  final int pendingRequestCount;

  const OfficialClassRecord({
    required this.id,
    required this.className,
    required this.subjectCode,
    required this.section,
    this.academicYear = '',
    this.program = '',
    required this.room,
    required this.scheduleDay,
    required this.scheduleTime,
    this.schedules = const [],
    required this.description,
    required this.enrollmentCode,
    required this.instructorId,
    required this.instructorName,
    this.isArchived = false,
    this.approvedStudentCount = 0,
    this.pendingRequestCount = 0,
  });

  List<ClassMeetingSchedule> get effectiveSchedules {
    if (schedules.isNotEmpty) return schedules;
    return ClassMeetingSchedule.parseLegacy(
      scheduleDay,
      scheduleTime,
      defaultRoom: room,
    );
  }

  String get roomSummary {
    final fromMeetings = ClassMeetingSchedule.encodeRoomSummary(effectiveSchedules);
    if (fromMeetings.isNotEmpty) return fromMeetings;
    return room.trim().isEmpty ? 'Room TBA' : room.trim();
  }

  List<String> get scheduleLines {
    final list = effectiveSchedules;
    if (list.isNotEmpty) {
      return list.map((s) => s.formattedSummary).toList();
    }
    final summary = scheduleSummary;
    return summary == 'Schedule TBA' ? const [] : [summary];
  }

  String get scheduleSummary {
    if (schedules.isNotEmpty) {
      return schedules.map((s) => s.formattedCompact).join(' · ');
    }
    final d = scheduleDay.trim();
    final t = scheduleTime.trim();
    if (d.isEmpty && t.isEmpty) return 'Schedule TBA';
    if (d.isEmpty) return t;
    if (t.isEmpty) return d;
    if (t.contains('·') || t.contains(';')) return t;
    return '$d · $t';
  }

  String get scheduleMultiline {
    if (schedules.isNotEmpty) {
      return schedules.map((s) => s.formattedSummary).join('\n');
    }
    return scheduleSummary;
  }

  bool isScheduledOnWeekday(int weekday) {
    final list = effectiveSchedules;
    if (list.isNotEmpty) {
      return list.any((s) => s.weekday == weekday);
    }
    if (weekday < 1 || weekday > 7) return false;
    final todayName = ClassMeetingSchedule.daysOfWeek[weekday - 1].toLowerCase();
    final shortName = todayName.substring(0, 3);
    final sched = scheduleDay.toLowerCase();
    return sched.contains(todayName) || sched.contains(shortName);
  }

  String timeForWeekday(int weekday) {
    final list = effectiveSchedules.where((s) => s.weekday == weekday).toList();
    if (list.isNotEmpty) {
      return list.map((s) => s.formattedTimeRange).join(', ');
    }
    return scheduleTime.isEmpty ? 'TBA' : scheduleTime;
  }

  String roomForWeekday(int weekday) {
    final list = effectiveSchedules.where((s) => s.weekday == weekday).toList();
    if (list.isNotEmpty) {
      final rooms = list
          .map((s) => s.room.trim())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
      if (rooms.isNotEmpty) return rooms.join(', ');
    }
    return room.trim().isEmpty ? 'TBA' : room.trim();
  }

  factory OfficialClassRecord.fromMap(
    Map<String, dynamic> map, {
    int approvedCount = 0,
    int pendingCount = 0,
    List<ClassMeetingSchedule>? schedules,
  }) {
    final instructorProfile = map['profiles'];
    final instName = instructorProfile is Map
        ? (instructorProfile['full_name'] ?? 'Instructor').toString()
        : (map['instructor_name'] ?? 'Instructor').toString();

    final day = (map['schedule_day'] ?? '').toString();
    final time = (map['schedule_time'] ?? '').toString();
    final room = (map['room'] ?? '').toString();
    final resolvedSchedules = schedules != null && schedules.isNotEmpty
        ? ClassMeetingSchedule.sortSchedules(schedules)
        : ClassMeetingSchedule.parseLegacy(day, time, defaultRoom: room);

    return OfficialClassRecord(
      id: map['id'].toString(),
      className: (map['class_name'] ?? '').toString(),
      subjectCode: (map['subject_code'] ?? '').toString(),
      section: (map['section'] ?? 'Section A').toString(),
      academicYear: (map['academic_year'] ?? '').toString(),
      program: (map['program'] ?? '').toString(),
      room: room,
      scheduleDay: day,
      scheduleTime: time,
      schedules: resolvedSchedules,
      description: (map['description'] ?? '').toString(),
      enrollmentCode: (map['enrollment_code'] ?? '').toString(),
      instructorId: (map['instructor_id'] ?? '').toString(),
      instructorName: instName.isEmpty ? 'Instructor' : instName,
      isArchived: map['is_archived'] == true,
      approvedStudentCount: approvedCount,
      pendingRequestCount: pendingCount,
    );
  }
}

class EnrollmentRecord {
  final String id;
  final String classId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String status; // pending, approved, rejected
  final DateTime enrolledAt;

  const EnrollmentRecord({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    required this.enrolledAt,
  });

  factory EnrollmentRecord.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    final name = profile is Map
        ? (profile['full_name'] ?? '').toString()
        : '';
    final email = profile is Map
        ? (profile['email'] ?? '').toString()
        : '';

    return EnrollmentRecord(
      id: map['id'].toString(),
      classId: map['class_id'].toString(),
      studentId: map['student_id'].toString(),
      studentName: name.isEmpty ? (email.isEmpty ? 'Student' : email) : name,
      studentEmail: email,
      status: (map['status'] ?? 'approved').toString().toLowerCase(),
      enrolledAt: DateTime.tryParse((map['enrolled_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class PersonalClassRecord {
  final String id;
  final String subjectCode;
  final String className;
  final String instructorName;
  final String location;
  final String scheduleDay;
  final String scheduleTime;
  final String section;

  const PersonalClassRecord({
    required this.id,
    required this.subjectCode,
    required this.className,
    required this.instructorName,
    required this.location,
    required this.scheduleDay,
    required this.scheduleTime,
    this.section = 'Personal',
  });

  List<ClassMeetingSchedule> get schedules => ClassMeetingSchedule.parseLegacy(
        scheduleDay,
        scheduleTime,
        defaultRoom: location,
      );

  bool isScheduledOnWeekday(int weekday) {
    final list = schedules;
    if (list.isNotEmpty) {
      return list.any((s) => s.weekday == weekday);
    }
    if (weekday < 1 || weekday > 7) return false;
    final todayName = ClassMeetingSchedule.daysOfWeek[weekday - 1].toLowerCase();
    final shortName = todayName.substring(0, 3);
    final sched = scheduleDay.toLowerCase();
    return sched.contains(todayName) || sched.contains(shortName);
  }

  String timeForWeekday(int weekday) {
    final list = schedules.where((s) => s.weekday == weekday).toList();
    if (list.isNotEmpty) {
      return list.map((s) => s.formattedTimeRange).join(', ');
    }
    return scheduleTime.isEmpty ? 'TBA' : scheduleTime;
  }

  factory PersonalClassRecord.fromMap(Map<String, dynamic> map) {
    return PersonalClassRecord(
      id: map['id'].toString(),
      subjectCode: (map['subject_code'] ?? '').toString(),
      className: (map['class_name'] ?? '').toString(),
      instructorName: (map['instructor_name'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      scheduleDay: (map['schedule_day'] ?? '').toString(),
      scheduleTime: (map['schedule_time'] ?? '').toString(),
      section: (map['section'] ?? 'Personal').toString(),
    );
  }
}

class ClassService {
  const ClassService._();

  static String generateCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  // ---------------- INSTRUCTOR ----------------

  static Future<List<OfficialClassRecord>> getInstructorClasses({
    bool includeArchived = false,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    var query = supabase
        .from('classes')
        .select('*, profiles!classes_instructor_id_fkey(full_name)')
        .eq('instructor_id', uid);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final rows = await query.order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return [];

    final classIds = list.map((r) => r['id'].toString()).toList();
    final enrollmentsFuture = supabase
        .from('enrollments')
        .select('class_id, status')
        .inFilter('class_id', classIds);
    final schedulesFuture = _loadSchedulesForClasses(classIds);

    final enrollments = await enrollmentsFuture;
    final schedulesByClass = await schedulesFuture;

    final approvedCounts = <String, int>{};
    final pendingCounts = <String, int>{};
    for (final e in enrollments) {
      final cid = e['class_id'].toString();
      final status = (e['status'] ?? 'approved').toString().toLowerCase();
      if (status == 'approved') {
        approvedCounts[cid] = (approvedCounts[cid] ?? 0) + 1;
      } else if (status == 'pending') {
        pendingCounts[cid] = (pendingCounts[cid] ?? 0) + 1;
      }
    }

    return list.map((r) {
      final cid = r['id'].toString();
      return OfficialClassRecord.fromMap(
        r,
        approvedCount: approvedCounts[cid] ?? 0,
        pendingCount: pendingCounts[cid] ?? 0,
        schedules: schedulesByClass[cid],
      );
    }).toList();
  }

  static Future<Map<String, List<ClassMeetingSchedule>>> _loadSchedulesForClasses(
    List<String> classIds,
  ) async {
    if (classIds.isEmpty) return const {};
    try {
      final rows = await supabase
          .from('class_schedules')
          .select()
          .inFilter('class_id', classIds)
          .order('start_time', ascending: true);

      final grouped = <String, List<ClassMeetingSchedule>>{};
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final schedule = ClassMeetingSchedule.fromMap(row);
        final cid = schedule.classId;
        if (cid == null || cid.isEmpty) continue;
        grouped.putIfAbsent(cid, () => []).add(schedule);
      }
      for (final entry in grouped.entries) {
        grouped[entry.key] = ClassMeetingSchedule.sortSchedules(entry.value);
      }
      return grouped;
    } catch (_) {
      // Graceful fallback if class_schedules migration hasn't been applied yet.
      return const {};
    }
  }

  static Future<List<ClassMeetingSchedule>> _replaceClassSchedules(
    String classId,
    List<ClassMeetingSchedule> schedules,
  ) async {
    final sorted = ClassMeetingSchedule.sortSchedules(schedules);
    try {
      await supabase
          .from('class_schedules')
          .delete()
          .eq('class_id', classId);
      if (sorted.isEmpty) return const [];

      final inserted = await supabase
          .from('class_schedules')
          .insert(sorted.map((s) => s.toInsertMap(classId)).toList())
          .select();
      return ClassMeetingSchedule.sortSchedules(
        List<Map<String, dynamic>>.from(inserted)
            .map(ClassMeetingSchedule.fromMap)
            .toList(),
      );
    } catch (_) {
      // If class_schedules table doesn't exist yet, legacy columns on classes still persist.
      return sorted;
    }
  }

  static Future<OfficialClassRecord> createOfficialClass({
    required String className,
    required String subjectCode,
    required String section,
    String academicYear = '',
    String program = '',
    String room = '',
    String scheduleDay = '',
    String scheduleTime = '',
    List<ClassMeetingSchedule> schedules = const [],
    String description = '',
    String? enrollmentCode,
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final code = (enrollmentCode == null || enrollmentCode.trim().isEmpty)
        ? generateCode()
        : enrollmentCode.trim().toUpperCase();

    final effectiveDay = schedules.isNotEmpty
        ? ClassMeetingSchedule.encodeScheduleDay(schedules)
        : scheduleDay.trim();
    final effectiveTime = schedules.isNotEmpty
        ? ClassMeetingSchedule.encodeScheduleTime(schedules)
        : scheduleTime.trim();
    final effectiveRoom = schedules.isNotEmpty
        ? ClassMeetingSchedule.encodeRoomSummary(schedules)
        : room.trim();

    final row = await supabase
        .from('classes')
        .insert({
          'instructor_id': uid,
          'class_name': className.trim(),
          'subject_code': subjectCode.trim().toUpperCase(),
          'section': section.trim().isEmpty ? 'Section A' : section.trim(),
          'academic_year': academicYear.trim(),
          'program': program.trim(),
          'room': effectiveRoom,
          'schedule_day': effectiveDay,
          'schedule_time': effectiveTime,
          'description': description.trim(),
          'enrollment_code': code,
        })
        .select('*, profiles!classes_instructor_id_fkey(full_name)')
        .single();

    final classId = row['id'].toString();
    final savedSchedules = schedules.isNotEmpty
        ? await _replaceClassSchedules(classId, schedules)
        : const <ClassMeetingSchedule>[];

    return OfficialClassRecord.fromMap(row, schedules: savedSchedules);
  }

  static Future<OfficialClassRecord> updateOfficialClass({
    required String classId,
    required String className,
    required String subjectCode,
    required String section,
    String academicYear = '',
    String program = '',
    String room = '',
    String scheduleDay = '',
    String scheduleTime = '',
    List<ClassMeetingSchedule>? schedules,
    String description = '',
    String? enrollmentCode,
  }) async {
    final effectiveDay = schedules != null
        ? ClassMeetingSchedule.encodeScheduleDay(schedules)
        : scheduleDay.trim();
    final effectiveTime = schedules != null
        ? ClassMeetingSchedule.encodeScheduleTime(schedules)
        : scheduleTime.trim();
    final effectiveRoom = schedules != null
        ? ClassMeetingSchedule.encodeRoomSummary(schedules)
        : room.trim();

    final updates = <String, dynamic>{
      'class_name': className.trim(),
      'subject_code': subjectCode.trim().toUpperCase(),
      'section': section.trim().isEmpty ? 'Section A' : section.trim(),
      'academic_year': academicYear.trim(),
      'program': program.trim(),
      'room': effectiveRoom,
      'schedule_day': effectiveDay,
      'schedule_time': effectiveTime,
      'description': description.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (enrollmentCode != null && enrollmentCode.trim().isNotEmpty) {
      updates['enrollment_code'] = enrollmentCode.trim().toUpperCase();
    }

    final row = await supabase
        .from('classes')
        .update(updates)
        .eq('id', classId)
        .select('*, profiles!classes_instructor_id_fkey(full_name)')
        .single();

    final savedSchedules = schedules != null
        ? await _replaceClassSchedules(classId, schedules)
        : null;

    return OfficialClassRecord.fromMap(row, schedules: savedSchedules);
  }

  static Future<void> setClassArchived(String classId, bool archived) async {
    await supabase
        .from('classes')
        .update({
          'is_archived': archived,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', classId);
  }

  static Future<List<EnrollmentRecord>> getClassEnrollments(
    String classId,
  ) async {
    final rows = await supabase
        .from('enrollments')
        .select('*, profiles!enrollments_student_id_fkey(full_name, email)')
        .eq('class_id', classId)
        .order('enrolled_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(EnrollmentRecord.fromMap)
        .toList();
  }

  static Future<void> updateEnrollmentStatus({
    required String enrollmentId,
    required String status,
  }) async {
    await supabase
        .from('enrollments')
        .update({
          'status': status.toLowerCase(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', enrollmentId);
  }

  static Future<void> enrollStudentByEmail({
    required String classId,
    required String studentEmail,
  }) async {
    await supabase.rpc(
      'instructor_enroll_student_by_email',
      params: {
        'p_class_id': classId,
        'p_student_email': studentEmail.trim(),
      },
    );
  }

  // ---------------- STUDENT ----------------

  static Future<Map<String, dynamic>> joinClassByCode(String code) async {
    final res = await supabase.rpc(
      'join_class_by_code',
      params: {'p_code': code.trim().toUpperCase()},
    );
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'status': 'pending'};
  }

  static Future<List<OfficialClassRecord>> getStudentApprovedClasses() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('enrollments')
        .select(
          'status, classes!inner(*, profiles!classes_instructor_id_fkey(full_name))',
        )
        .eq('student_id', uid)
        .eq('status', 'approved');

    final classMaps = <Map<String, dynamic>>[];
    for (final row in rows) {
      final cls = row['classes'];
      if (cls is Map<String, dynamic> && cls['is_archived'] != true) {
        classMaps.add(cls);
      }
    }
    if (classMaps.isEmpty) return [];

    final classIds = classMaps.map((c) => c['id'].toString()).toList();
    final schedulesByClass = await _loadSchedulesForClasses(classIds);

    return classMaps
        .map(
          (cls) => OfficialClassRecord.fromMap(
            cls,
            schedules: schedulesByClass[cls['id'].toString()],
          ),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getStudentPendingEnrollments() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('enrollments')
        .select('id, status, enrolled_at, classes(class_name, subject_code, section)')
        .eq('student_id', uid)
        .eq('status', 'pending')
        .order('enrolled_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<PersonalClassRecord>> getStudentPersonalClasses() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final rows = await supabase
        .from('student_personal_classes')
        .select()
        .eq('student_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .map(PersonalClassRecord.fromMap)
        .toList();
  }

  static Future<PersonalClassRecord> createPersonalClass({
    required String subjectCode,
    required String className,
    String instructorName = '',
    String location = '',
    String scheduleDay = '',
    String scheduleTime = '',
  }) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in.');

    final row = await supabase
        .from('student_personal_classes')
        .insert({
          'student_id': uid,
          'subject_code': subjectCode.trim().toUpperCase(),
          'class_name': className.trim(),
          'instructor_name': instructorName.trim(),
          'location': location.trim(),
          'schedule_day': scheduleDay.trim(),
          'schedule_time': scheduleTime.trim(),
        })
        .select()
        .single();

    return PersonalClassRecord.fromMap(row);
  }

  static Future<void> deletePersonalClass(String id) async {
    await supabase.from('student_personal_classes').delete().eq('id', id);
  }
}
