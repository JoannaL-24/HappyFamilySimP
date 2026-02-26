import 'package:happy_family_sim/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;
  AuthService(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authChangesService => _supabase.auth.onAuthStateChange;

  Future<String?> getPersistedRoleService() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'] as String;
  }

  Future<void> parentSignUpService({
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

  Future<String> signInService({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Log in failed');
    }

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'] as String;
  }

  Future<void> signOutService() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendPasswordResetService(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      //TODO: Page hosted in a forked repo. Replace with actual page link (based in the original repo) 
      redirectTo: 'https://chaoyi-zoey-lu.github.io/happy-family-sim/',
    );
  }

  // 2. Actually update the password once they return
  Future<void> updatePasswordService(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
