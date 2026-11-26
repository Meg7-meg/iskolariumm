import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/screens/instructor/instructor_notifications_screen.dart';
import 'package:iskolarium/services/class_service.dart';
import 'package:iskolarium/services/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('missing attendance table error explains the database setup fix', () {
    final error = PostgrestException(
      message: "Could not find the table 'public.attendance_sessions' in the schema cache",
      code: 'PGRST205',
    );

    expect(isMissingSupabaseTable(error, 'attendance_sessions'), isTrue);
    expect(
      formatAttendanceSessionsError(error),
      contains('202611250008_complete_class_management.sql'),
    );
    expect(isMissingSupabaseTable(error, 'attendance'), isFalse);
  });

  test('class reminders include only upcoming meetings in the next week', () {
    final record = OfficialClassRecord(
      id: 'class-1',
      className: 'Academic Writing',
      subjectCode: 'ENG101',
      section: 'A',
      room: 'Room 1',
      scheduleDay: 'Thursday, Monday',
      scheduleTime: 'See schedule',
      schedules: const [
        ClassMeetingSchedule(
          id: 'thursday-past',
          dayOfWeek: 'Thursday',
          startMinutes: 9 * 60,
          endMinutes: 10 * 60,
        ),
        ClassMeetingSchedule(
          id: 'thursday-upcoming',
          dayOfWeek: 'Thursday',
          startMinutes: 14 * 60,
          endMinutes: 15 * 60,
        ),
        ClassMeetingSchedule(
          id: 'monday',
          dayOfWeek: 'Monday',
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      ],
      description: '',
      enrollmentCode: 'JOIN01',
      instructorId: 'instructor-1',
      instructorName: 'Instructor',
    );

    final reminders = InstructorNotificationService.buildUpcomingClassReminders(
      [record],
      manilaWallTime: DateTime.utc(2026, 11, 26, 10),
    );

    expect(reminders, hasLength(2));
    expect(reminders.map((item) => item.timestamp.toUtc().toIso8601String()), [
      '2026-11-26T06:00:00.000Z',
      '2026-11-30T00:00:00.000Z',
    ]);
  });
}
