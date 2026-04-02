import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_service.dart';
import 'models.dart';

var logger = Logger();

class GameRepository {
  final GameService _gameService;
  GameRepository(this._gameService);

  Future<void> ensureDefaults(String childId) async {
    try {
      await _gameService.initializeDefaults(childId);
    } on PostgrestException catch (e) {
      logger.e('Postgrest error initializing defaults', error: e);
    } catch (e) {
      logger.e('Unexpected error initializing defaults', error: e);
    }
  }

  Future<Resources> getResources(String childId) async {
    try {
      return await _gameService.fetchResources(childId);

    } on PostgrestException catch (e) {
      logger.e('Postgrest error fetching resources', error: e);
      throw Exception('Failed to load resources. Please try again.');

    } catch (e) {
      logger.e('Unexpected error fetching resources', error: e);
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<Creature> getCreature(String childId) async {
    try {
      return await _gameService.fetchCreature(childId);

    } on PostgrestException catch (e) {
      logger.e('Postgrest error fetching creature', error: e);
      throw Exception('Failed to load creature. Please try again.');

    } catch (e) {
      logger.e('Unexpected error fetching creature', error: e);
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Applies one unit of [type] resource to the creature.
  /// Decrements the resource count, increments the corresponding stat.
  /// Throws if resource is 0 or stat is already at 100.
  Future<Creature> applyResource(String childId, ResourceType type) async {
    try {
      return await _gameService.applyResource(childId, type);
    } on PostgrestException catch (e) {
      logger.e('Postgrest error applying resource', error: e);
      throw Exception('Failed to apply resource. Please try again.');
    } catch (e) {
      logger.e('Unexpected error applying resource', error: e);
      rethrow;
    }
  }

  Future<void> updateCreatureStats(
    String childId, {
    required int fullness,
    required int happiness,
    required int cleanliness,
  }) async {
    try {
      await _gameService.updateCreatureStats(
        childId,
        fullness: fullness,
        happiness: happiness,
        cleanliness: cleanliness,
      );
    } on PostgrestException catch (e) {
      logger.e('Postgrest error updating creature stats', error: e);
    } catch (e) {
      logger.e('Unexpected error updating creature stats', error: e);
    }
  }

  /// Live stream of resource updates — emits whenever the DB row changes.
  Stream<Resources> watchResources(String childId) {
    return _gameService.streamResources(childId);
  }
}
