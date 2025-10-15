// lib/models/message.dart

enum MessageType { text, image, audio }

class Message {
  final int? id;
  final int conversationId;
  final int senderId;
  final MessageType messageType;
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['message_type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'message_type': messageType.toString().split('.').last,
    'content': content,
    'file_url': fileUrl,
    'file_name': fileName,
    'file_size': fileSize,
    'is_read': isRead,
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class Conversation {
  final int? id;
  final int trainerId;
  final int clientId;
  final int? lastMessageId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for UI
  final String? clientName;      // For trainer view
  final String? trainerName;     // For client view
   final String? trainerAvatar; 
  final String? clientAvatar;
  final String? lastMessageText;
  final bool hasUnreadMessages;
  final int unreadCount;

  Conversation({
    this.id,
    required this.trainerId,
    required this.clientId,
    this.lastMessageId,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.clientName,
    this.trainerName,
    this.trainerAvatar,
    this.clientAvatar,
    this.lastMessageText,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      trainerId: json['trainer_id'],
      clientId: json['client_id'],
      lastMessageId: json['last_message_id'],
      lastMessageAt: json['last_message_at'] != null 
        ? DateTime.parse(json['last_message_at']) 
        : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      clientName: json['client_name'],
      trainerName: json['trainer_name'],
      trainerAvatar: json['trainer_avatar'],
      clientAvatar: json['client_avatar'],
      lastMessageText: json['last_message_text'],
      hasUnreadMessages: json['has_unread_messages'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'trainer_id': trainerId,
    'client_id': clientId,
    'last_message_id': lastMessageId,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // Helper method to get display name based on current user role
  String getDisplayName(int? currentUserId) {
    if (currentUserId == null) return 'Unknown';
    
    if (currentUserId == trainerId) {
      // Current user is trainer, show client name
      return clientName ?? 'Client #$clientId';
    } else if (currentUserId == clientId) {
      // Current user is client, show trainer name  
      return trainerName ?? 'Trainer';
    } else {
      // Fallback
      return 'Unknown User';
    }
  }

  // Helper method to get initials for avatar
  String getInitials(int? currentUserId) {
    final displayName = getDisplayName(currentUserId);
    final words = displayName.split(' ');
    
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    } else {
      return 'U';
    }
  }

  // Helper method to create a copy with additional UI data
  Conversation copyWithUIData({
    String? clientName,
    String? trainerName,
    String? clientAvatar,
    String? lastMessageText,
    bool? hasUnreadMessages,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      trainerId: trainerId,
      clientId: clientId,
      lastMessageId: lastMessageId,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      clientName: clientName ?? this.clientName,
      trainerName: trainerName ?? this.trainerName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}