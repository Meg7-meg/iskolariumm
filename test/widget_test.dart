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
