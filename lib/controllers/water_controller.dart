// lib/controllers/water_controller.dart
import 'dart:convert';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/water_intake.dart';

class WaterController {
  
  /// Get user's water goal
  static Future<WaterGoal?> getUserWaterGoal() async {
    try {
      final response = await ChosenApi.get('/water/goal');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return WaterGoal.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting water goal: $e');
      return null;
    }
  }
  
  /// Set/Update user's water goal
  static Future<WaterGoal?> setUserWaterGoal(int dailyMl) async {
    try {
      final goalData = {
        'daily_ml': dailyMl,
      };
      
      final response = await ChosenApi.post('/water/goal', goalData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return WaterGoal.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error setting water goal: $e');
      return null;
    }
  }
  
  /// Add water intake entry
  static Future<WaterIntake?> addWaterIntake(int waterIntakeMl) async {
    try {
      final intakeData = {
        'water_intake': waterIntakeMl,
      };
      
      final response = await ChosenApi.post('/water/intake', intakeData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return WaterIntake.fromJson(responseData);
      } else {
        print('Failed to add water intake: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding water intake: $e');
      return null;
    }
  }
  
  /// Get water intake entries for a date range
  static Future<List<WaterIntake>> getWaterIntakeEntries({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
    String order = 'desc',
  }) async {
    try {
      String endpoint = '/water/intake?limit=$limit&offset=$offset&order=$order';
      
      if (startDate != null) {
        final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        endpoint += '&start_date=$startDateStr';
      }
      
      if (endDate != null) {
        final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        endpoint += '&end_date=$endDateStr';
      }
      
      final response = await ChosenApi.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => WaterIntake.fromJson(json)).toList();
      } else {
        print('Failed to get water intake entries: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting water intake entries: $e');
      return [];
    }
  }
  
  /// Get water intake entries for a specific date
  static Future<List<WaterIntake>> getWaterIntakeForDate(DateTime date) async {
    // Set start and end of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return getWaterIntakeEntries(
      startDate: startOfDay,
      endDate: endOfDay,
      order: 'desc',
    );
  }
  
  /// Get daily water statistics
  static Future<WaterDailyStats?> getDailyWaterStats({DateTime? targetDate}) async {
    try {
      String endpoint = '/water/stats/daily';
      
      if (targetDate != null) {
        final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        endpoint += '?target_date=$dateStr';
      }
      
      final response = await ChosenApi.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WaterDailyStats.fromJson(data);
      } else {
        print('Failed to get daily stats: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting daily water stats: $e');
      return null;
    }
  }
  
  /// Get today's water statistics
  static Future<WaterDailyStats?> getTodayWaterStats() async {
    return getDailyWaterStats(targetDate: DateTime.now());
  }
  
  /// Get weekly water statistics
  static Future<WaterWeeklyStats?> getWeeklyWaterStats({DateTime? weekStart}) async {
    try {
      String endpoint = '/water/stats/weekly';
      
      if (weekStart != null) {
        final dateStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
        endpoint += '?week_start=$dateStr';
      }
      
      final response = await ChosenApi.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WaterWeeklyStats.fromJson(data);
      } else {
        print('Failed to get weekly stats: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting weekly water stats: $e');
      return null;
    }
  }
  
  /// Get monthly water statistics
  static Future<Map<String, dynamic>?> getMonthlyWaterStats({int? year, int? month}) async {
    try {
      String endpoint = '/water/stats/monthly';
      
      List<String> params = [];
      if (year != null) params.add('year=$year');
      if (month != null) params.add('month=$month');
      
      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }
      
      final response = await ChosenApi.get(endpoint);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get monthly stats: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting monthly water stats: $e');
      return null;
    }
  }
  
  /// Update water intake entry
  static Future<WaterIntake?> updateWaterIntakeEntry(int entryId, int waterIntakeMl) async {
    try {
      final updateData = {
        'water_intake': waterIntakeMl,
      };
      
      final response = await ChosenApi.put('/water/intake/$entryId', updateData);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WaterIntake.fromJson(data);
      } else {
        print('Failed to update water intake: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating water intake: $e');
      return null;
    }
  }
  
  /// Delete water intake entry (soft delete by default)
  static Future<bool> deleteWaterIntakeEntry(int entryId, {bool hardDelete = false}) async {
    try {
      String endpoint = '/water/intake/$entryId';
      if (hardDelete) {
        endpoint += '?hard_delete=true';
      }
      
      final response = await ChosenApi.delete(endpoint);
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete water intake: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting water intake: $e');
      return false;
    }
  }
  
  /// Get water summary for dashboard
  static Future<Map<String, dynamic>> getWaterSummary() async {
    try {
      final stats = await getTodayWaterStats();
      
      if (stats != null) {
        return {
          'current_intake': stats.totalIntake,
          'daily_goal': stats.goalAmount,
          'progress_percentage': stats.progressPercentage / 100,
          'entries_today': stats.entryCount,
          'goal_reached': stats.goalReached,
          'remaining_ml': stats.remainingMl,
        };
      } else {
        // Return default data if API fails
        return {
          'current_intake': 0.0,
          'daily_goal': 2500.0,
          'progress_percentage': 0.0,
          'entries_today': 0,
          'goal_reached': false,
          'remaining_ml': 2500,
        };
      }
    } catch (e) {
      print('Error getting water summary: $e');
      // Return default data on error
      return {
        'current_intake': 0.0,
        'daily_goal': 2500.0,
        'progress_percentage': 0.0,
        'entries_today': 0,
        'goal_reached': false,
        'remaining_ml': 2500,
      };
    }
  }
  
  /// Create default water goal based on weight (35ml per kg)
  static Future<WaterGoal?> createDefaultWaterGoal(double weightKg) async {
    final defaultGoalMl = (weightKg * 35).round();
    return setUserWaterGoal(defaultGoalMl);
  }
  
  /// Ensure user has a water goal, create default if needed
  static Future<WaterGoal?> ensureUserHasWaterGoal() async {
    try {
      // First try to get existing goal
      final existingGoal = await getUserWaterGoal();
      if (existingGoal != null) {
        return existingGoal;
      }
      
      // If no goal exists, create default 2500ml goal
      return await setUserWaterGoal(2500);
    } catch (e) {
      print('Error ensuring water goal: $e');
      return null;
    }
  }
}