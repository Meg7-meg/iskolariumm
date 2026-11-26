import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme_service.dart';
import 'supabase_client_provider.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String preferredTheme;
  final String? avatarPath;
  final Map<String, dynamic> notificationPreferences;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.preferredTheme = 'system',
    this.avatarPath,
    this.notificationPreferences = const {
      'tasks': true,
      'events': true,
      'classes': true,
    },
  });

  bool get isInstructor => role.toLowerCase() == 'instructor';
  bool get isStudent => role.toLowerCase() == 'student';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final prefsRaw = map['notification_preferences'];
    final prefs = prefsRaw is Map<String, dynamic>
        ? prefsRaw
        : prefsRaw is Map
        ? Map<String, dynamic>.from(prefsRaw)
        : <String, dynamic>{'tasks': true, 'events': true, 'classes': true};

    return UserProfile(
      id: map['id'].toString(),
      fullName: (map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'student').toString().toLowerCase(),
      preferredTheme: (map['preferred_theme'] ?? 'system').toString(),
      avatarPath: map['avatar_path']?.toString(),
      notificationPreferences: prefs,
    );
  }
}

class AuthService {
  const AuthService._();

  static User? get currentUser => supabase.auth.currentUser;
  static Session? get currentSession => supabase.auth.currentSession;
  static Stream<AuthState> get onAuthStateChange =>
      supabase.auth.onAuthStateChange;

  static Future<UserProfile> signInWithRole({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Unable to retrieve your account.');
    }

    final profileRow = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileRow == null) {
      await supabase.auth.signOut();
      throw Exception('Your user profile was not found.');
    }

    final profile = UserProfile.fromMap(profileRow);
    if (profile.role != expectedRole.toLowerCase()) {
      await supabase.auth.signOut();
      throw Exception(
        'This account is not registered as $expectedRole. '
        'Please select the correct account type.',
      );
    }

    AppThemeService.applyPreference(profile.preferredTheme);
    return profile;
  }

  static Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedRole = role.toLowerCase();
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();

    final response = await supabase.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: {'full_name': trimmedName, 'role': normalizedRole},
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Unable to create your account. Please try again.');
    }

    final hasSession = response.session != null;
    if (hasSession) {
      final existingProfile = await supabase
          .from('profiles')
          .select('id, role')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        try {
          await supabase.from('profiles').insert({
            'id': user.id,
            'full_name': trimmedName,
            'email': trimmedEmail,
            'role': normalizedRole,
          });
        } on PostgrestException {
          await supabase.from('profiles').insert({
            'id': user.id,
            'role': normalizedRole,
          });
        }
      } else if (existingProfile['role'] == null) {
        await supabase
            .from('profiles')
            .update({'role': normalizedRole})
            .eq('id', user.id);
      }

      await supabase.auth.signOut();
    }

    return hasSession;
  }

  static Future<void> sendPasswordReset(String email) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  static Future<void> updatePassword(String password) async {
    await supabase.auth.updateUser(UserAttributes(password: password));
  }

  static Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    final profile = UserProfile.fromMap(row);
    AppThemeService.applyPreference(profile.preferredTheme);
    return profile;
  }

  static Future<UserProfile> updateProfile({
    required String fullName,
    String? preferredTheme,
    Map<String, dynamic>? notificationPreferences,
    String? avatarPath,
    bool clearAvatar = false,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in.');
    if (clearAvatar && avatarPath != null) {
      throw ArgumentError('Cannot set and clear the avatar path together.');
    }

    final updates = <String, dynamic>{
      'full_name': fullName.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (preferredTheme != null) {
      updates['preferred_theme'] = preferredTheme;
    }
    if (notificationPreferences != null) {
      updates['notification_preferences'] = notificationPreferences;
    }
    if (avatarPath != null) {
      updates['avatar_path'] = avatarPath;
    } else if (clearAvatar) {
      updates['avatar_path'] = null;
    }

    final row = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();

    final profile = UserProfile.fromMap(row);
    if (preferredTheme != null) {
      AppThemeService.applyPreference(profile.preferredTheme);
    }
    return profile;
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
    AppThemeService.applyPreference('system');
  }
}
