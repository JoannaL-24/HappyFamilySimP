import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ProfileRepository {
  final ProfileService _profileService;
  ProfileRepository(this._profileService);

  Future<String> updateUserProfile(
    String userId,
    String? name,
    String? newPassword,
    File? pickedImage,
  ) async {
    try {
      final updateMessage = await _profileService.updateProfileService(
        userId: userId,
        name: name,
        newPassword: newPassword,
        pickedImage: pickedImage,
      );

      return updateMessage;
    } on PostgrestException catch (e) {
      logger.e('Postgrest error during profile update', error: e);

      throw Exception('Failed to update profile. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during profile update', error: e);

      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final data = await _profileService.fetchProfileService(userId: userId);
      return data;
    } on PostgrestException catch (e) {
      logger.e('Postgrest error during profile fetch', error: e);

      throw Exception('Failed to fetch profile data. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during profile fetch', error: e);

      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }
}
