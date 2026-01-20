import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:renthive/admin/providers/admin_provider.dart';
import 'package:renthive/models/chat_model.dart';
import 'package:renthive/models/user_model.dart';
import 'package:renthive/models/property_model.dart';

class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatRoom> _filteredChatRooms = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChatRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChatRooms() {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredChatRooms = provider.allChatRooms;
      });
    } else {
      setState(() {
        _filteredChatRooms =
            provider.allChatRooms.where((chatRoom) {
              // Find property
              PropertyModel? property;
              if (chatRoom.propertyId != null) {
                try {
                  property = provider.allProperties.firstWhere(
                    (prop) => prop.id == chatRoom.propertyId,
                  );
                } catch (e) {
                  property = null;
                }
              }

              // Find participants
              final participantNames =
                  chatRoom.participants.map((userId) {
                    try {
                      final user = provider.allUsers.firstWhere(
                        (u) => u.id == userId,
                      );
                      return user.name.toLowerCase();
                    } catch (e) {
                      return '';
                    }
                  }).toList();

              return (property?.title.toLowerCase().contains(query) ?? false) ||
                  participantNames.any((name) => name.contains(query));
            }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (_filteredChatRooms.isEmpty && _searchController.text.isEmpty) {
          _filteredChatRooms = provider.allChatRooms;
        }

        final totalUnread = provider.allChatRooms.fold<int>(
          0,
          (sum, chat) =>
              sum + chat.unreadCount.values.fold<int>(0, (a, b) => a + b),
        );

        return Scaffold(
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search chats by property or participants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterChatRooms();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                      title: 'Total Chats',
                      count: provider.allChatRooms.length,
                      icon: Icons.chat,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'Active',
                      count:
                          provider.allChatRooms.where((c) => c.isActive).length,
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'Unread',
                      count: totalUnread,
                      icon: Icons.mark_chat_unread,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Chat rooms list
              Expanded(
                child:
                    provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredChatRooms.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No chat rooms found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => _refreshChats(provider),
                          child: ListView.builder(
                            itemCount: _filteredChatRooms.length,
                            itemBuilder: (context, index) {
                              final chatRoom = _filteredChatRooms[index];

                              // Find property
                              PropertyModel? property;
                              if (chatRoom.propertyId != null) {
                                try {
                                  property = provider.allProperties.firstWhere(
                                    (prop) => prop.id == chatRoom.propertyId,
                                  );
                                } catch (e) {
                                  property = null;
                                }
                              }

                              // Find participants
                              final participants =
                                  chatRoom.participants.map((userId) {
                                    try {
                                      return provider.allUsers.firstWhere(
                                        (u) => u.id == userId,
                                      );
                                    } catch (e) {
                                      return UserModel(
                                        id: userId,
                                        name: 'Unknown User',
                                        email: '',
                                        phone: '',
                                        userType: UserType.roomSeeker,
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      );
                                    }
                                  }).toList();

                              final totalUnreadForChat = chatRoom
                                  .unreadCount
                                  .values
                                  .fold<int>(0, (a, b) => a + b);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading:
                                      property != null &&
                                              property.images.isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              property.images.first,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stack,
                                                  ) => Container(
                                                    width: 60,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.chat,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          )
                                          : Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.chat,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  title: Text(
                                    property?.title ?? 'Chat (No Property)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Participants: ${participants.map((u) => u.name).join(', ')}',
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (chatRoom.lastMessage.isNotEmpty)
                                        Text(
                                          chatRoom.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat(
                                              'MMM dd, yyyy - HH:mm',
                                            ).format(chatRoom.lastMessageTime),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (!chatRoom.isActive) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Inactive',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (totalUnreadForChat > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '$totalUnreadForChat',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        color: Colors.blue,
                                        tooltip: 'View Details',
                                        onPressed:
                                            () => _viewChatDetails(
                                              chatRoom,
                                              property,
                                              participants,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        tooltip: 'Delete Chat',
                                        onPressed:
                                            () => _deleteChatRoom(chatRoom.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _refreshChats(provider),
            tooltip: 'Refresh Chats',
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  Future<void> _viewChatDetails(
    ChatRoom chatRoom,
    PropertyModel? property,
    List<UserModel> participants,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chat Room Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Property Info
                  if (property != null) ...[
                    if (property.images.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          property.images.first,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stack) => Container(
                                height: 120,
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${property.propertyType.displayName} • \$${property.price}/${property.priceType.displayName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                  ],

                  // Participants
                  const Text(
                    'Participants',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ...participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ParticipantCard(
                        title: 'Participant ${index + 1}',
                        user: user,
                        color: index == 0 ? Colors.blue : Colors.green,
                      ),
                    );
                  }),
                  const Divider(height: 24),

                  // Chat Stats
                  _DetailRow(
                    label: 'Created',
                    value: DateFormat(
                      'MMM dd, yyyy - HH:mm',
                    ).format(chatRoom.createdAt),
                  ),
                  _DetailRow(
                    label: 'Last Message',
                    value: DateFormat(
                      'MMM dd, yyyy - HH:mm',
                    ).format(chatRoom.lastMessageTime),
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: chatRoom.isActive ? 'Active' : 'Inactive',
                  ),
                  _DetailRow(
                    label: 'Total Unread',
                    value:
                        '${chatRoom.unreadCount.values.fold<int>(0, (a, b) => a + b)}',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteChatRoom(chatRoom.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Chat'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteChatRoom(String chatRoomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Chat Room'),
            content: const Text(
              'Are you sure you want to delete this chat room? '
              'This will also delete all messages in this chat. '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      final success = await provider.deleteChatRoom(chatRoomId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Chat room deleted successfully'
                  : 'Error deleting chat room',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _filterChatRooms();
        }
      }
    }
  }

  Future<void> _refreshChats(AdminProvider provider) async {
    await provider.refreshChatRooms();
    _filterChatRooms();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat rooms refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final String title;
  final UserModel user;
  final Color color;

  const _ParticipantCard({
    required this.title,
    required this.user,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title: ${user.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(user.email, style: const TextStyle(fontSize: 12)),
                Text(user.phone, style: const TextStyle(fontSize: 12)),
                Text(
                  user.userType.displayName,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
