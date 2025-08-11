import 'package:flutter/material.dart';

class Questionnaire {
  final int? id;           
  final int? userId;       
  final double? weight;
  final double? height;
  final int? age;
  final String? healthIssues;
  final String? badHabits;
  final String trainingEnvironment;
  final String workShift;
  final TimeOfDay wakeUpTime;  
  final TimeOfDay sleepTime;    
  final String? morningRoutine;
  final String? eveningRoutine;
  final DateTime createdAt;
  final DateTime updatedAt;

  Questionnaire({
    this.id,               
    this.userId,           
    this.weight,
    this.height,
    this.age,
    this.healthIssues,
    this.badHabits,
    required this.trainingEnvironment,
    required this.workShift,
    required this.wakeUpTime,
    required this.sleepTime,
    this.morningRoutine,
    this.eveningRoutine,
    required this.createdAt,
    required this.updatedAt,
  });
  

  // For creating new questionnaire (no id, no userId in JSON)
  Map<String, dynamic> toJson() => {
    "weight": weight,
    "height": height,
    "age": age,
    "health_issues": healthIssues,
    "bad_habits": badHabits,
    "workout_environment": trainingEnvironment.toLowerCase(),
    "work_shift": workShift.toLowerCase(),
    "wake_up_time": "${wakeUpTime.hour.toString().padLeft(2, '0')}:${wakeUpTime.minute.toString().padLeft(2, '0')}",
    "sleep_time": "${sleepTime.hour.toString().padLeft(2, '0')}:${sleepTime.minute.toString().padLeft(2, '0')}",
    "morning_routine": morningRoutine,
    "evening_routine": eveningRoutine,
  };

  // For admin purposes or when you need to include user_id explicitly
  Map<String, dynamic> toJsonWithUser() => {
    if (id != null) "id": id,
    if (userId != null) "user_id": userId,
    "weight": weight,
    "height": height,
    "age": age,
    "health_issues": healthIssues,
    "bad_habits": badHabits,
    "workout_environment": trainingEnvironment,
    "work_shift": workShift,
    "wake_up_time": wakeUpTime,
    "sleep_time": sleepTime,
    "morning_routine": morningRoutine,
    "evening_routine": eveningRoutine,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };

  // From JSON constructor (when receiving from API)
  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    // Helper function to parse time string to TimeOfDay
    TimeOfDay parseTime(dynamic timeValue) {
      if (timeValue == null) return const TimeOfDay(hour: 0, minute: 0);
      
      String timeString = timeValue.toString();
      if (timeString.contains('T')) {
        // Handle full DateTime ISO string
        final dateTime = DateTime.parse(timeString);
        return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } else {
        // Handle HH:MM format
        final parts = timeString.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    return Questionnaire(
      id: json['id'],
      userId: json['user_id'],
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      age: json['age'] as int?,
      healthIssues: json['health_issues'],
      badHabits: json['bad_habits'],
      trainingEnvironment: json['workout_environment'] ?? '',
      workShift: json['work_shift'] ?? '',
      wakeUpTime: parseTime(json['wake_up_time']),
      sleepTime: parseTime(json['sleep_time']),
      morningRoutine: json['morning_routine'],
      eveningRoutine: json['evening_routine'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  // Copy with method for updates
  Questionnaire copyWith({
    int? id,
    int? userId,
    double? weight,
    double? height,
    int? age,
    String? healthIssues,
    String? badHabits,
    String? trainingEnvironment,
    String? workShift,
    TimeOfDay? wakeUpTime,
    TimeOfDay? sleepTime,
    String? morningRoutine,
    String? eveningRoutine,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Questionnaire(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      healthIssues: healthIssues ?? this.healthIssues,
      badHabits: badHabits ?? this.badHabits,
      trainingEnvironment: trainingEnvironment ?? this.trainingEnvironment,
      workShift: workShift ?? this.workShift,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      morningRoutine: morningRoutine ?? this.morningRoutine,
      eveningRoutine: eveningRoutine ?? this.eveningRoutine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}