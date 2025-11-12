import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chosen/models/message.dart';
import 'package:chosen/controllers/message_controller.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/config/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final int? currentUserId;

  const ChatScreen({
    super.key, 
    required this.conversation,
    this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserController _userController = UserController();
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isInitializing = true;
  bool _isSending = false;
  bool _showScrollButton = false;
  bool _isAtBottom = true;
  List<Message> _messages = [];
  int? _currentUserId;
  String? _currentUserProfilePicture;
  String? _error;
  int _newMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.currentUserId;
    _scrollController.addListener(_onScroll);
    _initializeChat();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final atBottom = _scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 50;
      
      if (atBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = atBottom;
          _showScrollButton = !atBottom;
          if (atBottom) {
            _newMessageCount = 0;
          }
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isLoading) {
        _loadMessagesQuietly();
      }
    });
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isInitializing = true;
        _isLoading = true;
        _error = null;
      });

      if (_currentUserId == null) {
        await _getCurrentUser();
      }
      
      await _loadMessages();
      
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize chat. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _userController.getStoredUser();
      if (user != null && mounted) {
        setState(() {
          _currentUserId = user.id;
          _currentUserProfilePicture = user.profilePicture;
        });
        print('Current user loaded: ${user.id}, profilePicture: ${user.profilePicture}');
      } else {
        print('No user found in storage');
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      if (widget.conversation.id == null) {
        throw Exception('Conversation ID is null');
      }

      print('Loading messages for thread ${widget.conversation.id}...');
      final messages = await MessageController.getMessages(widget.conversation.id!);
      print('Loaded ${messages.length} messages');
      
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages. Pull down to retry.';
        });
      }
    }
  }

  Future<void> _loadMessagesQuietly() async {
    try {
      if (widget.conversation.id == null) return;

      final messages = await MessageController.getMessages(widget.conversation.id!);
      
      if (mounted && messages.length != _messages.length) {
        final oldCount = _messages.length;
        setState(() {
          _messages = messages;
          if (!_isAtBottom) {
            _newMessageCount += messages.length - oldCount;
          }
        });
        
        // Only auto-scroll if user was already at bottom
        if (_isAtBottom) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error loading messages quietly: $e');
    }
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadMessages();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending || widget.conversation.id == null) return;

    setState(() => _isSending = true);
    
    final originalText = messageText;
    _messageController.clear();

    try {
      final sentMessage = await MessageController.sendMessage(
        widget.conversation.id!,
        originalText,
      );

      if (sentMessage != null && mounted) {
        setState(() {
          _messages.add(sentMessage);
        });
        _scrollToBottom();
      } else {
        if (mounted) {
          _messageController.text = originalText;
          _showErrorSnackBar('Failed to send message. Please try again.');
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        _messageController.text = originalText;
        _showErrorSnackBar('Error sending message: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Jučer ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          children: [
            _buildSmallAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.getDisplayName(_currentUserId),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _refreshMessages,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_error != null) _buildErrorBanner(),
              Expanded(
                child: _isInitializing 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Učitavanje poruka...',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshMessages,
                      color: theme.colorScheme.primary,
                      child: _buildMessagesList(),
                    ),
              ),
              _buildMessageInput(),
            ],
          ),
          if (_showScrollButton && _newMessageCount > 0)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _newMessageCount = 0;
                  });
                  _scrollToBottom();
                },
                backgroundColor: theme.colorScheme.primary,
                child: Badge(
                  label: Text(_newMessageCount.toString()),
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.arrow_downward,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            )
          else if (_showScrollButton)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.arrow_downward,
                  color: theme.colorScheme.onPrimary,
                ),
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
      color: Colors.red[100],
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[800], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _error = null);
              _refreshMessages();
            },
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final otherUserAvatar = _currentUserId == widget.conversation.trainerId
        ? widget.conversation.clientAvatar
        : widget.conversation.trainerAvatar;

    final avatarUrl = otherUserAvatar != null
        ? _userController.getProfilePictureUrl(otherUserAvatar)
        : null;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading avatar: $error');
                  return _buildDefaultSmallAvatar();
                },
              )
            : _buildDefaultSmallAvatar(),
      ),
    );
  }

  Widget _buildDefaultSmallAvatar() {
    final theme = Theme.of(context);
    final initials = widget.conversation.getInitials(_currentUserId);
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    final theme = Theme.of(context);
    
    print('Building messages list: ${_messages.length} messages, currentUserId: $_currentUserId');
    
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }
    
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;
        final showDateSeparator = _shouldShowDateSeparator(index);
        
        print('Message ${index}: senderId=${message.senderId}, isMe=$isMe, content="${message.content}"');
        
        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(_messages[index].createdAt),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Počnite razgovor',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pošaljite prvu poruku ${widget.conversation.getDisplayName(_currentUserId)}',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    
    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );
    
    final previousDate = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );
    
    return currentDate != previousDate;
  }

  Widget _buildDateSeparator(DateTime date) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Danas';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Jučer';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.dividerColor)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildOtherUserAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.getBubbleColor(context, isMe: isMe),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == MessageType.text)
                    Text(
                      message.content ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else if (message.messageType == MessageType.image)
                    _buildImageMessage(message, isMe)
                  else if (message.messageType == MessageType.audio)
                    _buildAudioMessage(message, isMe),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead 
                            ? Colors.blue 
                            : theme.colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildCurrentUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherUserAvatar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final otherUserAvatar = _currentUserId == widget.conversation.trainerId
        ? widget.conversation.clientAvatar
        : widget.conversation.trainerAvatar;

    final avatarUrl = otherUserAvatar != null
        ? _userController.getProfilePictureUrl(otherUserAvatar)
        : null;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultOtherUserAvatar();
                },
              )
            : _buildDefaultOtherUserAvatar(),
      ),
    );
  }

  Widget _buildDefaultOtherUserAvatar() {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
      child: Center(
        child: Text(
          widget.conversation.getInitials(_currentUserId),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserAvatar() {
    final theme = Theme.of(context);

    final currentUserAvatar = _currentUserId == widget.conversation.trainerId
        ? widget.conversation.trainerAvatar
        : widget.conversation.clientAvatar;

    final avatarUrl = currentUserAvatar != null
        ? _userController.getProfilePictureUrl(currentUserAvatar)
        : null;

    String initials = 'U';
    if (_currentUserId == widget.conversation.trainerId) {
      final trainerName = widget.conversation.trainerName;
      if (trainerName != null) {
        final words = trainerName.split(' ');
        if (words.length >= 2) {
          initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
        } else if (words.isNotEmpty) {
          initials = words[0][0].toUpperCase();
        }
      } else {
        initials = 'T';
      }
    } else if (_currentUserId == widget.conversation.clientId) {
      final clientName = widget.conversation.clientName;
      if (clientName != null) {
        final words = clientName.split(' ');
        if (words.length >= 2) {
          initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
        } else if (words.isNotEmpty) {
          initials = words[0][0].toUpperCase();
        }
      } else {
        initials = 'C';
      }
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading current user avatar: $error');
                  return _buildDefaultCurrentUserAvatar(initials);
                },
              )
            : _buildDefaultCurrentUserAvatar(initials),
      ),
    );
  }

  Widget _buildDefaultCurrentUserAvatar(String initials) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.primary,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(Message message, bool isMe) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;


    final backgroundColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            // Image takes up to 70% of screen width, keeps aspect ratio
            maxWidth: MediaQuery.of(context).size.width * 0.7,
            maxHeight: 300,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: message.fileUrl != null
              ? AspectRatio(
                  aspectRatio: 16 / 9, // Safe default aspect ratio
                  child: Image.network(
                    message.fileUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
        ),
        if (message.content?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            message.content!,
            style: TextStyle(
              color: isMe
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildAudioMessage(Message message, bool isMe) {
    final theme = Theme.of(context);
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_filled,
            color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            size: 32,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: (isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)
                      .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.fileName ?? 'Audio',
                  style: TextStyle(
                    color: isMe 
                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _showAttachmentOptions();
              },
              icon: Icon(Icons.add, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Napišite poruku...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5)
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    )
                  : Icon(Icons.send, color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pošaljite datoteku',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_camera,
                  label: 'Kamera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camera feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Galerija',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gallery feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.mic,
                  label: 'Audio',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio recording coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}