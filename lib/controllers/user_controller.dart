import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
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

  Future<UserModel?> getStoredUser() async {
    final jsonString = await _storage.read(key: 'user_data');
    if (jsonString == null) return null;
    return UserModel.fromJson(jsonDecode(jsonString));
  }

}