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
      final questionnaire = await QuestionnaireController.getUserQuestionnaire();

      if(questionnaire != null) {
        bool isCompleted = isQuestionnaireComplete(questionnaire);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyQuestionnaireCompleted, isCompleted);

        return isCompleted;
      }else{
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyQuestionnaireCompleted, false);
        return false;
      }
    } catch (e) {
      
      // Fallback to local storage if API fails
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_keyQuestionnaireCompleted) ?? false;
      } catch (e) {
        return false;
      }
    }
  }

  static bool isQuestionnaireComplete(Questionnaire questionnaire) {
    // Define required fields for completion
     return (questionnaire.weight != null && questionnaire.weight! > 0) &&
         (questionnaire.height != null && questionnaire.height! > 0) &&
         (questionnaire.age != null && questionnaire.age! > 0) &&
         questionnaire.trainingEnvironment.isNotEmpty &&
         questionnaire.workShift.isNotEmpty;
  }

  // Mark questionnaire as completed
  static Future<void> markQuestionnaireCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyQuestionnaireCompleted, true);
      // Clear draft data when completed
      await clearDraftQuestionnaire();
    } catch (e) {
    }
  }

  static Future<Map<String, dynamic>?> getQuestionnaireProgress() async {
    try {
      final questionnaire = await QuestionnaireController.getUserQuestionnaire();
      
      if (questionnaire == null) {
        return null; // No questionnaire exists
      }

      // Convert questionnaire to map and determine current step
      Map<String, dynamic> data = {
        'weight': questionnaire.weight,
        'height': questionnaire.height,
        'age': questionnaire.age,
        'healthIssues': questionnaire.healthIssues,
        'badHabits': questionnaire.badHabits,
        'trainingEnvironment': questionnaire.trainingEnvironment,
        'workShift': questionnaire.workShift,
        'wakeUpTime': '${questionnaire.wakeUpTime.hour.toString().padLeft(2, '0')}:${questionnaire.wakeUpTime.minute.toString().padLeft(2, '0')}',
        'sleepTime': '${questionnaire.sleepTime.hour.toString().padLeft(2, '0')}:${questionnaire.sleepTime.minute.toString().padLeft(2, '0')}',
        'morningRoutine': questionnaire.morningRoutine,
        'eveningRoutine': questionnaire.eveningRoutine,
      };


      // Determine incomplete step
      int currentStep = getIncompleteStep(data);
      
      return {
        'questionnaire_data': data,
        'current_step': currentStep,
        'is_complete': isQuestionnaireComplete(questionnaire)
      };
      
    } catch (e) {
      return null;
    }
  }

  // Save draft questionnaire data
  static Future<void> saveDraftQuestionnaire(Map<String, dynamic> data, int currentStep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyQuestionnaireDraft, json.encode(data));
      await prefs.setInt(_keyCurrentStep, currentStep);
    } catch (e) {
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
      return null;
    }
  }

  // Get current step
  static Future<int> getCurrentStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyCurrentStep) ?? 0;
    } catch (e) {
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
    }
  }

  // Get incomplete step (returns the first step with missing required data)
  static int getIncompleteStep(Map<String, dynamic> data) {
    final requiredFields = [
      'weight',
      'height', 
      'age',
      'healthIssues',
      'badHabits',
      'trainingEnvironment',
      'workShift',
      'wakeUpTime',
      'sleepTime',
      'morningRoutine',
      'eveningRoutine',
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
    
    return 9; // All fields completed, go to final step
  }


}