import 'dart:io';

import 'package:happy_family_sim/core/constants.dart';
import 'package:happy_family_sim/features/profile/data/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;
  ProfileService(this._supabase);

  Future<String> updateProfileService({
    required String userId,
    String? name,
    String? newPassword,
    File? selectedImage,
  }) async {
    List<String> updatedFields = [];
    final Map<String, dynamic> newProfile = {};

    if (selectedImage != null) {
      final avatarPath = 'users/$userId.jpg';
      await _supabase.storage
          .from('avatars')
          .upload(
            avatarPath,
            selectedImage,
            fileOptions: const FileOptions(
              cacheControl: '0',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      newProfile['avatar_path'] = avatarPath;
      updatedFields.add('• Avatar');
    }

    // name
    if (name != null) {
      newProfile['name'] = name;
      updatedFields.add('• Name');
    }

    if (newProfile.isNotEmpty) {
      await _supabase.from('profiles').update(newProfile).eq('id', userId);
    }

    // password and auth
    if (newPassword != null) {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      updatedFields.add('• Password');
    }

    if (updatedFields.isEmpty) {
      return 'No fields were updated.';
    } else {
      return 'The following fields were updated:\n${updatedFields.join('\n')}';
    }
  }

  Future<ProfileModel> fetchProfileService({required String userId}) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final String path = data['avatar_path'] ?? Constants.defaultAvatarPath;
    final baseUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    final String avatarUrl =
        '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    return ProfileModel.fromJson(data, avatarUrl);
  }
}
