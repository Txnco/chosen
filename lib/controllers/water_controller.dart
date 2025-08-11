// lib/controllers/water_controller.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/water_intake.dart';

class WaterController {
  static const _storage = FlutterSecureStorage();
  
  /// Calculate daily water goal based on user's questionnaire data
  static Future<double> calculateDailyGoal() async {
    try {
      final response = await ChosenApi.get('/water/calculate-goal');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['daily_goal'] as num).toDouble();
      } else {
        // Fallback calculation if API fails
        return _fallbackGoalCalculation();
      }
    } catch (e) {
      return _fallbackGoalCalculation();
    }
  }
  
  static Future<double> _fallbackGoalCalculation() async {
    try {
      // Try to get cached questionnaire data
      final cachedUser = await _storage.read(key: 'user_data');
      if (cachedUser != null) {
        final userData = jsonDecode(cachedUser);
        // Basic calculation: 35ml per kg of body weight
        final weight = userData['weight'] ?? 70.0;
        return weight * 35.0;
      }
      return 2500.0; // Default goal
    } catch (e) {
      return 2500.0; // Default goal
    }
  }
  
  /// Add water intake
  static Future<WaterIntake?> addWaterIntake(double amount, {String? notes}) async {
    try {
      final intakeData = {
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'notes': notes,
      };
      
      final response = await ChosenApi.post('/water/intake', intakeData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return WaterIntake.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Get water intake for a specific date
  static Future<WaterStats?> getWaterStatsForDate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await ChosenApi.get('/water/stats/daily?date=$dateStr');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WaterStats.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Get water intake for current day
  static Future<WaterStats?> getTodayWaterStats() async {
    return getWaterStatsForDate(DateTime.now());
  }
  
  /// Get weekly water stats
  static Future<List<WaterStats>> getWeeklyWaterStats(DateTime weekStart) async {
    try {
      final dateStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      final response = await ChosenApi.get('/water/stats/weekly?start_date=$dateStr');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => WaterStats.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Get monthly water stats
  static Future<List<WaterStats>> getMonthlyWaterStats(int year, int month) async {
    try {
      final response = await ChosenApi.get('/water/stats/monthly?year=$year&month=$month');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => WaterStats.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Update water intake entry
  static Future<bool> updateWaterIntake(int intakeId, double amount, {String? notes}) async {
    try {
      final updateData = {
        'amount': amount,
        'notes': notes,
      };
      
      final response = await ChosenApi.put('/water/intake/$intakeId', updateData);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Delete water intake entry
  static Future<bool> deleteWaterIntake(int intakeId) async {
    try {
      final response = await ChosenApi.delete('/water/intake/$intakeId');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
  
  /// Get user's water goal
  static Future<WaterGoal?> getUserWaterGoal() async {
    try {
      final response = await ChosenApi.get('/water/goal');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WaterGoal.fromJson(data);
      } else if (response.statusCode == 404) {
        // No goal set, calculate and create one
        final calculatedGoal = await calculateDailyGoal();
        return await setUserWaterGoal(calculatedGoal);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Set/Update user's water goal
  static Future<WaterGoal?> setUserWaterGoal(double dailyGoal) async {
    try {
      final goalData = {
        'daily_goal': dailyGoal,
      };
      
      final response = await ChosenApi.post('/water/goal', goalData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return WaterGoal.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get water intake summary (for dashboard widget)
  static Future<Map<String, dynamic>> getWaterSummary() async {
    try {
      final response = await ChosenApi.get('/water/summary');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return dummy data for dashboard
        return {
          'current_intake': 1200.0,
          'daily_goal': 2500.0,
          'progress_percentage': 0.48,
          'entries_today': 4,
        };
      }
    } catch (e) {
      // Return dummy data for dashboard
      return {
        'current_intake': 1200.0,
        'daily_goal': 2500.0,
        'progress_percentage': 0.48,
        'entries_today': 4,
      };
    }
  }
  
  /// Cache water data locally
  static Future<void> cacheWaterData(String key, Map<String, dynamic> data) async {
    try {
      await _storage.write(key: 'water_$key', value: jsonEncode(data));
    } catch (e) {
    }
  }
  
  /// Get cached water data
  static Future<Map<String, dynamic>?> getCachedWaterData(String key) async {
    try {
      final cached = await _storage.read(key: 'water_$key');
      if (cached != null) {
        return jsonDecode(cached);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Clear water cache
  static Future<void> clearWaterCache() async {
    try {
      final allKeys = await _storage.readAll();
      final waterKeys = allKeys.keys.where((key) => key.startsWith('water_'));
      
      for (final key in waterKeys) {
        await _storage.delete(key: key);
      }
    } catch (e) {
    }
  }
}