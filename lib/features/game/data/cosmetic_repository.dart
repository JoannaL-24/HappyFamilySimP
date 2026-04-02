import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cosmetic_models.dart';
import 'cosmetic_service.dart';

final _log = Logger();

class CosmeticRepository {
  final CosmeticService _service;
  CosmeticRepository(this._service);

  Future<({List<CosmeticItem> all, Set<int> ownedIds})> getItemsWithOwnership(
    String childId,
  ) async {
    try {
      return await _service.fetchItemsWithOwnership(childId);
    } on PostgrestException catch (e) {
      _log.e('Error fetching cosmetic items', error: e);
      return (all: <CosmeticItem>[], ownedIds: <int>{});
    }
  }

  Future<List<RoomPlacement>> getPlacements(String childId) async {
    try {
      return await _service.fetchPlacements(childId);
    } on PostgrestException catch (e) {
      _log.e('Error fetching room placements', error: e);
      return [];
    }
  }

  Future<String?> addPlacement(
    String childId,
    int itemId,
    double posX,
    double posY,
  ) async {
    try {
      return await _service.addPlacement(childId, itemId, posX, posY);
    } on PostgrestException catch (e) {
      _log.e('Error adding placement', error: e);
      return null;
    }
  }

  Future<void> updatePlacement(String id, double posX, double posY) async {
    try {
      await _service.updatePlacement(id, posX, posY);
    } on PostgrestException catch (e) {
      _log.e('Error updating placement', error: e);
    }
  }

  Future<void> removePlacement(String id) async {
    try {
      await _service.removePlacement(id);
    } on PostgrestException catch (e) {
      _log.e('Error removing placement', error: e);
    }
  }
}
