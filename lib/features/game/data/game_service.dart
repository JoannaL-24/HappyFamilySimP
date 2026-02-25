import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class GameService {
  final SupabaseClient _supabase;
  GameService(this._supabase);

  Future<Resources> fetchResources(String childId) async {
    final data = await _supabase
        .from('resources')
        .select()
        .eq('child_id', childId)
        .single();
    return Resources.fromJson(data);
  }

  Future<Creature> fetchCreature(String childId) async {
    final data = await _supabase
        .from('creatures')
        .select()
        .eq('child_id', childId)
        .single();
    return Creature.fromJson(data);
  }

  Stream<Resources> streamResources(String childId) {
    return _supabase
        .from('resources')
        .stream(primaryKey: ['id'])
        .eq('child_id', childId)
        .map((rows) =>
            rows.isEmpty ? Resources.empty : Resources.fromJson(rows.first));
  }
}
