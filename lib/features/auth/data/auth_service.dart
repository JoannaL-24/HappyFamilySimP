import 'package:happy_family_sim/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;
  AuthService(this._supabase);

  Future<void> parentSignUP({
    required String email,
    required String password,
    required String parentName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('User creation failed');
    }

    await _supabase.from('profiles').insert({
      'name': parentName,
      'role': Constants.parentRole,
      'avatar_path': Constants.defaultAvatarPath,
    });
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Future<AuthResponse> childSignUP({
  //   required String email,
  //   required String sixDigitCode,
  //   required String childName,
  // }) async {
  //   final internalEmail = email.replaceFirst('@', '+$sixDigitCode@hfs.local');
  //
  //   try {
  //     final response = await _supabase.auth.signUp(
  //       email: internalEmail,
  //       password: sixDigitCode,
  //     );
  //
  //     return AuthResponse(session: response.session, user: response.user);
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
}
