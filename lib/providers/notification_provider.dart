import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chosen/controllers/notifications_controller.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/models/notification_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  bool _dailyPlanning = false;
  bool _dayRating = false;
  bool _progressPhoto = false;
  bool _weight = false;
  bool _water = false;
  bool _birthday = false;
  int _waterInterval = 2;
  bool _isLoading = false;
  String? _errorMessage;

  bool get dailyPlanning => _dailyPlanning;
  bool get dayRating => _dayRating;
  bool get progressPhoto => _progressPhoto;
  bool get weight => _weight;
  bool get water => _water;
  bool get birthday => _birthday;
  int get waterInterval => _waterInterval;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load notification settings from backend API (with fallback to local)
  Future<void> loadSettings({UserModel? user}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to fetch from backend first
      final apiPreferences = await NotificationsController.fetchPreferencesFromApi();

      if (apiPreferences != null) {
        // Successfully fetched from API, update local state
        _dailyPlanning = apiPreferences.dailyPlanning.enabled;
        _dayRating = apiPreferences.dayRating.enabled;
        _progressPhoto = apiPreferences.progressPhoto.enabled;
        _weight = apiPreferences.weightTracking.enabled;
        _water = apiPreferences.waterReminders.enabled;
        _birthday = apiPreferences.birthday.enabled;
        _waterInterval = apiPreferences.waterReminders.intervalHours ?? 2;

        // Sync local preferences and reschedule notifications
        await NotificationsController.syncPreferencesWithApi(user);
      } else {
        // Fallback to local SharedPreferences if API fails (offline mode)
        final settings = await NotificationsController.getNotificationSettings();
        _dailyPlanning = settings['daily_planning'] ?? false;
        _dayRating = settings['day_rating'] ?? false;
        _progressPhoto = settings['progress_photo'] ?? false;
        _weight = settings['weight'] ?? false;
        _water = settings['water'] ?? false;
        _birthday = settings['birthday'] ?? false;
      }
    } catch (e) {
      // If any error, fallback to local settings
      final settings = await NotificationsController.getNotificationSettings();
      _dailyPlanning = settings['daily_planning'] ?? false;
      _dayRating = settings['day_rating'] ?? false;
      _progressPhoto = settings['progress_photo'] ?? false;
      _weight = settings['weight'] ?? false;
      _water = settings['water'] ?? false;
      _birthday = settings['birthday'] ?? false;

      _errorMessage = 'Could not sync with server. Using local settings.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Toggle daily planning notification
  Future<bool> setDailyPlanning(bool value) async {
    final oldValue = _dailyPlanning;
    _dailyPlanning = value;
    notifyListeners();

    // Schedule/cancel local notification
    await NotificationsController.scheduleDailyPlanningReminder(enabled: value);

    // Update backend
    final preferences = await NotificationsController.getCurrentPreferences();
    final updatedPreferences = NotificationPreferences(
      dailyPlanning: NotificationPreference(enabled: value, time: preferences.dailyPlanning.time),
      dayRating: preferences.dayRating,
      progressPhoto: preferences.progressPhoto,
      weightTracking: preferences.weightTracking,
      waterReminders: preferences.waterReminders,
      birthday: preferences.birthday,
    );

    final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

    if (!success) {
      // Revert on failure
      _dailyPlanning = oldValue;
      notifyListeners();
      _errorMessage = 'Could not update notifications. Please check your connection.';
      return false;
    }

    return true;
  }

  // Toggle day rating notification
  Future<bool> setDayRating(bool value) async {
    final oldValue = _dayRating;
    _dayRating = value;
    notifyListeners();

    await NotificationsController.scheduleDayRatingReminder(enabled: value);

    final preferences = await NotificationsController.getCurrentPreferences();
    final updatedPreferences = NotificationPreferences(
      dailyPlanning: preferences.dailyPlanning,
      dayRating: NotificationPreference(enabled: value, time: preferences.dayRating.time),
      progressPhoto: preferences.progressPhoto,
      weightTracking: preferences.weightTracking,
      waterReminders: preferences.waterReminders,
      birthday: preferences.birthday,
    );

    final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

    if (!success) {
      _dayRating = oldValue;
      notifyListeners();
      _errorMessage = 'Could not update notifications. Please check your connection.';
      return false;
    }

    return true;
  }

  // Toggle progress photo notification
  Future<bool> setProgressPhoto(bool value) async {
    final oldValue = _progressPhoto;
    _progressPhoto = value;
    notifyListeners();

    await NotificationsController.scheduleWeeklyProgressPhotoReminder(enabled: value);

    final preferences = await NotificationsController.getCurrentPreferences();
    final updatedPreferences = NotificationPreferences(
      dailyPlanning: preferences.dailyPlanning,
      dayRating: preferences.dayRating,
      progressPhoto: NotificationPreference(
        enabled: value,
        day: preferences.progressPhoto.day,
        time: preferences.progressPhoto.time,
      ),
      weightTracking: preferences.weightTracking,
      waterReminders: preferences.waterReminders,
      birthday: preferences.birthday,
    );

    final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

    if (!success) {
      _progressPhoto = oldValue;
      notifyListeners();
      _errorMessage = 'Could not update notifications. Please check your connection.';
      return false;
    }

    return true;
  }

  // Toggle weight tracking notification
  Future<bool> setWeight(bool value) async {
    final oldValue = _weight;
    _weight = value;
    notifyListeners();

    await NotificationsController.scheduleWeeklyWeightReminder(enabled: value);

    final preferences = await NotificationsController.getCurrentPreferences();
    final updatedPreferences = NotificationPreferences(
      dailyPlanning: preferences.dailyPlanning,
      dayRating: preferences.dayRating,
      progressPhoto: preferences.progressPhoto,
      weightTracking: NotificationPreference(
        enabled: value,
        day: preferences.weightTracking.day,
        time: preferences.weightTracking.time,
      ),
      waterReminders: preferences.waterReminders,
      birthday: preferences.birthday,
    );

    final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

    if (!success) {
      _weight = oldValue;
      notifyListeners();
      _errorMessage = 'Could not update notifications. Please check your connection.';
      return false;
    }

    return true;
  }

  // Toggle water reminder notification
  Future<bool> setWater(bool value, {int? intervalHours}) async {
    final oldValue = _water;
    final oldInterval = _waterInterval;

    _water = value;
    if (intervalHours != null) {
      _waterInterval = intervalHours;
    }
    notifyListeners();

    await NotificationsController.scheduleWaterReminders(
      enabled: value,
      intervalHours: _waterInterval,
    );

    final preferences = await NotificationsController.getCurrentPreferences();
    final updatedPreferences = NotificationPreferences(
      dailyPlanning: preferences.dailyPlanning,
      dayRating: preferences.dayRating,
      progressPhoto: preferences.progressPhoto,
      weightTracking: preferences.weightTracking,
      waterReminders: NotificationPreference(
        enabled: value,
        intervalHours: _waterInterval,
      ),
      birthday: preferences.birthday,
    );

    final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

    if (!success) {
      _water = oldValue;
      _waterInterval = oldInterval;
      notifyListeners();
      _errorMessage = 'Could not update notifications. Please check your connection.';
      return false;
    }

    return true;
  }

  // Set water interval
  Future<bool> setWaterInterval(int hours) async {
    final oldInterval = _waterInterval;
    _waterInterval = hours;
    notifyListeners();

    if (_water) {
      await NotificationsController.scheduleWaterReminders(
        enabled: true,
        intervalHours: hours,
      );

      final preferences = await NotificationsController.getCurrentPreferences();
      final updatedPreferences = NotificationPreferences(
        dailyPlanning: preferences.dailyPlanning,
        dayRating: preferences.dayRating,
        progressPhoto: preferences.progressPhoto,
        weightTracking: preferences.weightTracking,
        waterReminders: NotificationPreference(
          enabled: true,
          intervalHours: hours,
        ),
        birthday: preferences.birthday,
      );

      final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

      if (!success) {
        _waterInterval = oldInterval;
        notifyListeners();
        _errorMessage = 'Could not update notifications. Please check your connection.';
        return false;
      }
    }

    return true;
  }

  // Toggle birthday notification
  Future<bool> setBirthday(bool value, UserModel? user) async {
    final oldValue = _birthday;
    _birthday = value;
    notifyListeners();

    await NotificationsController.scheduleBirthdayNotification(
      enabled: value,
      user: user,
    );

    final preferences = await NotificationsController.getCurrentPreferences();
    final updatedPreferences = NotificationPreferences(
      dailyPlanning: preferences.dailyPlanning,
      dayRating: preferences.dayRating,
      progressPhoto: preferences.progressPhoto,
      weightTracking: preferences.weightTracking,
      waterReminders: preferences.waterReminders,
      birthday: NotificationPreference(enabled: value, time: preferences.birthday.time),
    );

    final success = await NotificationsController.updatePreferencesToApi(updatedPreferences);

    if (!success) {
      _birthday = oldValue;
      notifyListeners();
      _errorMessage = 'Could not update notifications. Please check your connection.';
      return false;
    }

    return true;
  }

  // Enable all notifications
  Future<void> enableAll(UserModel? user) async {
    _dailyPlanning = true;
    _dayRating = true;
    _progressPhoto = true;
    _weight = true;
    _water = true;
    _birthday = true;
    notifyListeners();

    await NotificationsController.rescheduleAllNotifications(user);

    // Update backend
    final preferences = await NotificationsController.getCurrentPreferences();
    await NotificationsController.updatePreferencesToApi(preferences);
  }

  // Disable all notifications
  Future<void> disableAll() async {
    _dailyPlanning = false;
    _dayRating = false;
    _progressPhoto = false;
    _weight = false;
    _water = false;
    _birthday = false;
    notifyListeners();

    await NotificationsController.cancelAllNotifications();

    // Update backend
    final preferences = await NotificationsController.getCurrentPreferences();
    await NotificationsController.updatePreferencesToApi(preferences);
  }

  // Reset preferences to defaults
  Future<bool> resetToDefaults(UserModel? user) async {
    _isLoading = true;
    notifyListeners();

    final success = await NotificationsController.resetPreferencesOnApi();

    if (success) {
      // Reload from backend to get defaults
      await loadSettings(user: user);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = 'Could not reset preferences. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
