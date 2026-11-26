import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/services/academic_service.dart';
import 'package:iskolarium/services/auth_service.dart';
import 'package:iskolarium/services/class_service.dart';
import 'package:iskolarium/services/organizer_service.dart';

void main() {
  test('UserProfile parses role and defaults safely', () {
    final profile = UserProfile.fromMap({
      'id': 'u-1',
      'full_name': 'Jane Doe',
      'email': 'jane@example.com',
      'role': 'Instructor',
    });
    expect(profile.isInstructor, isTrue);
    expect(profile.isStudent, isFalse);
    expect(profile.fullName, 'Jane Doe');
  });

  test('ClassService.generateCode produces 6-char uppercase code', () {
    final code = ClassService.generateCode();
    expect(code.length, 6);
    expect(code, equals(code.toUpperCase()));
  });

  test('ScoreRecord computes percentage accurately', () {
    final score = ScoreRecord(
      id: 's-1',
      classId: 'c-1',
      className: 'Database Systems',
      subjectCode: 'CS 304',
      instructorName: 'Dr. Reyes',
      studentId: 'u-2',
      studentName: 'Juan',
      assessmentName: 'Quiz 1',
      category: 'quiz',
      score: 18,
      maxScore: 20,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(score.percentage, 90.0);
  });

  test(
    'academic record dates use Supabase values and remain absent if missing',
    () {
      final attendance = AttendanceRecord.fromMap({
        'id': 'a-1',
        'class_id': 'c-1',
        'student_id': 'u-2',
        'attendance_date': '2026-11-26',
        'status': 'present',
      });
      final score = ScoreRecord.fromMap({
        'id': 's-1',
        'class_id': 'c-1',
        'student_id': 'u-2',
        'created_at': '2026-11-25T08:00:00Z',
        'updated_at': '2026-11-26T08:00:00Z',
      });
      final undatedAttendance = AttendanceRecord.fromMap({
        'id': 'a-2',
        'class_id': 'c-1',
        'student_id': 'u-2',
      });
      final undatedScore = ScoreRecord.fromMap({
        'id': 's-2',
        'class_id': 'c-1',
        'student_id': 'u-2',
      });

      expect(attendance.attendanceDate, DateTime(2026, 11, 26));
      expect(score.updatedAt, DateTime.utc(2026, 11, 26, 8));
      expect(undatedAttendance.attendanceDate, isNull);
      expect(undatedScore.createdAt, isNull);
    },
  );

  test('attendance sessions are matched to the selected meeting key', () {
    final meetingOne = AttendanceSessionRecord(
      id: 'session-one',
      classId: 'class-1',
      scheduleId: 'schedule-one',
      meetingKey: 'schedule-one',
      sessionDate: DateTime.utc(2026, 11, 26),
    );
    final meetingTwo = AttendanceSessionRecord(
      id: 'session-two',
      classId: 'class-1',
      scheduleId: 'schedule-two',
      meetingKey: 'schedule-two',
      sessionDate: DateTime.utc(2026, 11, 26),
    );

    final selected = AcademicService.findAttendanceSessionForMeeting(
      sessions: [meetingOne, meetingTwo],
      meetingKey: 'schedule-two',
      scheduleId: 'schedule-two',
      hasSingleScheduledMeeting: false,
    );
    final unrelated = AcademicService.findAttendanceSessionForMeeting(
      sessions: [meetingOne, meetingTwo],
      meetingKey: 'schedule-three',
      scheduleId: 'schedule-three',
      hasSingleScheduledMeeting: false,
    );

    expect(selected?.id, 'session-two');
    expect(unrelated, isNull);
  });

  test('legacy session is only matched when the date has one meeting', () {
    final legacySession = AttendanceSessionRecord(
      id: 'legacy-session',
      classId: 'class-1',
      sessionDate: DateTime.utc(2026, 11, 26),
    );

    expect(
      AcademicService.findAttendanceSessionForMeeting(
        sessions: [legacySession],
        meetingKey: 'schedule-one',
        scheduleId: 'schedule-one',
        hasSingleScheduledMeeting: true,
      )?.id,
      'legacy-session',
    );
    expect(
      AcademicService.findAttendanceSessionForMeeting(
        sessions: [legacySession],
        meetingKey: 'schedule-one',
        scheduleId: 'schedule-one',
        hasSingleScheduledMeeting: false,
      ),
      isNull,
    );
  });

  test('StudentNotificationRecord tracks unread state', () {
    final unread = StudentNotificationRecord(
      id: 'n-1',
      title: 'Test',
      message: 'Body',
      category: 'Classes',
      createdAt: DateTime.now(),
    );
    expect(unread.isUnread, isTrue);
  });
}
