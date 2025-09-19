// lib/models/water_intake.dart
class WaterIntake {
  final int? id;
  final int? userId;
  final int waterIntake; // in ml (matches API field name)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  WaterIntake({
    this.id,
    this.userId,
    required this.waterIntake,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WaterIntake.fromJson(Map<String, dynamic> json) {
    return WaterIntake(
      id: json['id'],
      userId: json['user_id'],
      waterIntake: json['water_intake'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    'water_intake': waterIntake,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };

  // Helper getter for compatibility with existing UI code
  double get amount => waterIntake.toDouble();
  DateTime get timestamp => createdAt;
  String? get notes => null; // API doesn't support notes yet
}

// lib/models/water_goal.dart
class WaterGoal {
  final int? id;
  final int? userId;
  final int dailyMl; // in ml (matches API field name)
  final DateTime createdAt;
  final DateTime updatedAt;
  
  WaterGoal({
    this.id,
    this.userId,
    required this.dailyMl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaterGoal.fromJson(Map<String, dynamic> json) {
    return WaterGoal(
      id: json['id'],
      userId: json['user_id'],
      dailyMl: json['daily_ml'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    'daily_ml': dailyMl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // Helper getter for compatibility with existing UI code
  double get dailyGoal => dailyMl.toDouble();
  DateTime get calculatedAt => createdAt;
}

// lib/models/water_daily_stats.dart
class WaterDailyStats {
  final String date;
  final int totalIntakeMl;
  final int goalMl;
  final double progressPercentage;
  final bool goalReached;
  final int entryCount;
  final int remainingMl;

  WaterDailyStats({
    required this.date,
    required this.totalIntakeMl,
    required this.goalMl,
    required this.progressPercentage,
    required this.goalReached,
    required this.entryCount,
    required this.remainingMl,
  });

  factory WaterDailyStats.fromJson(Map<String, dynamic> json) {
    return WaterDailyStats(
      date: json['date'],
      totalIntakeMl: json['total_intake_ml'],
      goalMl: json['goal_ml'],
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      goalReached: json['goal_reached'],
      entryCount: json['entry_count'],
      remainingMl: json['remaining_ml'],
    );
  }

  // Helper getters for compatibility with existing UI code
  double get totalIntake => totalIntakeMl.toDouble();
  double get goalAmount => goalMl.toDouble();
  int get numberOfEntries => entryCount;
}

// lib/models/water_weekly_stats.dart
class WaterWeeklyStats {
  final String weekStart;
  final String weekEnd;
  final int totalIntakeMl;
  final int weekGoalMl;
  final int dailyGoalMl;
  final double progressPercentage;
  final int daysGoalReached;
  final List<WaterDailyBreakdown> dailyBreakdown;

  WaterWeeklyStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalIntakeMl,
    required this.weekGoalMl,
    required this.dailyGoalMl,
    required this.progressPercentage,
    required this.daysGoalReached,
    required this.dailyBreakdown,
  });

  factory WaterWeeklyStats.fromJson(Map<String, dynamic> json) {
    return WaterWeeklyStats(
      weekStart: json['week_start'],
      weekEnd: json['week_end'],
      totalIntakeMl: json['total_intake_ml'],
      weekGoalMl: json['week_goal_ml'],
      dailyGoalMl: json['daily_goal_ml'],
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      daysGoalReached: json['days_goal_reached'],
      dailyBreakdown: (json['daily_breakdown'] as List)
          .map((e) => WaterDailyBreakdown.fromJson(e))
          .toList(),
    );
  }
}

class WaterDailyBreakdown {
  final String date;
  final int intakeMl;
  final int entryCount;
  final bool goalReached;

  WaterDailyBreakdown({
    required this.date,
    required this.intakeMl,
    required this.entryCount,
    required this.goalReached,
  });

  factory WaterDailyBreakdown.fromJson(Map<String, dynamic> json) {
    return WaterDailyBreakdown(
      date: json['date'],
      intakeMl: json['intake_ml'],
      entryCount: json['entry_count'],
      goalReached: json['goal_reached'],
    );
  }
}