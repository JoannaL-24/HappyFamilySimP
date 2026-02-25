import 'package:happy_family_sim/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageService {
  final SupabaseClient _supabase;
  ManageService(this._supabase);

  Future<void> childSignUpService({
    required String name,
    required String email,
    required String sixDigitCode,
    required String parentId,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-child',
      body: {
        'childName': name,
        'childEmail': email,
        'sixDigitCode': sixDigitCode,
        'role': Constants.childRole,
        'avatarPath': Constants.defaultAvatarPath,
        'parentId': parentId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    if (response.status != 200 || data.containsKey('error')) {
      throw Exception(data['error'] ?? 'Failed to create child');
    }
  }

  Future<List<Map<String, dynamic>>> fetchChildrenListService(
    String parentId,
  ) async {
    final response = await _supabase
        .from('family_links')
        .select('''
          profiles!child_id (
            id,
            name,
            role,
            avatar_path,
            code
          )
        ''')
        .eq('parent_id', parentId);

    return List<Map<String, dynamic>>.from(response);
  }
}
