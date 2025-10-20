// lib/models/events.dart
class Event {
  final int? id;
  final int userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String repeatType;
  final DateTime? repeatUntil;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isRepeatInstance;
  final DateTime? originalStart;

  Event({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.repeatType = 'none',
    this.repeatUntil,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isRepeatInstance,
    this.originalStart,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      allDay: json['all_day'] ?? false,
      repeatType: json['repeat_type'] ?? 'none',
      repeatUntil: json['repeat_until'] != null 
          ? DateTime.parse(json['repeat_until']) 
          : null,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      isRepeatInstance: json['is_repeat_instance'],
      originalStart: json['original_start'] != null
          ? DateTime.parse(json['original_start'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description ?? '',
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'all_day': allDay,
      'repeat_type': repeatType,
      'repeat_until': repeatUntil?.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  Event copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? repeatType,
    DateTime? repeatUntil,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      repeatType: repeatType ?? this.repeatType,
      repeatUntil: repeatUntil ?? this.repeatUntil,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isSameDay(DateTime date) {
    return startTime.year == date.year &&
        startTime.month == date.month &&
        startTime.day == date.day;
  }
}