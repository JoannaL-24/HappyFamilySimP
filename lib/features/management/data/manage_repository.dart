import 'package:happy_family_sim/features/management/data/manage_service.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ManageRepository {
  final ManageService _manageService;
  ManageRepository(this._manageService);

  Future<void> addChild(
    String name,
    String email,
    String sixDigitCode,
    String parentId,
  ) async {
    try {
      await _manageService.childSignUpService(
        name: name,
        email: email,
        sixDigitCode: sixDigitCode,
        parentId: parentId,
      );
    } catch (e) {
      logger.e('Unexpected error during account creation', error: e);

      final errorMsg = e.toString().toLowerCase();

      // network error
      if (errorMsg.contains('socket') || errorMsg.contains('network')) {
        throw Exception('Please check your internet connection and try again.');
      }

      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchChildrenData(String parentId) async {
    try {
      return await _manageService.fetchChildrenListService(parentId);
    } catch (e) {
      logger.e('Error fetching children list', error: e);
      throw Exception('Could not load children. Please try again.');
    }
  }
}
