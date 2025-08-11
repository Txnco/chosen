
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

// lib/models/conversation.dart
class Conversation {
  final int? id;
  final int trainerId;
  final int clientId;
  final int? lastMessageId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for UI
  final String? clientName;
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
}