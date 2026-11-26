import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarium/services/auth_service.dart';

void main() {
  test('UserProfile reads its persisted avatar storage path', () {
    final profile = UserProfile.fromMap({
      'id': 'instructor-1',
      'full_name': 'Alex Teacher',
      'email': 'alex@example.com',
      'role': 'instructor',
      'avatar_path': 'instructor-1/1732600000000000.jpg',
    });

    expect(profile.avatarPath, 'instructor-1/1732600000000000.jpg');
  });
}
