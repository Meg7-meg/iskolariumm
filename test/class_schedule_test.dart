import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/services/class_service.dart';

void main() {
  group('ClassMeetingSchedule', () {
    test('validates end time must be later than start time', () {
      const invalid = [
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 10 * 60,
          endMinutes: 9 * 60,
        ),
      ];
      expect(
        ClassMeetingSchedule.validateSchedules(invalid),
        contains('End time must be later than start time'),
      );

      const equal = [
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 10 * 60,
          endMinutes: 10 * 60,
        ),
      ];
      expect(
        ClassMeetingSchedule.validateSchedules(equal),
        contains('End time must be later than start time'),
      );
    });

    test('finds the next occurrence after a reference time', () {
      const mondayMorning = ClassMeetingSchedule(
        dayOfWeek: 'Monday',
        startMinutes: 9 * 60,
        endMinutes: 10 * 60,
      );

      expect(
        mondayMorning.nextOccurrenceAfter(DateTime(2026, 6, 1, 8)),
        DateTime(2026, 6, 1, 9),
      );
      expect(
        mondayMorning.nextOccurrenceAfter(DateTime(2026, 6, 1, 9)),
        DateTime(2026, 6, 8, 9),
      );
    });

    test('detects duplicate and overlapping meetings on same day', () {
      const overlapping = [
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 8 * 60,
          endMinutes: 10 * 60,
          room: 'Room 301',
        ),
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 9 * 60,
          endMinutes: 11 * 60,
          room: 'Room 301',
        ),
      ];
      expect(
        ClassMeetingSchedule.validateSchedules(overlapping),
        contains('duplicate or overlapping'),
      );

      // Back-to-back on the same day is allowed
      const backToBack = [
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 8 * 60,
          endMinutes: 10 * 60,
          room: 'Room 301',
        ),
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 10 * 60,
          endMinutes: 12 * 60,
          room: 'Online',
        ),
      ];
      expect(ClassMeetingSchedule.validateSchedules(backToBack), isNull);
    });

    test('requires valid location (Online, TBA, or Room Number)', () {
      const missingRoom = [
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 8 * 60,
          endMinutes: 10 * 60,
          room: '',
        ),
      ];
      expect(
        ClassMeetingSchedule.validateSchedules(missingRoom),
        contains('Online, TBA'),
      );

      const online = ClassMeetingSchedule(
        dayOfWeek: 'Wednesday',
        startMinutes: 13 * 60,
        endMinutes: 15 * 60,
        room: 'Online',
      );
      const tba = ClassMeetingSchedule(
        dayOfWeek: 'Friday',
        startMinutes: 9 * 60,
        endMinutes: 11 * 60,
        room: 'TBA',
      );
      const numbered = ClassMeetingSchedule(
        dayOfWeek: 'Monday',
        startMinutes: 8 * 60,
        endMinutes: 10 * 60,
        room: 'Room 301',
      );
      expect(online.locationType, MeetingLocationType.online);
      expect(tba.locationType, MeetingLocationType.tba);
      expect(numbered.locationType, MeetingLocationType.roomNumber);
      expect(
        ClassMeetingSchedule.validateSchedules([numbered, online, tba]),
        isNull,
      );
    });

    test('requires at least one meeting when requireAtLeastOne is true', () {
      expect(
        ClassMeetingSchedule.validateSchedules(
          const [],
          requireAtLeastOne: true,
        ),
        isNotNull,
      );
      expect(
        ClassMeetingSchedule.validateSchedules(
          const [],
          requireAtLeastOne: false,
        ),
        isNull,
      );
    });

    test('encodes and parses multi-meeting schedules with per-meeting rooms round-trip', () {
      const schedules = [
        ClassMeetingSchedule(
          dayOfWeek: 'Wednesday',
          startMinutes: 13 * 60,
          endMinutes: 15 * 60,
          room: 'Computer Lab 2',
        ),
        ClassMeetingSchedule(
          dayOfWeek: 'Monday',
          startMinutes: 8 * 60,
          endMinutes: 10 * 60,
          room: 'Room 301',
        ),
      ];
      final encodedDay = ClassMeetingSchedule.encodeScheduleDay(schedules);
      final encodedTime = ClassMeetingSchedule.encodeScheduleTime(schedules);
      final encodedRooms = ClassMeetingSchedule.encodeRoomSummary(schedules);

      expect(encodedDay, 'Monday, Wednesday');
      expect(
        encodedTime,
        'Mon 8:00 AM - 10:00 AM @ Room 301 · Wed 1:00 PM - 3:00 PM @ Computer Lab 2',
      );
      expect(encodedRooms, 'Room 301, Computer Lab 2');

      final parsed = ClassMeetingSchedule.parseLegacy(encodedDay, encodedTime);
      expect(parsed.length, 2);
      expect(parsed[0].dayOfWeek, 'Monday');
      expect(parsed[0].startMinutes, 8 * 60);
      expect(parsed[0].endMinutes, 10 * 60);
      expect(parsed[0].room, 'Room 301');
      expect(parsed[1].dayOfWeek, 'Wednesday');
      expect(parsed[1].startMinutes, 13 * 60);
      expect(parsed[1].endMinutes, 15 * 60);
      expect(parsed[1].room, 'Computer Lab 2');
    });

    test('parses legacy day strings and migrates defaultRoom safely', () {
      final monWed = ClassMeetingSchedule.parseLegacy(
        'Mon & Wed',
        '9:00-10:30 AM',
        defaultRoom: 'Room 204',
      );
      expect(monWed.length, 2);
      expect(monWed[0].dayOfWeek, 'Monday');
      expect(monWed[0].room, 'Room 204');
      expect(monWed[1].dayOfWeek, 'Wednesday');
      expect(monWed[1].room, 'Room 204');
      expect(monWed[0].startMinutes, 9 * 60);
      expect(monWed[0].endMinutes, 10 * 60 + 30);

      final mwf = ClassMeetingSchedule.parseLegacy('MWF', '1:00 PM - 2:00 PM');
      expect(mwf.map((e) => e.dayOfWeek).toList(), [
        'Monday',
        'Wednesday',
        'Friday',
      ]);
    });
  });
}
