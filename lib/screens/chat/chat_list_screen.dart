import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_overlay.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatRooms();
    });
  }

  void _loadChatRooms() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      chatProvider.loadUserChatRooms(authProvider.user!.id);
    }
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
          appBar: AppBar(
            title: const Text('Messages'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () {
                  // Navigate to search users
                },
                icon: const Icon(Icons.person_add_outlined),
              ),
            ],
          ),
          body: LoadingOverlay(
            isLoading: chatProvider.isLoading,
            child: StreamBuilder<List<ChatRoom>>(
              stream: chatProvider.getUserChatRoomsStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chats: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.errorColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final chatRooms = snapshot.data ?? [];

                if (chatRooms.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadChatRooms();
                  },
                  color: AppColors.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatRooms.length,
                    itemBuilder: (context, index) {
                      final chatRoom = chatRooms[index];
                      final otherUserId = chatProvider.getOtherParticipantId(
                        chatRoom.participants,
                        user.id,
                      );
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatListTile(
                          chatRoom: chatRoom,
                          currentUserId: user.id,
                          otherUserId: otherUserId,
                          onTap: () => _navigateToChat(chatRoom, otherUserId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Start chatting with property owners or\ntenants by viewing their properties',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to property search
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.search_rounded),
              label: const Text('Explore Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(ChatRoom chatRoom, String otherUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatRoom.id,
          otherUserId: otherUserId,
          propertyId: chatRoom.propertyId,
        ),
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final String otherUserId;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.otherUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;
    final isUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: FutureBuilder<UserModel?>(
                    future: _getUserById(otherUserId),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      if (user?.profileImage != null) {
                        return ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user!.profileImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => _buildDefaultAvatar(user.name),
                          ),
                        );
                      }
                      return _buildDefaultAvatar(user?.name ?? '');
                    },
                  ),
                ),
                
                // Online status indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FutureBuilder<UserModel?>(
                          future: _getUserById(otherUserId),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            return Text(
                              user?.name ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      
                      Text(
                        timeago.format(chatRoom.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? AppColors.primaryColor : AppColors.textSecondary,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Last Message
                  Row(
                    children: [
                      // Sender indicator
                      if (chatRoom.lastMessageSenderId == currentUserId)
                        const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                      if (chatRoom.lastMessageSenderId == currentUserId)
                        const SizedBox(width: 4),
                      
                      // Message text
                      Expanded(
                        child: Text(
                          _getDisplayMessage(chatRoom.lastMessage),
                          style: TextStyle(
                            fontSize: 14,
                            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Unread count badge
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Icon(
      Icons.person_rounded,
      size: 30,
      color: AppColors.primaryColor,
    );
  }

  String _getDisplayMessage(String message) {
    if (message.isEmpty) return 'No messages yet';
    if (message.startsWith('🏠')) return '📍 Property shared';
    if (message.startsWith('📷')) return '📷 Photo';
    if (message.startsWith('🎵')) return '🎵 Voice message';
    return message;
  }

  Future<UserModel?> _getUserById(String userId) async {
    // TODO: Implement user fetching from Firebase
    // This is a placeholder - you would implement this using your FirebaseService
    return null;
  }
}