import 'package:supabase_flutter/supabase_flutter.dart';

import 'cosmetic_models.dart';

class CosmeticService {
  final SupabaseClient _supabase;
  CosmeticService(this._supabase);

  /// All items in the catalog, plus whether this child owns each one.
  /// Default items count as owned for everyone.
  Future<({List<CosmeticItem> all, Set<int> ownedIds})> fetchItemsWithOwnership(
    String childId,
  ) async {
    final allData = await _supabase.from('cosmetic_items').select().order('id');
    final ownedData = await _supabase
        .from('child_owned_cosmetics')
        .select('item_id')
        .eq('child_id', childId);

    final all = (allData as List)
        .map((e) => CosmeticItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final explicitOwned =
        (ownedData as List).map((e) => e['item_id'] as int).toSet();

    // Default items are always owned; add explicitly owned ones
    final ownedIds = {
      for (final item in all)
        if (item.isDefault || explicitOwned.contains(item.id)) item.id,
    };

    return (all: all, ownedIds: ownedIds);
  }

  Future<List<RoomPlacement>> fetchPlacements(String childId) async {
    final data = await _supabase
        .from('room_placements')
        .select('*, cosmetic_items(sprite_index, priority_offset)')
        .eq('child_id', childId);
    return (data as List)
        .map((e) => RoomPlacement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a new placement and returns its id.
  Future<String> addPlacement(
    String childId,
    int itemId,
    double posX,
    double posY,
  ) async {
    final result = await _supabase
        .from('room_placements')
        .insert({
          'child_id': childId,
          'item_id': itemId,
          'pos_x': posX,
          'pos_y': posY,
        })
        .select('id')
        .single();
    return result['id'] as String;
  }

  Future<void> updatePlacement(String id, double posX, double posY) async {
    await _supabase
        .from('room_placements')
        .update({'pos_x': posX, 'pos_y': posY})
        .eq('id', id);
  }

  Future<void> removePlacement(String id) async {
    await _supabase.from('room_placements').delete().eq('id', id);
  }

  Future<void> grantOwnership(String childId, int itemId) async {
    await _supabase.from('child_owned_cosmetics').upsert({
      'child_id': childId,
      'item_id': itemId,
    });
  }
}
