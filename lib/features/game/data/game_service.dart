import 'package:supabase_flutter/supabase_flutter.dart';

import '../game_engine.dart';
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

  /// Decrements the resource by 1 and increments the corresponding creature
  /// stat by [kStatIncrement], both clamped to valid ranges.
  /// Returns the updated [Creature].
  Future<Creature> applyResource(String childId, ResourceType type) async {
    // Fetch current values
    final resourceData = await _supabase
        .from('resources')
        .select()
        .eq('child_id', childId)
        .single();
    final creatureData = await _supabase
        .from('creatures')
        .select()
        .eq('child_id', childId)
        .single();

    final resources = Resources.fromJson(resourceData);
    final creature = Creature.fromJson(creatureData);

    final currentAmount = resources.amountFor(type);
    final currentStat = creature.statFor(type);

    if (currentAmount <= 0) throw Exception('No ${type.name} left!');
    if (currentStat >= 100) throw Exception('${type.name} is already full!');

    final (resourceField, statField) = switch (type) {
      ResourceType.food => ('food', 'fullness'),
      ResourceType.play => ('play', 'happiness'),
      ResourceType.clean => ('clean', 'cleanliness'),
    };

    final newStat = (currentStat + kStatIncrement).clamp(0, 100);

    await Future.wait([
      _supabase
          .from('resources')
          .update({resourceField: currentAmount - 1})
          .eq('child_id', childId),
      _supabase
          .from('creatures')
          .update({statField: newStat})
          .eq('child_id', childId),
    ]);

    return creature.copyWith(
      fullness: type == ResourceType.food ? newStat : creature.fullness,
      happiness: type == ResourceType.play ? newStat : creature.happiness,
      cleanliness: type == ResourceType.clean ? newStat : creature.cleanliness,
    );
  }

  Future<void> updateCreatureStats(
    String childId, {
    required int fullness,
    required int happiness,
    required int cleanliness,
  }) async {
    await _supabase.from('creatures').update({
      'fullness': fullness.clamp(0, 100),
      'happiness': happiness.clamp(0, 100),
      'cleanliness': cleanliness.clamp(0, 100),
    }).eq('child_id', childId);
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
