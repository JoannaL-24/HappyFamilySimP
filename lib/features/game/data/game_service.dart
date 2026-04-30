import 'package:supabase_flutter/supabase_flutter.dart';

import '../game_engine.dart' show kSecondsPerDepletionTick, kStatIncrement, kBoxPiecesRequired;
import 'models.dart';

class GameService {
  final SupabaseClient _supabase;
  GameService(this._supabase);

  /// Inserts default creature + resources rows if they don't exist yet.
  Future<void> initializeDefaults(String childId) async {
    final creatures = await _supabase
        .from('creatures')
        .select('child_id')
        .eq('child_id', childId);
    if ((creatures as List).isEmpty) {
      await _supabase.from('creatures').insert({
        'child_id': childId,
        'type': 'cat',
        'name': 'Cat',
        'fullness': 100,
        'happiness': 100,
        'cleanliness': 100,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    final resources = await _supabase
        .from('resources')
        .select('child_id')
        .eq('child_id', childId);
    if ((resources as List).isEmpty) {
      await _supabase.from('resources').insert({
        'child_id': childId,
        'food': 5,
        'play': 5,
        'clean': 5,
        'box_pieces': 0,
      });
    }
  }

  Future<Resources> fetchResources(String childId) async {
    final data = await _supabase
        .from('resources')
        .select()
        .eq('child_id', childId)
        .single();
    return Resources.fromJson(data);
  }

  /// Fetches the creature, applies offline depletion based on elapsed time,
  /// saves the updated stats back to DB, and returns the current creature.
  Future<Creature> fetchCreature(String childId) async {
    final data = await _supabase
        .from('creatures')
        .select()
        .eq('child_id', childId)
        .single();

    final creature = Creature.fromJson(data);
    final now = DateTime.now().toUtc();
    final elapsedSeconds =
        now.difference(creature.lastUpdatedAt).inSeconds.toDouble();
    final depleted = (elapsedSeconds / kSecondsPerDepletionTick).floor();

    if (depleted <= 0) return creature;

    final newFullness = (creature.fullness - depleted).clamp(0, 100);
    final newHappiness = (creature.happiness - depleted).clamp(0, 100);
    final newCleanliness = (creature.cleanliness - depleted).clamp(0, 100);

    await _supabase.from('creatures').update({
      'fullness': newFullness,
      'happiness': newHappiness,
      'cleanliness': newCleanliness,
      'last_updated_at': now.toIso8601String(),
    }).eq('child_id', childId);

    return creature.copyWith(
      fullness: newFullness,
      happiness: newHappiness,
      cleanliness: newCleanliness,
      lastUpdatedAt: now,
    );
  }

  /// Decrements the resource by 1 and increments the corresponding creature
  /// stat by [kStatIncrement], both clamped to valid ranges.
  /// Returns the updated [Creature].
  Future<Creature> applyResource(String childId, ResourceType type) async {
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
      _supabase.from('creatures').update({
        statField: newStat,
        'last_updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('child_id', childId),
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
      'last_updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('child_id', childId);
  }

  Future<void> spendBoxPieces(String childId) async {
    final data = await _supabase
        .from('resources')
        .select('box_pieces')
        .eq('child_id', childId)
        .single();
    final current = (data['box_pieces'] as num? ?? 0).toInt();
    if (current < kBoxPiecesRequired) return;
    await _supabase
        .from('resources')
        .update({'box_pieces': current - kBoxPiecesRequired})
        .eq('child_id', childId);
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
