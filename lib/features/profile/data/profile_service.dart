import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;
  ProfileService(this._supabase);

  Future<String> updateProfileService({
    required String userId,
    String? name,
    String? newPassword,
    File? pickedImage,
  }) async {
    List<String> updateFields = [];
    updateFields.add('The following fields were updated: ');
    final avatarPath = 'users/$userId.png';

    // Upload the file to the avatars bucket
    if (pickedImage != null) {
      final response = await _supabase.storage
          .from('avatars')
          .upload(
            avatarPath,
            pickedImage,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (response.isEmpty) {
        throw Exception('File upload failed');
      }
    }

    // name and profiles table
    if (name != null && pickedImage != null) {
      await _supabase
          .from('profiles')
          .update({'name': name, 'avatar_path': avatarPath})
          .eq('id', userId);

      updateFields.add('• Name');
      updateFields.add('• Avatar');
    } else if (name != null) {
      await _supabase.from('profiles').update({'name': name}).eq('id', userId);

      updateFields.add('• Name');
    } else if (pickedImage != null) {
      await _supabase
          .from('profiles')
          .update({'avatar_path': avatarPath})
          .eq('id', userId);

      updateFields.add('• Avatar');
    }

    // password and auth
    if (newPassword != null) {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      updateFields.add('• Password');
    }

    if (updateFields.length == 1) {
      return 'No fields were updated.';
    } else {
      return updateFields.join('\n');
    }
  }

  Future<Map<String, dynamic>> fetchProfileService({
    required String userId,
  }) async {
    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return profileData;
  }
}
