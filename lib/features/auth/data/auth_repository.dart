import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

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
      // This is a "400/401" style error from Supabase (e.g., User already exists)
      throw Exception(e.message);
    } on SocketException catch (_) {
      // This is a "No Internet" error (Network layer)
      throw Exception('No internet connection. Please check your connection and try again.');
    } catch (e) {
      // This is your "500" style error (Internal Server/Logic error)
      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }
}
