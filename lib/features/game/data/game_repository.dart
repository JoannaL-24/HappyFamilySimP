import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_service.dart';
import 'models.dart';

var logger = Logger();

class GameRepository {
  final GameService _gameService;
  GameRepository(this._gameService);

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

  /// Live stream of resource updates — emits whenever the DB row changes.
  Stream<Resources> watchResources(String childId) {
    return _gameService.streamResources(childId);
  }
}
