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
      imageUrl: 'https://admin.chosen-international.com/public/uploads/progress/' + json['image_url'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
      deletedAt: json['deleted_at'] != null 
        ? DateTime.parse(json['deleted_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'angle': angle.name,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  static PhotoAngle _parseAngle(dynamic angleValue) {
    if (angleValue == null) return PhotoAngle.front;
    
    String angleStr = angleValue.toString().toLowerCase();
    switch (angleStr) {
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
}