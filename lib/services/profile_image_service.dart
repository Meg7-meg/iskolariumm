import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

class ProfileImageService {
  static const String bucket = 'instructor-profile-photos';
  static const int maxPhotoBytes = 5 * 1024 * 1024;

  static Future<String> uploadAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in.');
    if (bytes.isEmpty || bytes.lengthInBytes > maxPhotoBytes) {
      throw Exception('Choose an image that is no larger than 5 MB.');
    }
    if (contentType != 'image/jpeg' && contentType != 'image/png') {
      throw Exception('Choose a JPG or PNG image.');
    }

    final extension = contentType == 'image/png' ? 'png' : 'jpg';
    final path =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: contentType,
            upsert: false,
          ),
        );
    return path;
  }

  static Future<String> createSignedUrl(String path) {
    _requireOwnedPath(path);
    return supabase.storage.from(bucket).createSignedUrl(path, 3600);
  }

  static Future<void> deleteAvatar(String path) async {
    _requireOwnedPath(path);
    await supabase.storage.from(bucket).remove([path]);
  }

  static void _requireOwnedPath(String path) {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in.');
    if (path.split('/').first != user.id) {
      throw Exception('You can only manage your own profile photo.');
    }
  }
}
