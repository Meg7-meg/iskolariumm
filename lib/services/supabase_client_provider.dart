import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared Supabase client accessor and error formatting utilities.
SupabaseClient get supabase => Supabase.instance.client;

String formatSupabaseError(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  if (error is PostgrestException) {
    return error.message;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

bool isMissingSupabaseTable(Object error, String tableName) =>
    error is PostgrestException &&
    error.code == 'PGRST205' &&
    error.message.split(RegExp(r'[^A-Za-z0-9_]+')).contains(tableName);

String formatAttendanceSessionsError(Object error) {
  if (isMissingSupabaseTable(error, 'attendance_sessions')) {
    return 'Attendance storage is not available in Supabase. Apply '
        '202611250008_complete_class_management.sql, then '
        '202611261000_attendance_scheduling_and_corrections.sql, and reload '
        'the schema cache. Do not create a duplicate table.';
  }
  return formatSupabaseError(error);
}
