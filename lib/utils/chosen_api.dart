import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ChosenApi {
  static const String baseUrl = 'https://admin.chosen-international.com/api'; // or your production IP/domain
  // static const String baseUrl = 'http://192.168.1.19:8000'; // or your production IP/domain
  static final _storage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
       try {
        final token = await _getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
       }catch(e){
          return {'error': 'No token found!'};
       }
    }

    return headers;
  }

  static Future<http.Response> get(String endpoint, {bool auth = true}) async {
    final headers = await _buildHeaders(includeAuth: auth);
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    final headers = await _buildHeaders(includeAuth: auth);
    return http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    final headers = await _buildHeaders(includeAuth: auth);
    return http.put(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String endpoint, {bool auth = true}) async {
    final headers = await _buildHeaders(includeAuth: auth);
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
