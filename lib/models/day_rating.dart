class DayRating {
  final int id;
  final int userId;
  final int? score;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DayRating({
    required this.id,
    required this.userId,
    this.score,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DayRating.fromJson(Map<String, dynamic> json) {
    return DayRating(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      score: json['score'],
      note: json['note'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'score': score,
    'note': note,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}