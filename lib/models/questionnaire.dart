class Questionnaire {
  final int? id;           // Optional for creation, required for updates
  final int? userId;       // Optional - handled by backend via token
  final double weight;
  final double height;
  final int age;
  final String healthIssues;
  final String badHabits;
  final String trainingEnvironment;
  final String workShift;
  final DateTime wakeUpTime;  
  final DateTime sleepTime;    
  final String morningRoutine;
  final String eveningRoutine;
  final DateTime createdAt;
  final DateTime updatedAt;

  Questionnaire({
    this.id,               // Optional
    this.userId,           // Optional
    required this.weight,
    required this.height,
    required this.age,
    required this.healthIssues,
    required this.badHabits,
    required this.trainingEnvironment,
    required this.workShift,
    required this.wakeUpTime,
    required this.sleepTime,
    required this.morningRoutine,
    required this.eveningRoutine,
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
    "wake_up_time": wakeUpTime.toIso8601String(),
    "sleep_time": sleepTime.toIso8601String(),
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
    "wake_up_time": wakeUpTime.toIso8601String(),
    "sleep_time": sleepTime.toIso8601String(),
    "morning_routine": morningRoutine,
    "evening_routine": eveningRoutine,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };

  // From JSON constructor (when receiving from API)
  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      id: json['id'],
      userId: json['user_id'],
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      age: json['age'],
      healthIssues: json['health_issues'] ?? '',
      badHabits: json['bad_habits'] ?? '',
      trainingEnvironment: json['workout_environment'] ?? '',
      workShift: json['work_shift'] ?? '',
      wakeUpTime: DateTime.parse(json['wake_up_time']),
      sleepTime: DateTime.parse(json['sleep_time']),
      morningRoutine: json['morning_routine'] ?? '',
      eveningRoutine: json['evening_routine'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
    DateTime? wakeUpTime,
    DateTime? sleepTime,
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