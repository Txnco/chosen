import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/questionnaire.dart'; // Make sure this import matches your file structure

class QuestionnaireController {
  static const _storage = FlutterSecureStorage();
  
  /// Save questionnaire to the server
  static Future<Questionnaire?> saveQuestionnaire(Questionnaire questionnaire) async {
    try {
      // Convert questionnaire to JSON (without id and userId for creation)
      final questionnaireData = questionnaire.toJson();
      
      // Send POST request to save questionnaire
      final response = await ChosenApi.post('/questionnaire/', questionnaireData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response to get the created questionnaire with id
        final responseData = jsonDecode(response.body);
        final createdQuestionnaire = Questionnaire.fromJson(responseData);
        
        // Store questionnaire data locally for offline access
        await _storage.write(
          key: 'questionnaire_${createdQuestionnaire.id}',
          value: jsonEncode(responseData),
        );
        
        return createdQuestionnaire;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Update existing questionnaire
  static Future<bool> updateQuestionnaire(Questionnaire questionnaire) async {
    try {
      final questionnaireData = questionnaire.toJson();
      
      final response = await ChosenApi.put(
        '/questionnaires/${questionnaire.id}',
        questionnaireData,
      );
      
      if (response.statusCode == 200) {
        // Update local storage
        await _storage.write(
          key: 'questionnaire_${questionnaire.id}',
          value: jsonEncode(questionnaireData),
        );
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Get questionnaire by ID
  static Future<Questionnaire?> getQuestionnaire(String id) async {
    try {
      final response = await ChosenApi.get('/questionnaires/$id');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Questionnaire.fromJson(data);
      } else {
        // Try to get from local storage if server fails
        final localData = await _storage.read(key: 'questionnaire_$id');
        if (localData != null) {
          return Questionnaire.fromJson(jsonDecode(localData));
        }
        
        return null;
      }
    } catch (e) {
      
      // Fallback to local storage
      try {
        final localData = await _storage.read(key: 'questionnaire_$id');
        if (localData != null) {
          return Questionnaire.fromJson(jsonDecode(localData));
        }
      } catch (localError) {
      }
      
      return null;
    }
  }
  

  static Future<Questionnaire?> getUserQuestionnaire() async {
    try {
      final response = await ChosenApi.get('/questionnaire/');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response is null (no questionnaire exists)
        if (responseData == null) {
          return null;
        }
        
        // Parse and return questionnaire
        return Questionnaire.fromJson(responseData);
      } else if (response.statusCode == 404) {
        // No questionnaire found
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  
  /// Delete questionnaire
  static Future<bool> deleteQuestionnaire(String id) async {
    try {
      final response = await ChosenApi.delete('/questionnaires/$id');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from local storage
        await _storage.delete(key: 'questionnaire_$id');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Admin method to save questionnaire for specific user
  static Future<Questionnaire?> saveQuestionnaireForUser(Questionnaire questionnaire, int userId) async {
    try {
      // Create questionnaire with explicit user_id for admin purposes
      final questionnaireWithUser = questionnaire.copyWith(userId: userId);
      final questionnaireData = questionnaireWithUser.toJsonWithUser();
      
      final response = await ChosenApi.post('/admin/questionnaires', questionnaireData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Questionnaire.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  
  /// Clear all local questionnaire data
  static Future<void> clearLocalData() async {
    try {
      final allKeys = await _storage.readAll();
      final questionnaireKeys = allKeys.keys.where((key) => key.startsWith('questionnaire_'));
      
      for (final key in questionnaireKeys) {
        await _storage.delete(key: key);
      }
    } catch (e) {
    }
  }
}
