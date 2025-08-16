// lib/screens/messaging/messaging_screen.dart
import 'package:flutter/material.dart';
import 'package:chosen/models/message.dart';
import 'package:chosen/screens/messaging/chat_screen.dart';
import 'package:chosen/controllers/message_controller.dart';
import 'package:chosen/controllers/user_controller.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Conversation> _conversations = [];
  String? _error;
  int? _currentUserId; // ✅ Added this

  @override
  void initState() {
    super.initState();
    _initializeMessaging(); // ✅ Changed this
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Added this method
  Future<void> _initializeMessaging() async {
    await _getCurrentUser();
    await _loadConversations();
  }

  // ✅ Added this method
  Future<void> _getCurrentUser() async {
    try {
      final userController = UserController();
      final user = await userController.getStoredUser();
      if (user != null) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await MessageController.getConversations();
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
      
      // Cache conversations for offline access
      await MessageController.cacheConversations(conversations);
    } catch (e) {
      print('Error loading conversations: $e');
      
      // Try to load from cache if API fails
      try {
        final cachedConversations = await MessageController.getCachedConversations();
        if (mounted) {
          setState(() {
            _conversations = cachedConversations;
            _isLoading = false;
            _error = 'Using offline data. Pull to refresh.';
          });
        }
      } catch (cacheError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Failed to load conversations. Please try again.';
          });
        }
      }
    }
  }

  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((conversation) =>
      // ✅ Fixed this - use role-based display name
      conversation.getDisplayName(_currentUserId).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Poruke',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null) _buildErrorBanner(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : RefreshIndicator(
                  onRefresh: _refreshConversations,
                  color: Colors.black,
                  child: _buildConversationsList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[800], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _error = null);
              _refreshConversations();
            },
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          // ✅ Fixed hint text
          hintText: _currentUserId != null && _conversations.isNotEmpty && _currentUserId == _conversations.first.trainerId 
            ? 'Pretražite klijente...' 
            : 'Pretražite...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    final conversations = _filteredConversations;
    
    if (conversations.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const AlwaysScrollableScrollPhysics(), // For pull-to-refresh
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
              ? 'Nema rezultata pretrage' 
              : 'Nema poruka',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
              ? 'Pokušajte sa drugim terminom'
              : 'Kada pošaljete poruku, pojaviće se ovdje',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshConversations,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Osvježi',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          // Navigate to chat screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversation: conversation),
            ),
          );
          
          // Refresh conversations when returning from chat (in case of new messages)
          if (result == true || result == null) {
            _refreshConversations();
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: _buildAvatar(conversation),
        title: Row(
          children: [
            Expanded(
              child: Text(
                // ✅ Fixed this - use role-based display name
                conversation.getDisplayName(_currentUserId),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.hasUnreadMessages)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              conversation.lastMessageText ?? 'No messages yet',
              style: TextStyle(
                fontSize: 14,
                color: conversation.hasUnreadMessages 
                  ? Colors.black 
                  : Colors.grey[600],
                fontWeight: conversation.hasUnreadMessages 
                  ? FontWeight.w500 
                  : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(conversation.lastMessageAt ?? conversation.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: conversation.hasUnreadMessages
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildAvatar(Conversation conversation) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: conversation.clientAvatar != null
        ? ClipOval(
            child: Image.network(
              conversation.clientAvatar!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(conversation),
            ),
          )
        : _buildDefaultAvatar(conversation),
    );
  }

  Widget _buildDefaultAvatar(Conversation conversation) {
    // ✅ Fixed this - use role-based initials
    final initials = conversation.getInitials(_currentUserId);
    
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}