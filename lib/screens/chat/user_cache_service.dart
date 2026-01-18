import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:renthive/models/user_model.dart';

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final Map<String, UserModel> _userCache = {};
  final Map<String, StreamController<UserModel?>> _userStreams = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID with caching
  Future<UserModel?> getUserById(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!);
        _userCache[userId] = user; // Cache the user
        return user;
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get user stream (real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    if (!_userStreams.containsKey(userId)) {
      _userStreams[userId] = StreamController<UserModel?>.broadcast();

      _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                final user = UserModel.fromMap(snapshot.data()!);
                _userCache[userId] = user; // Update cache
                _userStreams[userId]?.add(user);
              } else {
                _userStreams[userId]?.add(null);
              }
            },
            onError: (error) {
              print('Error in user stream: $error');
              _userStreams[userId]?.addError(error);
            },
          );
    }

    return _userStreams[userId]!.stream;
  }

  // Clear cache
  void clearCache() {
    _userCache.clear();
  }

  // Clear specific user from cache
  void clearUserCache(String userId) {
    _userCache.remove(userId);
  }

  // Preload multiple users
  Future<void> preloadUsers(List<String> userIds) async {
    final futures = userIds.map((id) => getUserById(id)).toList();
    await Future.wait(futures);
  }

  // Get multiple users at once
  Future<Map<String, UserModel>> getMultipleUsers(List<String> userIds) async {
    final Map<String, UserModel> users = {};

    for (String userId in userIds) {
      final user = await getUserById(userId);
      if (user != null) {
        users[userId] = user;
      }
    }

    return users;
  }

  // Dispose streams
  void dispose() {
    for (var controller in _userStreams.values) {
      controller.close();
    }
    _userStreams.clear();
  }
}
