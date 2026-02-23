import 'package:happy_family_sim/features/auth/data/auth_service.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var logger = Logger();

class AuthRepository {
  final AuthService _authService;
  AuthRepository(this._authService);

  User? get currentUser => _authService.currentUser;

  Stream<AuthState> get authChanges => _authService.authChangesService;

  Future<String?> getPersistedRole() async {
    try {
      return await _authService.getPersistedRoleService();
    } catch (e) {
      logger.e('Failed to fetch persisted role', error: e);
      return null;
    }
  }

  Future<void> parentSignUp(String email, String password, String name) async {
    try {
      await _authService.parentSignUpService(
        email: email,
        password: password,
        parentName: name,
      );

      await _authService.signOutService();
    } on AuthException catch (e) {
      logger.e('Auth error during account creation', error: e);

      // network error
      if (e.message.toLowerCase().contains('socket')) {
        throw Exception('Please check your internet connection and try again.');
      }

      // user already exists
      if (e.message.toLowerCase().contains('user already registered')) {
        throw Exception(
          'An account with this email already exists. Please use a different email.',
        );
      }

      throw Exception('An unexpected error occurred. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during account creation', error: e);
      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }

  Future<String> signIn(String email, String password) async {
    try {
      final role = await _authService.signInService(
        email: email,
        password: password,
      );

      return role;
    } on AuthException catch (e) {
      logger.e('Auth error during login', error: e);

      // network error
      if (e.message.toLowerCase().contains('socket')) {
        throw Exception('Please check your internet connection and try again.');
      }

      // incorrect email or password
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception('Incorrect email or password.');
      }

      throw Exception('An unexpected error occurred. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during login', error: e);
      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOutService();
    } catch (e) {
      logger.e('Error during sign out', error: e);
    }
  }
}
