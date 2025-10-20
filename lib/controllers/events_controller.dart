// lib/controllers/events_controller.dart
import 'dart:convert';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/events.dart';

class EventsController {
  static int _getTimezoneOffset() {
    return -DateTime.now().timeZoneOffset.inMinutes;
  }

  static Map<String, String> _getTimezoneHeaders() {
    return {
      'X-Timezone-Offset': _getTimezoneOffset().toString(),
    };
  }
  static Future<List<Event>> getEvents({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeRepeating = true,
  }) async {
    try {
      String endpoint = 'events/?include_repeating=$includeRepeating';
      
      if (userId != null) {
        endpoint += '&user_id=$userId';
      }
      if (startDate != null) {
        endpoint += '&start_date=${startDate.toIso8601String()}';
      }
      if (endDate != null) {
        endpoint += '&end_date=${endDate.toIso8601String()}';
      }

      final response = await ChosenApi.get(
        endpoint,
        auth: true,
        headers: _getTimezoneHeaders()
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.body}');
      }
    } catch (e) {
      print('Error fetching events: $e');
      throw Exception('Error fetching events: $e');
    }
  }

  static Future<Event?> createEvent(Event event) async {
    try {
      final response = await ChosenApi.post(
        'events/',
        event.toJson(),
        auth: true,
        headers: _getTimezoneHeaders(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to create event: ${response.body}');
      }
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Error creating event: $e');
    }
  }

  static Future<Event?> updateEvent(int eventId, Map<String, dynamic> updates) async {
    try {
      final response = await ChosenApi.patch(
        'events/$eventId',
        updates,
        auth: true,
        headers: _getTimezoneHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to update event: ${response.body}');
      }
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Error updating event: $e');
    }
  }

  static Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await ChosenApi.delete(
        'events/$eventId',
        auth: true,
        headers: _getTimezoneHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete event: ${response.body}');
      }
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Error deleting event: $e');
    }
  }

  static Future<Event?> getEvent(int eventId) async {
    try {
      final response = await ChosenApi.get(
        'events/$eventId',
        auth: true,
        headers: _getTimezoneHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to get event: ${response.body}');
      }
    } catch (e) {
      print('Error fetching event: $e');
      throw Exception('Error fetching event: $e');
    }
  }
}