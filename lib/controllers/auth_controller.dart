import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';


class AuthController {
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await ChosenApi.post('/auth/login', {
        "email": email,
        "password": password,
      }, auth: false);


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout()async{
    try {
      // final response = await ChosenApi.post('/auth/logout', {}, auth: true);

      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'user_data');
      await _storage.delete(key: 'last_sync');

      return true;
      
    } catch (e) {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'user_data');
      await _storage.delete(key: 'last_sync');
      return false;
    }
  }

}