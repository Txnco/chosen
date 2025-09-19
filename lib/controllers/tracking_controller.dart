import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/weight_tracking.dart';
import 'package:chosen/models/day_rating.dart';
import 'package:chosen/models/progress_photo.dart';

class TrackingController {
  
  // Weight Tracking Methods
  static Future<List<WeightTracking>> getWeightTracking() async {
    try {
      final response = await ChosenApi.get('/tracking/weight');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => WeightTracking.fromJson(item)).toList();
      } else {
        print('Failed to get weight tracking: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting weight tracking: $e');
      return [];
    }
  }
  
  static Future<WeightTracking?> saveWeight(double weight, {DateTime? date}) async {
    try {
      final Map<String, dynamic> body = {'weight': weight};
      if (date != null) {
        body['date'] = date.toIso8601String().substring(0, 10);
      }
      final response = await ChosenApi.post('/tracking/weight', body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map && data['weight'] is String) {
          data['weight'] = double.tryParse(data['weight']) ?? 0.0;
        }
        return WeightTracking.fromJson(data);
      } else {
        print('Failed to save weight: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error saving weight: $e');
      return null;
    }
  }

  // Upload progress photo with file
  static Future<ProgressPhoto?> uploadProgressPhoto(String angle, String imagePath) async {
    try {
      final uri = Uri.parse('${ChosenApi.baseUrl}/tracking/progress-photos');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      final token = await ChosenApi.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add form fields
      request.fields['angle'] = angle;
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imagePath)
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProgressPhoto.fromJson(data);
      } else {
        print('Failed to upload progress photo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading progress photo: $e');
      return null;
    }
  }

  static Future<WeightTracking?> updateWeight(int weightId, double weight) async {
    try {
      final response = await ChosenApi.put('/tracking/weight/$weightId', {
        'weight': weight,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeightTracking.fromJson(data);
      } else {
        print('Failed to update weight: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating weight: $e');
      return null;
    }
  }

  // Day Rating Methods
  static Future<List<DayRating>> getDayRatings() async {
    try {
      final response = await ChosenApi.get('/tracking/day-rating');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => DayRating.fromJson(item)).toList();
      } else {
        print('Failed to get day ratings: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting day ratings: $e');
      return [];
    }
  }

  static Future<DayRating?> createDayRating({int? score, String? note}) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (score != null) body['score'] = score;
      if (note != null && note.isNotEmpty) body['note'] = note;
      
      final response = await ChosenApi.post('/tracking/day-rating', body);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DayRating.fromJson(data);
      } else {
        print('Failed to create day rating: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating day rating: $e');
      return null;
    }
  }

  static Future<DayRating?> updateDayRating(int ratingId, {int? score, String? note}) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (score != null) body['score'] = score;
      if (note != null) body['note'] = note;
      
      final response = await ChosenApi.put('/tracking/day-rating/$ratingId', body);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DayRating.fromJson(data);
      } else {
        print('Failed to update day rating: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating day rating: $e');
      return null;
    }
  }

  // Progress Photos Methods
  static Future<List<ProgressPhoto>> getProgressPhotos({String? angle}) async {
    try {
      String endpoint = '/tracking/progress-photos';
      if (angle != null) {
        endpoint += '?angle=$angle';
      }
      
      final response = await ChosenApi.get(endpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ProgressPhoto.fromJson(item)).toList();
      } else {
        print('Failed to get progress photos: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting progress photos: $e');
      return [];
    }
  }

  static Future<ProgressPhoto?> saveProgressPhoto(String angle, String imageUrl) async {
    try {
      final response = await ChosenApi.post('/tracking/progress-photos', {
        'angle': angle,
        'image_url': imageUrl,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProgressPhoto.fromJson(data);
      } else {
        print('Failed to save progress photo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error saving progress photo: $e');
      return null;
    }
  }

  static Future<ProgressPhoto?> updateProgressPhoto(int photoId, {String? angle, String? imageUrl}) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (angle != null) body['angle'] = angle;
      if (imageUrl != null) body['image_url'] = imageUrl;
      
      final response = await ChosenApi.put('/tracking/progress-photos/$photoId', body);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProgressPhoto.fromJson(data);
      } else {
        print('Failed to update progress photo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating progress photo: $e');
      return null;
    }
  }
}