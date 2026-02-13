import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class AuthRepository {
  final AuthService _authService;
  AuthRepository(this._authService);

  Future<void> createParentAccount(
    String email,
    String password,
    String name,
  ) async {
    try {
      await _authService.parentSignUP(
        email: email,
        password: password,
        parentName: name,
      );

      await _authService.signOut();
    } on AuthException catch (e) {
      logger.e('Auth error during account creation', error: e);

      // network error
      if (e.message.toLowerCase().contains('socket')) {
        throw Exception('Please check your internet connection and try again.');
      }

      // user already exists
      if (e.message.toLowerCase().contains('user already registered')) {
        throw Exception('An account with this email already exists. Please use a different email.');
      }

      throw Exception('An unexpected error occurred. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during account creation', error: e);

      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }
}
