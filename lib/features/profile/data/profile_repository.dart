import 'dart:io';

import 'package:happy_family_sim/features/profile/data/profile_model.dart';
import 'package:happy_family_sim/features/profile/data/profile_service.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var logger = Logger();

class ProfileRepository {
  final ProfileService _profileService;
  ProfileRepository(this._profileService);

  Future<String> updateUserProfile(
    String userId,
    String? name,
    String? newPassword,
    File? selectedImage,
  ) async {
    try {
      final updateMessage = await _profileService.updateProfileService(
        userId: userId,
        name: name,
        newPassword: newPassword,
        selectedImage: selectedImage,
      );

      return updateMessage;
    } on AuthApiException catch (e) {
      logger.e('Auth error during profile update', error: e);

      // password issue
      if (e.message.toLowerCase().contains('different from the old password')) {
        throw Exception(
          'New password should be different from the old password.',
        );
      }

      throw Exception('Failed to update profile. Please try again later.');
    } on PostgrestException catch (e) {
      logger.e('Postgrest error during profile update', error: e);

      throw Exception('Failed to update profile. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during profile update', error: e);

      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }

  Future<ProfileModel> fetchUserProfile(String userId) async {
    try {
      return await _profileService.fetchProfileService(userId: userId);
    } on PostgrestException catch (e) {
      logger.e('Postgrest error during profile fetch', error: e);

      throw Exception('Failed to fetch profile data. Please try again later.');
    } catch (e) {
      logger.e('Unexpected error during profile fetch', error: e);

      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }
}
