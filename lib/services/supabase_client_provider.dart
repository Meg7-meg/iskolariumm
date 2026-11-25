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
