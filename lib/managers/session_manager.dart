import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/controllers/user_controller.dart';

class SessionManager {
  static final _storage = FlutterSecureStorage();

  static Future<bool> isTokenValid() async {
    try {
      final response = await ChosenApi.get('/auth/validate', auth: true);
      if (response.statusCode == 200) {
        await _storage.write(key: 'last_sync', value: DateTime.now().toIso8601String());
        return true;
      }
    } catch (e) {
      final cached = await _storage.read(key: 'user_data');
      return cached != null;
    }
    return false;
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  /// Get current user - fetches from API if possible, falls back to cached data
  static Future<UserModel?> getCurrentUser() async {
    try {
      final userController = UserController();
      
      // Try to fetch fresh data from API
      final success = await userController.getCurrentUser();
      
      if (success) {
        // Return the freshly fetched and cached user
        return await userController.getStoredUser();
      } else {
        // API call failed, return cached data if available
        print('Failed to fetch user from API, using cached data');
        return await userController.getStoredUser();
      }
    } catch (e) {
      print('Error getting current user: $e');
      // On any error, fallback to cached data
      try {
        final userController = UserController();
        return await userController.getStoredUser();
      } catch (storageError) {
        print('Error reading cached user data: $storageError');
        return null;
      }
    }
  }

  /// Clear all session data
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  /// Get stored token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}