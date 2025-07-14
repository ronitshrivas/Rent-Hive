import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../services/firebase_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentChatRoomId;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentChatRoomId => _currentChatRoomId;

  Future<void> loadUserChatRooms(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _chatRooms = await _firebaseService.getUserChatRooms(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load chat rooms: $e');
      _setLoading(false);
    }
  }

  Stream<List<ChatRoom>> getUserChatRoomsStream(String userId) {
    return _firebaseService.getUserChatRoomsStream(userId);
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String chatRoomId) {
    return _firebaseService.getChatMessagesStream(chatRoomId);
  }

  Future<String?> createOrGetChatRoom({
    required List<String> participants,
    String? propertyId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if chat room already exists
      String? existingChatRoomId = await _firebaseService.findExistingChatRoom(
        participants,
        propertyId: propertyId,
      );

      if (existingChatRoomId != null) {
        _setLoading(false);
        return existingChatRoomId;
      }

      // Create new chat room
      String chatRoomId = await _firebaseService.createChatRoom(
        participants,
        propertyId: propertyId,
      );

      _setLoading(false);
      return chatRoomId;
    } catch (e) {
      _setError('Failed to create chat room: $e');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final chatMessage = ChatMessage(
        id: _uuid.v4(),
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        messageType: messageType,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        metadata: metadata,
      );

      await _firebaseService.sendMessage(chatMessage);
      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      await _firebaseService.markMessagesAsRead(chatRoomId, userId);
    } catch (e) {
      _setError('Failed to mark messages as read: $e');
    }
  }

  void setCurrentChatRoom(String? chatRoomId) {
    _currentChatRoomId = chatRoomId;
    _currentMessages.clear();
    notifyListeners();
  }

  void updateCurrentMessages(List<ChatMessage> messages) {
    _currentMessages = messages;
    notifyListeners();
  }

  void addMessageToCurrentChat(ChatMessage message) {
    _currentMessages.insert(0, message);
    notifyListeners();
  }

  int getUnreadCount(String chatRoomId, String userId) {
    final chatRoom = _chatRooms.firstWhere(
      (room) => room.id == chatRoomId,
      orElse: () => ChatRoom(
        id: '',
        participants: [],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: '',
        createdAt: DateTime.now(),
      ),
    );
    
    return chatRoom.unreadCount[userId] ?? 0;
  }

  int getTotalUnreadCount(String userId) {
    int totalUnread = 0;
    for (ChatRoom room in _chatRooms) {
      totalUnread += room.unreadCount[userId] ?? 0;
    }
    return totalUnread;
  }

  String getOtherParticipantId(List<String> participants, String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}