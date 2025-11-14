import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';


class ChosenApi {
  static const String baseUrl = 'https://admin.chosen-international.com/api/'; // or your production IP/domain
  //static const String baseUrl = 'http://10.0.2.2:8000'; // or your production IP/domain
  static const String uploadsUrl = 'https://admin.chosen-international.com/public'; // or your production IP/domain
  static final _storage = FlutterSecureStorage();

  // Made public so TrackingController can access it
  static Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Keep the private method for internal use
  static Future<String?> _getToken() async {
    return await getToken();
  }

  static Future<Map<String, String>> _buildHeaders({bool includeAuth = true, Map<String, String>? additionalHeaders}) async {
    
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

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  static Future<http.Response> get(String endpoint, {bool auth = true, Map<String, String>? headers}) async {
    final requestHeaders  = await _buildHeaders(includeAuth: auth, additionalHeaders: headers);
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: requestHeaders );
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool auth = true, Map<String, String>? headers}) async {
    final requestHeaders  = await _buildHeaders(includeAuth: auth, additionalHeaders: headers);
    return http.post(Uri.parse('$baseUrl$endpoint'), headers: requestHeaders , body: jsonEncode(body));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool auth = true, Map<String, String>? headers}) async {
    final requestHeaders  = await _buildHeaders(includeAuth: auth, additionalHeaders: headers);
    return http.put(Uri.parse('$baseUrl$endpoint'), headers: requestHeaders , body: jsonEncode(body));
  }

  static Future<http.Response> delete(String endpoint, {bool auth = true, Map<String, String>? headers}) async {
    final requestHeaders  = await _buildHeaders(includeAuth: auth, additionalHeaders: headers);
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: requestHeaders );
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body, {bool auth = true, Map<String, String>? headers}) async {
    final requestHeaders  = await _buildHeaders(includeAuth: auth, additionalHeaders: headers);
    return http.patch(Uri.parse('$baseUrl$endpoint'), headers: requestHeaders, body: jsonEncode(body));
  }

   static Future<http.Response> putMultipart(
    String endpoint, 
    {
      Map<String, String>? fields,
      File? file,
      String fileFieldName = 'profile_picture',
      bool auth = true,
    }
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('PUT', uri);

      // Add authorization header
      if (auth) {
        final token = await _getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add file if provided
      if (file != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
        );
        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      
      // Convert streamed response to regular response
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      print('Error in putMultipart: $e');
      rethrow;
    }
  }

}