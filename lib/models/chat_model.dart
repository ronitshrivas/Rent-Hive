import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String? propertyId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.participants,
    this.propertyId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCount = const {},
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'propertyId': propertyId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      propertyId: map['propertyId'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(
        map['lastMessageTime'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: map['isActive'] ?? true,
    );
  }

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ChatRoom.fromMap(data);
  }

  ChatRoom copyWith({
    String? id,
    List<String>? participants,
    String? propertyId,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      propertyId: propertyId ?? this.propertyId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String receiverId;
  final String message;
  final MessageType messageType;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.audioUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      messageType: MessageType.values.firstWhere(
        (e) => e.toString() == map['messageType'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
    );
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ChatMessage.fromMap(data);
  }

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? receiverId,
    String? message,
    MessageType? messageType,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum MessageType {
  text,
  image,
  audio,
  location,
  property,
}

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.audio:
        return 'Audio';
      case MessageType.location:
        return 'Location';
      case MessageType.property:
        return 'Property';
    }
  }
}