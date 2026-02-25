import 'package:supabase_flutter/supabase_flutter.dart';

class ManageService {
  final SupabaseClient _supabase;
  ManageService(this._supabase);

  Future<AuthResponse> childSignUP({
    required String email,
    required String sixDigitCode,
    required String childName,
  }) async {
    final internalEmail = email.replaceFirst('@', '+$sixDigitCode@hfs.local');

    try {
      final response = await _supabase.auth.signUp(
        email: internalEmail,
        password: sixDigitCode,
      );

      return AuthResponse(session: response.session, user: response.user);
    } catch (e) {
      rethrow;
    }
  }
}
