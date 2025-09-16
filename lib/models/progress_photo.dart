enum PhotoAngle {
  front,
  side,
  back,
}

class ProgressPhoto {
  final int id;
  final int userId;
  final PhotoAngle angle;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ProgressPhoto({
    required this.id,
    required this.userId,
    required this.angle,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      angle: _parseAngle(json['angle']),
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  static PhotoAngle _parseAngle(dynamic angleValue) {
    if (angleValue == null) return PhotoAngle.front;
    
    String angleString = angleValue.toString().toLowerCase();
    switch (angleString) {
      case 'front':
        return PhotoAngle.front;
      case 'side':
        return PhotoAngle.side;
      case 'back':
        return PhotoAngle.back;
      default:
        return PhotoAngle.front;
    }
  }

  String get angleString {
    switch (angle) {
      case PhotoAngle.front:
        return 'front';
      case PhotoAngle.side:
        return 'side';
      case PhotoAngle.back:
        return 'back';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'angle': angleString,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };
}