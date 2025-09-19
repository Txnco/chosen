class WeightTracking {
  final int id;
  final int userId;
  final double weight;
  final DateTime? date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  WeightTracking({
    required this.id,
    required this.userId,
    required this.weight,
    this.date,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WeightTracking.fromJson(Map<String, dynamic> json) {
    double parseWeight(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }
    return WeightTracking(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      weight: parseWeight(json['weight']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'weight': weight,
    'date': date?.toIso8601String().substring(0, 10), // Format as YYYY-MM-DD
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}