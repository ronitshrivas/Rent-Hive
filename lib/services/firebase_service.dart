import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // Collections
  static const String usersCollection = 'users';
  static const String propertiesCollection = 'properties';
  static const String chatRoomsCollection = 'chatRooms';
  static const String messagesCollection = 'messages';
  static const String reviewsCollection = 'reviews';

  // User Methods
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap())
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (e) {
      print('Firestore create error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error creating user: $e');
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
        // Add type safety check
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }
      return null;
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.code} - ${e.message}');
      rethrow;
    } on TimeoutException catch (e) {
      print('Firestore timeout: $e');
      throw Exception('Request timed out');
    } catch (e) {
      print('Unexpected error getting user: $e');
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
    } on FirebaseException catch (e) {
      print('Firestore update error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Property Methods
  // Updated addProperty method for FirebaseService class

Future<String> addProperty(PropertyModel property) async {
  try {
    print('FirebaseService: Starting to add property');
    print('FirebaseService: Property title: ${property.title}');
    
    // Step 1: Create property document in Firestore first
    final propertyData = property.toMap();
    print('FirebaseService: Property data prepared');
    print('FirebaseService: Owner ID: ${propertyData['ownerId']}');
    
    final docRef = await _firestore
        .collection(propertiesCollection)
        .add(propertyData)
        .timeout(const Duration(seconds: 30));
    
    print('FirebaseService: Property added successfully with ID: ${docRef.id}');
    return docRef.id;
  } on FirebaseException catch (e) {
    print('FirebaseService: Firebase error: ${e.code} - ${e.message}');
    throw Exception('Failed to add property: ${e.message}');
  } catch (e) {
    print('FirebaseService: General error: $e');
    throw Exception('Failed to add property: $e');
  }
}

// Add these methods to your FirebaseService class

// Upload single image
Future<String> uploadPropertyImage(File imageFile, String propertyId) async {
  try {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final Reference ref = _storage.ref().child('properties/$propertyId/$fileName');
    
    final UploadTask uploadTask = ref.putFile(imageFile);
    final TaskSnapshot snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    throw Exception('Failed to upload property image: $e');
  }
}

// Upload multiple property images
Future<List<String>> uploadPropertyImages(List<File> imageFiles, String userId, {String? propertyId}) async {
  try {
    List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final File imageFile = imageFiles[i];
      final String fileName = 'property_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      
      // Upload to user's folder (which we have permission for)
      final Reference ref = _storage.ref().child('properties/$userId/$fileName');
      
      print('Uploading property image to: properties/$userId/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
      
      print('Property image uploaded successfully: $downloadUrl');
    }
    
    return downloadUrls;
  } catch (e) {
    print('Error uploading property images: $e');
    throw Exception('Failed to upload property images: $e');
  }
}

// Upload virtual tour images
Future<List<String>> uploadVirtualTourImages(List<File> imageFiles, String userId, {String? propertyId}) async {
  try {
    List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final File imageFile = imageFiles[i];
      final String fileName = 'vr_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      
      // Upload to user's virtual tour folder
      final Reference ref = _storage.ref().child('virtual-tours/$userId/$fileName');
      
      print('Uploading virtual tour image to: virtual-tours/$userId/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
      
      print('Virtual tour image uploaded successfully: $downloadUrl');
    }
    
    return downloadUrls;
  } catch (e) {
    print('Error uploading virtual tour images: $e');
    throw Exception('Failed to upload virtual tour images: $e');
  }
}

// Upload profile image
Future<String> uploadProfileImage(File imageFile, String userId) async {
  try {
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('users/$userId/profile/$fileName');
    
    print('Uploading profile image to: users/$userId/profile/$fileName');
    
    final UploadTask uploadTask = ref.putFile(imageFile);
    final TaskSnapshot snapshot = await uploadTask;
    
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    print('Profile image uploaded successfully: $downloadUrl');
    
    return downloadUrl;
  } catch (e) {
    print('Error uploading profile image: $e');
    throw Exception('Failed to upload profile image: $e');
  }
}

// Upload chat media (images/audio)
Future<String> uploadChatMedia(File mediaFile, String chatRoomId, String mediaType) async {
  try {
    final String fileName = '${mediaType}_${DateTime.now().millisecondsSinceEpoch}.${mediaFile.path.split('.').last}';
    final Reference ref = _storage.ref().child('chats/$chatRoomId/$mediaType/$fileName');
    
    final UploadTask uploadTask = ref.putFile(mediaFile);
    final TaskSnapshot snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    throw Exception('Failed to upload chat media: $e');
  }
}

// Delete image from storage
Future<void> deleteImageFromStorage(String imageUrl) async {
  try {
    final Reference ref = _storage.refFromURL(imageUrl);
    await ref.delete();
  } catch (e) {
    print('Error deleting image: $e');
    // Don't throw error as it might be already deleted
  }
}

// Delete multiple images
Future<void> deleteImagesFromStorage(List<String> imageUrls) async {
  for (String imageUrl in imageUrls) {
    await deleteImageFromStorage(imageUrl);
  }
}

// Compress image before upload (optional optimization)
Future<File?> compressImage(File imageFile) async {
  try {
    // You can add image compression logic here using flutter_image_compress
    // For now, return the original file
    return imageFile;
  } catch (e) {
    print('Error compressing image: $e');
    return imageFile;
  }
}

  Future<List<PropertyModel>> getAllProperties() async {
    try {
      final querySnapshot = await _firestore
          .collection(propertiesCollection)
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
      final querySnapshot = await _firestore
          .collection(propertiesCollection)
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

  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore
          .collection(propertiesCollection)
          .doc(propertyId)
          .get();

      if (doc.exists) {
        return PropertyModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get property: $e');
    }
  }

  Future<void> updateProperty(PropertyModel property) async {
    try {
      await _firestore
          .collection(propertiesCollection)
          .doc(property.id)
          .update(property.toMap());
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore
          .collection(propertiesCollection)
          .doc(propertyId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  Future<void> incrementPropertyViews(String propertyId) async {
    try {
      await _firestore
          .collection(propertiesCollection)
          .doc(propertyId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment views: $e');
    }
  }

  Future<List<PropertyModel>> searchProperties({
    String? query,
    PropertyType? propertyType,
    double? minPrice,
    double? maxPrice,
    String? location,
    List<String>? amenities,
    FurnishingType? furnishing,
  }) async {
    try {
      Query queryRef = _firestore
          .collection(propertiesCollection)
          .where('isAvailable', isEqualTo: true);

      if (propertyType != null) {
        queryRef = queryRef.where('propertyType', isEqualTo: propertyType.toString());
      }

      if (minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (furnishing != null) {
        queryRef = queryRef.where('details.furnishing', isEqualTo: furnishing.toString());
      }

      final querySnapshot = await queryRef.get();
      List<PropertyModel> properties = querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();

      // Apply additional filters that can't be done in Firestore query
      if (query != null && query.isNotEmpty) {
        properties = properties.where((property) {
          return property.title.toLowerCase().contains(query.toLowerCase()) ||
                 property.description.toLowerCase().contains(query.toLowerCase()) ||
                 property.address.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      if (location != null && location.isNotEmpty) {
        properties = properties.where((property) {
          return property.address.toLowerCase().contains(location.toLowerCase());
        }).toList();
      }

      if (amenities != null && amenities.isNotEmpty) {
        properties = properties.where((property) {
          return amenities.every((amenity) => property.amenities.contains(amenity));
        }).toList();
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  // Chat Methods
  Future<String> createChatRoom(List<String> participants, {String? propertyId}) async {
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
          .collection(chatRoomsCollection)
          .add(chatRoom.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<List<ChatRoom>> getUserChatRooms(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(chatRoomsCollection)
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
        .collection(chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  Future<void> sendMessage(ChatMessage message) async {
    try {
      // Add message to messages collection
      await _firestore
          .collection(messagesCollection)
          .add(message.toMap());

      // Update chat room with last message
      await _firestore
          .collection(chatRoomsCollection)
          .doc(message.chatRoomId)
          .update({
        'lastMessage': message.message,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'lastMessageSenderId': message.senderId,
        'unreadCount.${message.receiverId}': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String chatRoomId) {
    return _firestore
        .collection(messagesCollection)
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // Mark messages as read
      final batch = _firestore.batch();
      
      final unreadMessages = await _firestore
          .collection(messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count in chat room
      batch.update(
        _firestore.collection(chatRoomsCollection).doc(chatRoomId),
        {'unreadCount.$userId': 0},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Storage Methods
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child('$path/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles, String path) async {
    try {
      List<String> downloadUrls = [];
      
      for (File imageFile in imageFiles) {
        final String url = await uploadImage(imageFile, path);
        downloadUrls.add(url);
      }
      
      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Review Methods
  Future<void> addReview({
    required String propertyId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    try {
      final review = {
        'propertyId': propertyId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection(reviewsCollection).add(review);

      // Update property rating
      await _updatePropertyRating(propertyId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPropertyReviews(String propertyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(reviewsCollection)
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  Future<void> _updatePropertyRating(String propertyId) async {
    try {
      final reviews = await getPropertyReviews(propertyId);
      
      if (reviews.isNotEmpty) {
        double totalRating = 0;
        for (var review in reviews) {
          totalRating += review['rating'];
        }
        
        double averageRating = totalRating / reviews.length;
        
        await _firestore
            .collection(propertiesCollection)
            .doc(propertyId)
            .update({
          'rating': averageRating,
          'totalRatings': reviews.length,
        });
      }
    } catch (e) {
      throw Exception('Failed to update property rating: $e');
    }
  }

  // Utility Methods
  Future<bool> checkIfChatRoomExists(List<String> participants, {String? propertyId}) async {
    try {
      Query query = _firestore
          .collection(chatRoomsCollection)
          .where('participants', isEqualTo: participants);

      if (propertyId != null) {
        query = query.where('propertyId', isEqualTo: propertyId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String?> findExistingChatRoom(List<String> participants, {String? propertyId}) async {
    try {
      Query query = _firestore
          .collection(chatRoomsCollection)
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

  // Batch Operations
  Future<void> batchUpdateProperties(List<PropertyModel> properties) async {
    try {
      final batch = _firestore.batch();
      
      for (PropertyModel property in properties) {
        final docRef = _firestore.collection(propertiesCollection).doc(property.id);
        batch.update(docRef, property.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update properties: $e');
    }
  }

  Future<void> batchDeleteProperties(List<String> propertyIds) async {
    try {
      final batch = _firestore.batch();
      
      for (String propertyId in propertyIds) {
        final docRef = _firestore.collection(propertiesCollection).doc(propertyId);
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch delete properties: $e');
    }
  }

  // Analytics Methods
  Future<Map<String, dynamic>> getPropertyAnalytics(String ownerId) async {
    try {
      final properties = await getPropertiesByOwner(ownerId);
      
      int totalProperties = properties.length;
      int availableProperties = properties.where((p) => p.isAvailable).length;
      int totalViews = properties.fold(0, (sum, p) => sum + p.views);
      double averageRating = 0;
      
      if (properties.isNotEmpty) {
        double totalRating = properties.fold(0.0, (sum, p) => sum + p.rating);
        averageRating = totalRating / properties.length;
      }

      return {
        'totalProperties': totalProperties,
        'availableProperties': availableProperties,
        'totalViews': totalViews,
        'averageRating': averageRating,
        'properties': properties,
      };
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  // Notification Methods
  Future<void> sendNotification({
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
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}