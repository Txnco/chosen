import 'package:flutter/foundation.dart';
import 'package:chosen/controllers/notifications_controller.dart';
import 'package:chosen/models/notification_preferences.dart';
import 'package:chosen/models/user.dart';

class NotificationProvider extends ChangeNotifier {
  bool _dailyPlanning = true;
  bool _dayRating = true;
  bool _progressPhoto = true;
  bool _weight = true;
  bool _water = true;
  bool _birthday = true;
  
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  bool get dailyPlanning => _dailyPlanning;
  bool get dayRating => _dayRating;
  bool get progressPhoto => _progressPhoto;
  bool get weight => _weight;
  bool get water => _water;
  bool get birthday => _birthday;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Load settings from backend API
  Future<void> loadSettings({UserModel? user}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await NotificationsController.fetchPreferencesFromApi();
      
      if (prefs != null) {
        _dailyPlanning = prefs.dailyPlanning.enabled;
        _dayRating = prefs.dayRating.enabled;
        _progressPhoto = prefs.progressPhoto.enabled;
        _weight = prefs.weightTracking.enabled;
        _water = prefs.waterReminders.enabled;
        _birthday = prefs.birthday.enabled;
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      _errorMessage = 'Greška pri učitavanju postavki';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Build NotificationPreferences from current provider state
  NotificationPreferences _buildCurrentPreferences() {
    return NotificationPreferences(
      dailyPlanning: NotificationPreference(enabled: _dailyPlanning, time: '20:00'),
      dayRating: NotificationPreference(enabled: _dayRating, time: '20:00'),
      progressPhoto: NotificationPreference(enabled: _progressPhoto, day: 1, time: '09:00'),
      weightTracking: NotificationPreference(enabled: _weight, day: 1, time: '08:00'),
      waterReminders: NotificationPreference(enabled: _water, intervalHours: 2),
      birthday: NotificationPreference(enabled: _birthday, time: '09:00'),
    );
  }

  /// Push current state to API
  Future<bool> _pushCurrentStateToApi() async {
    final prefs = _buildCurrentPreferences();
    return await NotificationsController.updatePreferencesToApi(prefs);
  }

  /// Set daily planning notification
  Future<bool> setDailyPlanning(bool value) async {
    final old = _dailyPlanning;
    _dailyPlanning = value;
    notifyListeners();

    final success = await _pushCurrentStateToApi();
    if (!success) {
      _dailyPlanning = old;
      _errorMessage = 'Neuspjelo spremanje postavke';
      notifyListeners();
      return false;
    }

    await NotificationsController.scheduleDailyPlanningReminder(enabled: value);
    return true;
  }

  /// Set day rating notification
  Future<bool> setDayRating(bool value) async {
    final old = _dayRating;
    _dayRating = value;
    notifyListeners();

    final success = await _pushCurrentStateToApi();
    if (!success) {
      _dayRating = old;
      _errorMessage = 'Neuspjelo spremanje postavke';
      notifyListeners();
      return false;
    }

    await NotificationsController.scheduleDayRatingReminder(enabled: value);
    return true;
  }

  /// Set progress photo notification
  Future<bool> setProgressPhoto(bool value) async {
    final old = _progressPhoto;
    _progressPhoto = value;
    notifyListeners();

    final success = await _pushCurrentStateToApi();
    if (!success) {
      _progressPhoto = old;
      _errorMessage = 'Neuspjelo spremanje postavke';
      notifyListeners();
      return false;
    }

    await NotificationsController.scheduleWeeklyProgressPhotoReminder(enabled: value);
    return true;
  }

  /// Set weight tracking notification
  Future<bool> setWeight(bool value) async {
    final old = _weight;
    _weight = value;
    notifyListeners();

    final success = await _pushCurrentStateToApi();
    if (!success) {
      _weight = old;
      _errorMessage = 'Neuspjelo spremanje postavke';
      notifyListeners();
      return false;
    }

    await NotificationsController.scheduleWeeklyWeightReminder(enabled: value);
    return true;
  }

  /// Set water reminder notification
  Future<bool> setWater(bool value) async {
    final old = _water;
    _water = value;
    notifyListeners();

    final success = await _pushCurrentStateToApi();
    if (!success) {
      _water = old;
      _errorMessage = 'Neuspjelo spremanje postavke';
      notifyListeners();
      return false;
    }

    await NotificationsController.scheduleWaterReminders(enabled: value, intervalHours: 2);
    return true;
  }

  /// Set birthday notification
  Future<bool> setBirthday(bool value, UserModel? user) async {
    final old = _birthday;
    _birthday = value;
    notifyListeners();

    final success = await _pushCurrentStateToApi();
    if (!success) {
      _birthday = old;
      _errorMessage = 'Neuspjelo spremanje postavke';
      notifyListeners();
      return false;
    }

    await NotificationsController.scheduleBirthdayNotification(
      enabled: value,
      user: user,
    );
    return true;
  }

  /// Reset all notifications to defaults
  Future<bool> resetToDefaults(UserModel? user) async {
    final oldDailyPlanning = _dailyPlanning;
    final oldDayRating = _dayRating;
    final oldProgressPhoto = _progressPhoto;
    final oldWeight = _weight;
    final oldWater = _water;
    final oldBirthday = _birthday;

    // Set all to true (defaults)
    _dailyPlanning = true;
    _dayRating = true;
    _progressPhoto = true;
    _weight = true;
    _water = true;
    _birthday = true;
    notifyListeners();

    final success = await NotificationsController.resetPreferencesOnApi();
    if (!success) {
      // Revert all
      _dailyPlanning = oldDailyPlanning;
      _dayRating = oldDayRating;
      _progressPhoto = oldProgressPhoto;
      _weight = oldWeight;
      _water = oldWater;
      _birthday = oldBirthday;
      _errorMessage = 'Neuspjelo resetiranje postavki';
      notifyListeners();
      return false;
    }

    // Reschedule all notifications
    await NotificationsController.rescheduleAllNotifications(user);
    return true;
  }
}