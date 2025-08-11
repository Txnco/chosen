import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/message.dart';

class MessageController {
  static const _storage = FlutterSecureStorage();
  
  /// Get all conversations for current user (admin sees all, client sees only trainer)
  static Future<List<Conversation>> getConversations() async {
    try {
      final response = await ChosenApi.get('/conversations/');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        print('Failed to get conversations: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }
  
  /// Get messages for a specific conversation
  static Future<List<Message>> getMessages(int conversationId, {int page = 1, int limit = 50}) async {
    try {
      final response = await ChosenApi.get('/conversations/$conversationId/messages?page=$page&limit=$limit');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;
        return messages.map((json) => Message.fromJson(json)).toList();
      } else {
        print('Failed to get messages: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }
  
  /// Send a text message
  static Future<Message?> sendTextMessage(int conversationId, String content) async {
    try {
      final messageData = {
        'conversation_id': conversationId,
        'message_type': 'text',
        'content': content,
      };
      
      final response = await ChosenApi.post('/messages/', messageData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Message.fromJson(responseData);
      } else {
        print('Failed to send message: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }
  
  /// Send an image message
  static Future<Message?> sendImageMessage(int conversationId, File imageFile, {String? caption}) async {
    try {
      // First upload the image file
      final uploadResponse = await _uploadFile(imageFile, 'image');
      if (uploadResponse == null) return null;
      
      final messageData = {
        'conversation_id': conversationId,
        'message_type': 'image',
        'content': caption,
        'file_url': uploadResponse['file_url'],
        'file_name': uploadResponse['file_name'],
        'file_size': uploadResponse['file_size'],
      };
      
      final response = await ChosenApi.post('/messages/', messageData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Message.fromJson(responseData);
      } else {
        print('Failed to send image message: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending image message: $e');
      return null;
    }
  }
  
  /// Send an audio message
  static Future<Message?> sendAudioMessage(int conversationId, File audioFile) async {
    try {
      // First upload the audio file
      final uploadResponse = await _uploadFile(audioFile, 'audio');
      if (uploadResponse == null) return null;
      
      final messageData = {
        'conversation_id': conversationId,
        'message_type': 'audio',
        'file_url': uploadResponse['file_url'],
        'file_name': uploadResponse['file_name'],
        'file_size': uploadResponse['file_size'],
      };
      
      final response = await ChosenApi.post('/messages/', messageData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Message.fromJson(responseData);
      } else {
        print('Failed to send audio message: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending audio message: $e');
      return null;
    }
  }
  
  /// Upload file to server
  static Future<Map<String, dynamic>?> _uploadFile(File file, String fileType) async {
    try {
      // This would typically use multipart/form-data
      // For now, we'll simulate the response
      // In real implementation, you'd use http.MultipartRequest or dio package
      
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      
      // Simulate upload response
      final uploadResponse = {
        'file_url': 'https://example.com/uploads/$fileName',
        'file_name': fileName,
        'file_size': fileSize,
      };
      
      return uploadResponse;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  /// Mark messages as read
  static Future<bool> markMessagesAsRead(int conversationId, List<int> messageIds) async {
    try {
      final response = await ChosenApi.post('/conversations/$conversationId/mark-read', {
        'message_ids': messageIds,
      });
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
  
  /// Get unread messages count
  static Future<int> getUnreadCount() async {
    try {
      final response = await ChosenApi.get('/conversations/unread-count');
      
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
  
  /// Create or get conversation with a client (admin only)
  static Future<Conversation?> createOrGetConversation(int clientId) async {
    try {
      final response = await ChosenApi.post('/conversations/create-or-get', {
        'client_id': clientId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Conversation.fromJson(responseData);
      } else {
        print('Failed to create/get conversation: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating/getting conversation: $e');
      return null;
    }
  }
  
  /// Delete a conversation (admin only)
  static Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await ChosenApi.delete('/conversations/$conversationId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
  
  /// Clear all messages in a conversation
  static Future<bool> clearConversation(int conversationId) async {
    try {
      final response = await ChosenApi.delete('/conversations/$conversationId/messages');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error clearing conversation: $e');
      return false;
    }
  }
  
  /// Search messages
  static Future<List<Message>> searchMessages(String query, {int? conversationId}) async {
    try {
      final endpoint = conversationId != null 
        ? '/conversations/$conversationId/search?q=$query'
        : '/messages/search?q=$query';
        
      final response = await ChosenApi.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }
  
  /// Get online status of users (for real-time features)
  static Future<Map<int, bool>> getUsersOnlineStatus(List<int> userIds) async {
    try {
      final response = await ChosenApi.post('/users/online-status', {
        'user_ids': userIds,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(int.parse(key), value as bool));
      }
      return {};
    } catch (e) {
      print('Error getting online status: $e');
      return {};
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
      print('Error clearing message cache: $e');
    }
  }
}