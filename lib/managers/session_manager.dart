import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';


class SessionManager {
  static final _storage = FlutterSecureStorage();

  static Future<bool> isTokenValid() async {
    try{
        final response = await ChosenApi.get('/auth/validate', auth: true);
        if (response.statusCode == 200) {
          await _storage.write(key: 'last_sync', value: DateTime.now().toIso8601String());
          return true;
        }
    }catch(e){
      final cached = await _storage.read(key: 'user_data');
      return cached != null;
    } 
    return false;
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

}
