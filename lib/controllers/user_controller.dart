import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
// import 'dart:developer' as developer;
import 'package:chosen/models/user.dart';

class UserController {
  final _storage = const FlutterSecureStorage();

  Future<bool> getCurrentUser() async {
    try {
      final response = await ChosenApi.get('/user/me', auth: true);
      if (response.statusCode == 200) {
        await _storage.write(key: 'user_data', value: response.body);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfilePicture(int userId, File imageFile) async {
    try {
      final response = await ChosenApi.putMultipart(
        '/user/$userId',
        file: imageFile,
        fileFieldName: 'profile_picture',
        auth: true,
      );
      
      if (response.statusCode == 200) {
        // Refresh user data after successful upload
        await getCurrentUser();
        return true;
      }
      
      print('Failed to update profile picture: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Error updating profile picture: $e');
      return false;
    }
  }

  String? getProfilePictureUrl(String? profilePicture) {
    // developer.log(jsonEncode(profilePicture));
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }

    if (profilePicture.startsWith('http')) {
      return profilePicture;
    }

    return '${ChosenApi.uploadsUrl}/uploads/profile/$profilePicture';
  }

  Future<UserModel?> getStoredUser() async {
    final jsonString = await _storage.read(key: 'user_data');
    if (jsonString == null) return null;
    return UserModel.fromJson(jsonDecode(jsonString));
  }

}