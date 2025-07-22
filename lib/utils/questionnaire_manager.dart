import 'package:shared_preferences/shared_preferences.dart';
import 'package:chosen/models/questionnaire.dart';
import 'package:chosen/controllers/questionnaire_controller.dart';
import 'dart:convert';

class QuestionnaireManager {
  static const String _keyQuestionnaireCompleted = 'questionnaire_completed';
  static const String _keyQuestionnaireDraft = 'questionnaire_draft';
  static const String _keyCurrentStep = 'questionnaire_current_step';

  // Check if questionnaire is completed
  static Future<bool> isQuestionnaireCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyQuestionnaireCompleted) ?? false;
    } catch (e) {
      print('Error checking questionnaire completion: $e');
      return false;
    }
  }

  // Mark questionnaire as completed
  static Future<void> markQuestionnaireCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyQuestionnaireCompleted, true);
      // Clear draft data when completed
      await clearDraftQuestionnaire();
    } catch (e) {
      print('Error marking questionnaire as completed: $e');
    }
  }

  // Save draft questionnaire data
  static Future<void> saveDraftQuestionnaire(Map<String, dynamic> data, int currentStep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyQuestionnaireDraft, json.encode(data));
      await prefs.setInt(_keyCurrentStep, currentStep);
    } catch (e) {
      print('Error saving draft questionnaire: $e');
    }
  }

  // Get draft questionnaire data
  static Future<Map<String, dynamic>?> getDraftQuestionnaire() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftString = prefs.getString(_keyQuestionnaireDraft);
      if (draftString != null) {
        return json.decode(draftString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting draft questionnaire: $e');
      return null;
    }
  }

  // Get current step
  static Future<int> getCurrentStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyCurrentStep) ?? 0;
    } catch (e) {
      print('Error getting current step: $e');
      return 0;
    }
  }

  // Clear draft data
  static Future<void> clearDraftQuestionnaire() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyQuestionnaireDraft);
      await prefs.remove(_keyCurrentStep);
    } catch (e) {
      print('Error clearing draft questionnaire: $e');
    }
  }

  // Complete questionnaire and save to backend
  static Future<bool> completeQuestionnaire(Questionnaire questionnaire) async {
    try {
      // Save to backend
      final savedQuestionnaire = await QuestionnaireController.saveQuestionnaire(questionnaire);
      
      if (savedQuestionnaire != null) {
        // Mark as completed locally
        await markQuestionnaireCompleted();
        return true;
      }
      return false;
    } catch (e) {
      print('Error completing questionnaire: $e');
      return false;
    }
  }

  // Reset questionnaire (for testing or user request)
  static Future<void> resetQuestionnaire() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyQuestionnaireCompleted, false);
      await clearDraftQuestionnaire();
    } catch (e) {
      print('Error resetting questionnaire: $e');
    }
  }

  // Get incomplete step (returns the first step with missing required data)
  static int getIncompleteStep(Map<String, dynamic> data) {
    final requiredFields = [
      'weight',
      'height', 
      'age',
      'trainingEnvironment',
      'workShift',
      'wakeUpTime',
      'sleepTime',
    ];

    for (int i = 0; i < requiredFields.length; i++) {
      final field = requiredFields[i];
      if (!data.containsKey(field) || 
          data[field] == null || 
          (data[field] is String && (data[field] as String).isEmpty) ||
          (data[field] is num && data[field] == 0)) {
        return i; // Return the step index
      }
    }
    
    // If all required fields are present, check optional fields
    if (!data.containsKey('healthIssues') || 
        !data.containsKey('badHabits') ||
        !data.containsKey('morningRoutine') ||
        !data.containsKey('eveningRoutine')) {
      return 7; // Return step for optional fields
    }
    
    return 9; // All fields completed, go to final step
  }
}