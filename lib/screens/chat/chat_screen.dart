import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String? propertyId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    this.propertyId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  void _markMessagesAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      chatProvider.markMessagesAsRead(widget.chatRoomId, authProvider.user!.id);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Messages List
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: chatProvider.getChatMessagesStream(widget.chatRoomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.errorColor),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return _buildEmptyMessages();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == user.id;
                        final showTimestamp = _shouldShowTimestamp(messages, index);
                        
                        return Column(
                          children: [
                            if (showTimestamp) _buildTimestamp(message.timestamp),
                            MessageBubble(
                              message: message,
                              isMe: isMe,
                              showAvatar: _shouldShowAvatar(messages, index, isMe),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Message Input
              _buildMessageInput(user.id, chatProvider),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Owner', // TODO: Get actual user name
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online', // TODO: Get actual online status
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.successColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Voice call
          },
          icon: const Icon(Icons.phone_outlined),
        ),
        IconButton(
          onPressed: () {
            // Video call
          },
          icon: const Icon(Icons.videocam_outlined),
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_property',
              child: Row(
                children: [
                  Icon(Icons.home_outlined),
                  SizedBox(width: 8),
                  Text('View Property'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block_user',
              child: Row(
                children: [
                  Icon(Icons.block_outlined),
                  SizedBox(width: 8),
                  Text('Block User'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report_outlined),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            // Handle menu actions
          },
        ),
      ],
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Send a message to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.borderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatTimestamp(timestamp),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMessageInput(String userId, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: () {
                _showAttachmentOptions();
              },
              icon: const Icon(
                Icons.add_rounded,
                color: AppColors.primaryColor,
              ),
            ),
            
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendMessage(userId, chatProvider, text.trim());
                    }
                  },
                ),
              ),
            ),
            
            // Send button
            IconButton(
              onPressed: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _sendMessage(userId, chatProvider, text);
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  'Camera',
                  Icons.camera_alt_rounded,
                  AppColors.primaryColor,
                  () {
                    Navigator.pop(context);
                    // Open camera
                  },
                ),
                _buildAttachmentOption(
                  'Gallery',
                  Icons.photo_library_rounded,
                  AppColors.secondaryColor,
                  () {
                    Navigator.pop(context);
                    // Open gallery
                  },
                ),
                _buildAttachmentOption(
                  'Location',
                  Icons.location_on_rounded,
                  AppColors.successColor,
                  () {
                    Navigator.pop(context);
                    // Share location
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(
    String userId,
    ChatProvider chatProvider,
    String message,
  ) async {
    _messageController.clear();
    
    final success = await chatProvider.sendMessage(
      chatRoomId: widget.chatRoomId,
      senderId: userId,
      receiverId: widget.otherUserId,
      message: message,
    );

    if (success) {
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  bool _shouldShowTimestamp(List<ChatMessage> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    final timeDiff = currentMessage.timestamp.difference(nextMessage.timestamp);
    return timeDiff.inMinutes > 30;
  }

  bool _shouldShowAvatar(List<ChatMessage> messages, int index, bool isMe) {
    if (isMe) return false;
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    return currentMessage.senderId != previousMessage.senderId;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays == 0) {
      return timeago.format(timestamp);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          if (!isMe && !showAvatar)
            const SizedBox(width: 32),
          
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 60 : 0,
                right: isMe ? 0 : 60,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryColor : AppColors.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe 
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead 
                              ? Icons.done_all_rounded 
                              : Icons.done_rounded,
                          size: 12,
                          color: message.isRead 
                              ? AppColors.successColor
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}