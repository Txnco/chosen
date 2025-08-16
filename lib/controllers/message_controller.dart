// lib/controllers/message_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/message.dart';

class MessageController {
  static const _storage = FlutterSecureStorage();
  
  /// Get all threads for current user
  /// Backend API: GET /chat/threads
  static Future<List<Conversation>> getConversations() async {
    try {
      final response = await ChosenApi.get('/chat/threads');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        List<Conversation> conversations = [];
        
        for (var json in data) {
          // Map backend response to frontend Conversation model
          final conversation = Conversation.fromJson({
            'id': json['id'],
            'trainer_id': json['trainer_id'],
            'client_id': json['client_id'],
            'last_message_id': null,
            'last_message_at': json['last_message_at'],
            'created_at': json['created_at'],
            'updated_at': json['updated_at'],
            // Handle both client and trainer views
            'client_name': json['client_name'], // For trainer view
            'trainer_name': json['trainer_name'], // For client view
            'client_avatar': null,
            'last_message_text': json['last_message'], // ✅ Fixed: backend sends 'last_message'
            'has_unread_messages': json['has_unread_messages'] ?? false,
            'unread_count': json['unread_count'] ?? 0,
          });
          
          conversations.add(conversation);
        }
        
        return conversations;
      } else {
        print('Failed to get conversations: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }
  
  /// Send a message 
  /// Backend API: POST /chat/message
  static Future<Message?> sendMessage(int threadId, String body) async {
    try {
      final response = await ChosenApi.post('/chat/message', {
        'thread_id': threadId,
        'body': body,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // ✅ Fixed: Map backend fields to frontend Message model
        return Message.fromJson({
          'id': responseData['id'],
          'conversation_id': responseData['thread_id'], // ✅ backend: thread_id -> frontend: conversation_id
          'sender_id': responseData['user_id'],         // ✅ backend: user_id -> frontend: sender_id
          'message_type': responseData['image_url'] != null ? 'image' : 'text',
          'content': responseData['body'],              // ✅ backend: body -> frontend: content
          'file_url': responseData['image_url'],
          'file_name': null,
          'file_size': null,
          'is_read': responseData['read_at'] != null,   // ✅ backend: read_at -> frontend: is_read
          'read_at': responseData['read_at'],
          'created_at': responseData['created_at'],
          'updated_at': responseData['updated_at'],
        });
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }
  
  /// Get messages for a conversation
  /// Backend API: GET /chat/threads/{thread_id}/messages
  static Future<List<Message>> getMessages(int threadId, {int page = 1, int limit = 50}) async {
    try {
      final response = await ChosenApi.get('/chat/threads/$threadId/messages?page=$page&limit=$limit');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List? ?? [];
        
        print('📨 Raw backend response: $data'); // Debug log
        
        return messages.map((json) {
          print('📨 Processing message: $json'); // Debug log
          
          // ✅ Fixed: Map backend fields to frontend Message model correctly
          return Message.fromJson({
            'id': json['id'],
            'conversation_id': json['thread_id'],     // ✅ backend: thread_id -> frontend: conversation_id
            'sender_id': json['user_id'],             // ✅ backend: user_id -> frontend: sender_id
            'message_type': json['image_url'] != null && json['image_url'].toString().isNotEmpty ? 'image' : 'text',
            'content': json['body'],                  // ✅ backend: body -> frontend: content
            'file_url': json['image_url'],
            'file_name': null,
            'file_size': null,
            'is_read': json['read_at'] != null,       // ✅ backend: read_at -> frontend: is_read
            'read_at': json['read_at'],
            'created_at': json['created_at'],
            'updated_at': json['updated_at'],
          });
        }).toList();
      } else {
        print('Failed to get messages: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }
  
  /// Mark messages as read
  /// Backend API: POST /chat/threads/{thread_id}/mark-read
  static Future<bool> markMessagesAsRead(int threadId, List<int> messageIds) async {
    try {
      final response = await ChosenApi.post('/chat/threads/$threadId/mark-read', {
        'message_ids': messageIds,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
  
  /// Get total unread count
  /// Backend API: GET /chat/unread-count
  static Future<int> getUnreadCount() async {
    try {
      final response = await ChosenApi.get('/chat/unread-count');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
  
  /// Send an image message (placeholder - needs file upload implementation)
  static Future<Message?> sendImageMessage(int threadId, File imageFile, {String? caption}) async {
    try {
      // First upload the file
      final uploadResponse = await _uploadFile(imageFile);
      if (uploadResponse == null) return null;
      
      // Then send message with image URL
      // Note: Backend doesn't support image URLs in messages yet
      // This is a placeholder implementation
      return await sendMessage(threadId, caption ?? '[Image]');
    } catch (e) {
      print('Error sending image message: $e');
      return null;
    }
  }
  
  /// Upload file to server
  /// Backend API: POST /chat/upload
  static Future<Map<String, dynamic>?> _uploadFile(File file) async {
    try {
      // This would need proper multipart form data implementation
      // For now, this is a placeholder
      
      // You'll need to implement multipart upload using packages like:
      // - dio (for easier file uploads)
      // - http with MultipartRequest
      
      // Placeholder response
      return {
        'file_url': 'https://example.com/uploads/placeholder.jpg',
        'file_name': file.path.split('/').last,
        'file_size': await file.length(),
      };
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  /// Cache conversations locally
  static Future<void> cacheConversations(List<Conversation> conversations) async {
    try {
      final conversationsJson = conversations.map((c) => c.toJson()).toList();
      await _storage.write(
        key: 'cached_conversations',
        value: jsonEncode(conversationsJson),
      );
    } catch (e) {
      print('Error caching conversations: $e');
    }
  }
  
  /// Get cached conversations
  static Future<List<Conversation>> getCachedConversations() async {
    try {
      final cached = await _storage.read(key: 'cached_conversations');
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((json) => Conversation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting cached conversations: $e');
      return [];
    }
  }
  
  /// Clear cached data
  static Future<void> clearCache() async {
    try {
      await _storage.delete(key: 'cached_conversations');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}