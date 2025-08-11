// lib/models/water_intake.dart
class WaterIntake {
  final int? id;
  final int? userId;
  final double amount; // in ml
  final DateTime timestamp;
  final String? notes;

  WaterIntake({
    this.id,
    this.userId,
    required this.amount,
    required this.timestamp,
    this.notes,
  });

  factory WaterIntake.fromJson(Map<String, dynamic> json) {
    return WaterIntake(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'notes': notes,
  };
}

// lib/models/water_goal.dart
class WaterGoal {
  final int? userId;
  final double dailyGoal; // in ml
  final DateTime calculatedAt;
  
  WaterGoal({
    this.userId,
    required this.dailyGoal,
    required this.calculatedAt,
  });

  factory WaterGoal.fromJson(Map<String, dynamic> json) {
    return WaterGoal(
      userId: json['user_id'],
      dailyGoal: (json['daily_goal'] as num).toDouble(),
      calculatedAt: DateTime.parse(json['calculated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (userId != null) 'user_id': userId,
    'daily_goal': dailyGoal,
    'calculated_at': calculatedAt.toIso8601String(),
  };

  // Calculate water goal based on questionnaire data
  static double calculateWaterGoal({
    required double weightKg,
    required double heightCm,
    required int age,
    String activityLevel = 'moderate',
  }) {
    // Base calculation: 35ml per kg of body weight
    double baseAmount = weightKg * 35;
    
    // Adjust for age (older people need slightly less)
    if (age > 65) {
      baseAmount *= 0.9;
    } else if (age < 30) {
      baseAmount *= 1.1;
    }
    
    // Adjust for activity level
    switch (activityLevel.toLowerCase()) {
      case 'low':
        baseAmount *= 0.9;
        break;
      case 'high':
        baseAmount *= 1.3;
        break;
      case 'moderate':
      default:
        baseAmount *= 1.0;
        break;
    }
    
    // Round to nearest 250ml
    return ((baseAmount / 250).round() * 250).toDouble();
  }
}

// lib/models/water_stats.dart
class WaterStats {
  final DateTime date;
  final double totalIntake;
  final double goalAmount;
  final int numberOfEntries;
  final List<WaterIntake> entries;

  WaterStats({
    required this.date,
    required this.totalIntake,
    required this.goalAmount,
    required this.numberOfEntries,
    required this.entries,
  });

  double get progressPercentage => 
    goalAmount > 0 ? (totalIntake / goalAmount).clamp(0.0, 1.0) : 0.0;

  bool get goalReached => totalIntake >= goalAmount;

  factory WaterStats.fromJson(Map<String, dynamic> json) {
    return WaterStats(
      date: DateTime.parse(json['date']),
      totalIntake: (json['total_intake'] as num).toDouble(),
      goalAmount: (json['goal_amount'] as num).toDouble(),
      numberOfEntries: json['number_of_entries'],
      entries: (json['entries'] as List)
          .map((e) => WaterIntake.fromJson(e))
          .toList(),
    );
  }
}