class WeightTracking {
  final int id;
  final int userId;
  final double weight;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  WeightTracking({
    required this.id,
    required this.userId,
    required this.weight,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WeightTracking.fromJson(Map<String, dynamic> json) {
    return WeightTracking(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'weight': weight,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };
}