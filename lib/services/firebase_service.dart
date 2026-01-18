import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/property_model.dart';
import '../models/chat_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize FCM
  Future<void> initializeNotifications() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      //return token;
    }
    return null;
  }

  // Save FCM token to user document
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Upload profile image with compression
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(
        'users/$userId/profile/$fileName',
      );

      print('Uploading profile image to: users/$userId/profile/$fileName');

      // Upload with metadata
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Delete old profile image
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
        final Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
        print('Old profile image deleted');
      }
    } catch (e) {
      print('Error deleting old profile image: $e');
    }
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = {
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('notifications').add(notification);
      print('Notification saved to Firestore');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final unreadNotifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Get property analytics for dashboard
  Future<Map<String, dynamic>> getOwnerAnalytics(String ownerId) async {
    try {
      final properties = await getPropertiesByOwner(ownerId);

      int totalProperties = properties.length;
      int availableProperties = properties.where((p) => p.isAvailable).length;
      int unavailableProperties = totalProperties - availableProperties;
      int totalViews = properties.fold(0, (sum, p) => sum + p.views);
      double averageRating = 0;

      if (properties.isNotEmpty) {
        double totalRating = properties.fold(0.0, (sum, p) => sum + p.rating);
        averageRating = totalRating / properties.length;
      }

      // Get recent inquiries (messages from chat rooms)
      int recentInquiries = 0;
      try {
        final chatRooms =
            await _firestore
                .collection('chatRooms')
                .where('participants', arrayContains: ownerId)
                .get();

        recentInquiries = chatRooms.docs.length;
      } catch (e) {
        print('Error getting inquiries: $e');
      }

      return {
        'totalProperties': totalProperties,
        'availableProperties': availableProperties,
        'unavailableProperties': unavailableProperties,
        'totalViews': totalViews,
        'averageRating': averageRating,
        'recentInquiries': recentInquiries,
        'properties': properties,
      };
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  // User Methods
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Property Methods
  Future<String> addProperty(PropertyModel property) async {
    try {
      print('FirebaseService: Adding property');
      final propertyData = property.toMap();

      final docRef = await _firestore
          .collection('properties')
          .add(propertyData)
          .timeout(const Duration(seconds: 30));

      print('Property added with ID: ${docRef.id}');

      // Send notification to nearby users (implement based on your needs)
      await _notifyNearbyUsers(property);

      return docRef.id;
    } catch (e) {
      print('Error adding property: $e');
      throw Exception('Failed to add property: $e');
    }
  }

  Future<void> _notifyNearbyUsers(PropertyModel property) async {
    try {
      // Get all room seekers
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('userType', isEqualTo: UserType.roomSeeker.toString())
              .get();

      // Send notifications
      for (var userDoc in usersSnapshot.docs) {
        await sendNotificationToUser(
          userId: userDoc.id,
          title: 'New Property Available',
          body:
              '${property.title} - ₹${property.price.toStringAsFixed(0)}/${property.priceType.displayName}',
          data: {'type': 'new_property', 'propertyId': property.id},
        );
      }
    } catch (e) {
      print('Error notifying users: $e');
    }
  }

  Future<List<PropertyModel>> getAllProperties() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('properties')
              .where('isAvailable', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get properties: $e');
    }
  }

  Future<List<PropertyModel>> getPropertiesByOwner(String ownerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('properties')
              .where('ownerId', isEqualTo: ownerId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get owner properties: $e');
    }
  }

  Future<void> updateProperty(PropertyModel property) async {
    try {
      await _firestore
          .collection('properties')
          .doc(property.id)
          .update(property.toMap());
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  Future<void> incrementPropertyViews(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  // Upload methods
  Future<List<String>> uploadPropertyImages(
    List<File> imageFiles,
    String userId,
  ) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final File imageFile = imageFiles[i];
        final String fileName =
            'property_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference ref = _storage.ref().child(
          'properties/$userId/$fileName',
        );

        final UploadTask uploadTask = ref.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload property images: $e');
    }
  }

  Future<List<String>> uploadVirtualTourImages(
    List<File> imageFiles,
    String userId,
  ) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final File imageFile = imageFiles[i];
        final String fileName =
            'vr_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference ref = _storage.ref().child(
          'virtual-tours/$userId/$fileName',
        );

        final UploadTask uploadTask = ref.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload virtual tour images: $e');
    }
  }

  Future<void> deleteImagesFromStorage(List<String> imageUrls) async {
    for (String imageUrl in imageUrls) {
      try {
        if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
          final Reference ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        }
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
  }

  // Chat Methods
  Future<String> createChatRoom(
    List<String> participants, {
    String? propertyId,
  }) async {
    try {
      final chatRoom = ChatRoom(
        id: '',
        participants: participants,
        propertyId: propertyId,
        lastMessage: 'Chat started',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: participants.first,
        unreadCount: {for (String participant in participants) participant: 0},
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('chatRooms')
          .add(chatRoom.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<String?> findExistingChatRoom(
    List<String> participants, {
    String? propertyId,
  }) async {
    try {
      Query query = _firestore
          .collection('chatRooms')
          .where('participants', isEqualTo: participants);

      if (propertyId != null) {
        query = query.where('propertyId', isEqualTo: propertyId);
      }

      final querySnapshot = await query.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ChatRoom>> getUserChatRooms(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('chatRooms')
              .where('participants', arrayContains: userId)
              .where('isActive', isEqualTo: true)
              .orderBy('lastMessageTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get chat rooms: $e');
    }
  }

  Stream<List<ChatRoom>> getUserChatRoomsStream(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList(),
        );
  }

  Future<void> sendMessage(ChatMessage message) async {
    try {
      // Add message
      await _firestore.collection('messages').add(message.toMap());

      // Update chat room
      await _firestore.collection('chatRooms').doc(message.chatRoomId).update({
        'lastMessage': message.message,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'lastMessageSenderId': message.senderId,
        'unreadCount.${message.receiverId}': FieldValue.increment(1),
      });

      // Send notification to receiver
      await sendNotificationToUser(
        userId: message.receiverId,
        title: 'New Message',
        body: message.message,
        data: {
          'type': 'new_message',
          'chatRoomId': message.chatRoomId,
          'senderId': message.senderId,
        },
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String chatRoomId) {
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final batch = _firestore.batch();

      final unreadMessages =
          await _firestore
              .collection('messages')
              .where('chatRoomId', isEqualTo: chatRoomId)
              .where('receiverId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      batch.update(_firestore.collection('chatRooms').doc(chatRoomId), {
        'unreadCount.$userId': 0,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
