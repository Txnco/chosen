// lib/controllers/message_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/message.dart';
import 'package:http/http.dart' as http;

class MessageController {
  static const _storage = FlutterSecureStorage();
  
  /// Get all threads for current user
  /// Backend API: GET /chat/threads
  /// 
  /// Returns list of conversations with proper field mapping:
  /// - Backend returns client_name for trainers, trainer_name for clients
  /// - Backend auto-creates thread if client doesn't have one
  static Future<List<Conversation>> getConversations() async {
    try {
      final response = await ChosenApi.get('/chat/threads');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) {
          return Conversation.fromJson({
            'id': json['id'],
            'trainer_id': json['trainer_id'],
            'client_id': json['client_id'],
            'last_message_id': null,
            'last_message_at': json['last_message_at'],
            'created_at': json['created_at'],
            'updated_at': json['updated_at'],
            // Backend returns either client_name (trainer view) or trainer_name (client view)
            'client_name': json['client_name'],
            'trainer_name': json['trainer_name'],
            'client_avatar': json['client_avatar'],
            'trainer_avatar': json['trainer_avatar'],
            'last_message_text': json['last_message'],
            'has_unread_messages': json['has_unread_messages'] ?? false,
            'unread_count': json['unread_count'] ?? 0,
          });
        }).toList();
      } else {
        print('Failed to get conversations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }
  
  /// Send a text message
  /// Backend API: POST /chat/message
  /// 
  /// Params:
  /// - threadId: The thread ID to send message to
  /// - body: The message text content
  /// - imageUrl: Optional filename of uploaded image (not full path)
  static Future<Message?> sendMessage(
    int threadId, 
    String body, 
    {String? imageUrl}
  ) async {
    try {
      final response = await ChosenApi.post('/chat/message', {
        'thread_id': threadId,
        'body': body,
        if (imageUrl != null) 'image_url': imageUrl, // Just filename, not full path
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _mapBackendMessageToModel(data, threadId);
      } else {
        print('Failed to send message: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }
  
  /// Get messages for a conversation with pagination
  /// Backend API: GET /chat/threads/{thread_id}/messages
  /// 
  /// Backend auto-marks messages as read when this endpoint is called
  /// Returns: List of messages in ascending order (oldest first)
  static Future<List<Message>> getMessages(
    int threadId, 
    {int page = 1, int limit = 50}
  ) async {
    try {
      final response = await ChosenApi.get(
        '/chat/threads/$threadId/messages?page=$page&limit=$limit'
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List? ?? [];
        
        return messages.map((json) {
          return _mapBackendMessageToModel(json, threadId);
        }).toList();
      } else {
        print('Failed to get messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }
  
  /// Mark specific messages as read
  /// Backend API: POST /chat/threads/{thread_id}/mark-read
  /// 
  /// Note: Backend automatically marks messages as read when getMessages is called
  /// This method is for explicit marking if needed
  static Future<bool> markMessagesAsRead(int threadId, List<int> messageIds) async {
    try {
      final response = await ChosenApi.post(
        '/chat/threads/$threadId/mark-read',
        {'message_ids': messageIds},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
  
  /// Get total unread message count
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
  
  /// Upload a file for messaging
  /// Backend API: POST /chat/upload
  /// 
  /// Returns the filename to be used in sendMessage's imageUrl parameter
  /// Files are organized by thread: /uploads/chat/{thread_id}/{filename}
  static Future<Map<String, dynamic>?> uploadFile(
    int threadId,
    File file,
  ) async {
    try {
      final uri = Uri.parse('${ChosenApi.baseUrl}/chat/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth token
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add form fields and file
      request.fields['thread_id'] = threadId.toString();
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path)
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'file_name': data['file_name'], // Store ONLY this in message
          'file_url': data['file_url'],   // Full URL for immediate display
          'original_name': data['original_name'],
          'file_size': data['file_size'],
          'content_type': data['content_type'],
        };
      } else {
        print('Failed to upload file: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  /// Send an image message
  /// 1. Upload the image file
  /// 2. Send message with the returned filename
  static Future<Message?> sendImageMessage(
    int threadId,
    File imageFile,
    {String? caption}
  ) async {
    try {
      // Upload image first
      final uploadResult = await uploadFile(threadId, imageFile);
      if (uploadResult == null) {
        print('Failed to upload image');
        return null;
      }
      
      // Send message with filename
      return await sendMessage(
        threadId,
        caption ?? '',
        imageUrl: uploadResult['file_name'], // Just the filename
      );
    } catch (e) {
      print('Error sending image message: $e');
      return null;
    }
  }
  
  /// Get list of clients without threads (Trainer only)
  /// Backend API: GET /chat/available-clients
  static Future<List<Map<String, dynamic>>> getAvailableClients({String? search}) async {
    try {
      final queryParam = search != null ? '?search=$search' : '';
      final response = await ChosenApi.get('/chat/available-clients$queryParam');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        print('Failed to get available clients: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting available clients: $e');
      return [];
    }
  }
  
  /// Create a new thread with a client (Trainer only)
  /// Backend API: POST /chat/threads
  static Future<Conversation?> createThread(int clientId) async {
    try {
      final response = await ChosenApi.post('/chat/threads', {
        'client_id': clientId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Conversation.fromJson({
          'id': data['id'],
          'trainer_id': data['trainer_id'],
          'client_id': data['client_id'],
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
          'client_name': data['client_name'],
          'trainer_name': null,
          'client_avatar': null,
          'trainer_avatar': null,
          'last_message_text': data['last_message'],
          'last_message_at': data['last_message_at'],
          'has_unread_messages': data['has_unread_messages'] ?? false,
          'unread_count': data['unread_count'] ?? 0,
        });
      } else {
        print('Failed to create thread: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating thread: $e');
      return null;
    }
  }
  
  /// Delete a thread (Trainer only)
  /// Backend API: DELETE /chat/threads/{thread_id}
  static Future<bool> deleteThread(int threadId) async {
    try {
      final response = await ChosenApi.delete('/chat/threads/$threadId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting thread: $e');
      return false;
    }
  }
  
  // ============================================================================
  // CACHING METHODS (for offline support)
  // ============================================================================
  
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
  
  /// Cache messages for a specific thread
  static Future<void> cacheMessages(int threadId, List<Message> messages) async {
    try {
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await _storage.write(
        key: 'cached_messages_$threadId',
        value: jsonEncode(messagesJson),
      );
    } catch (e) {
      print('Error caching messages: $e');
    }
  }
  
  /// Get cached messages for a specific thread
  static Future<List<Message>> getCachedMessages(int threadId) async {
    try {
      final cached = await _storage.read(key: 'cached_messages_$threadId');
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting cached messages: $e');
      return [];
    }
  }
  
  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      await _storage.delete(key: 'cached_conversations');
      
      // Clear all cached messages
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('cached_messages_')) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
  
  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================
  
  /// Map backend message fields to frontend Message model
  /// 
  /// Backend fields -> Frontend fields:
  /// - thread_id -> conversation_id
  /// - user_id -> sender_id
  /// - body -> content
  /// - image_url (filename) -> file_url (full path constructed)
  static Message _mapBackendMessageToModel(Map<String, dynamic> json, int threadId) {
    // Construct full image URL if filename exists
    String? fullImageUrl;
    if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      fullImageUrl = '${ChosenApi.baseUrl}/uploads/chat/$threadId/${json['image_url']}';
    }
    
    // Determine message type
    MessageType messageType = MessageType.text;
    if (fullImageUrl != null) {
      messageType = MessageType.image;
    }
    
    return Message.fromJson({
      'id': json['id'],
      'conversation_id': json['thread_id'],
      'sender_id': json['user_id'],
      'message_type': messageType.toString().split('.').last,
      'content': json['body'],
      'file_url': fullImageUrl,
      'file_name': json['image_url'], // Store original filename
      'file_size': null,
      'is_read': json['read_at'] != null,
      'read_at': json['read_at'],
      'created_at': json['created_at'],
      'updated_at': json['updated_at'],
    });
  }
}