import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:renthive/models/user_model.dart';
import 'package:renthive/models/property_model.dart';
import 'package:renthive/models/chat_model.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _admin;
  bool _isLoading = false;
  List<UserModel> _allUsers = [];
  List<PropertyModel> _allProperties = [];
  List<ChatRoom> _allChatRooms = [];
  String? _errorMessage;

  // Getters
  UserModel? get admin => _admin;
  bool get isLoading => _isLoading;
  List<UserModel> get allUsers => _allUsers;
  List<PropertyModel> get allProperties => _allProperties;
  List<ChatRoom> get allChatRooms => _allChatRooms;
  String? get errorMessage => _errorMessage;

  // LOGIN
  Future<bool> loginAdmin(String email, String password) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Check if it's an admin email
      final adminDoc =
          await _firestore
              .collection('admins')
              .where('email', isEqualTo: email)
              .get();

      if (adminDoc.docs.isEmpty) {
        _errorMessage = 'Not an admin account';
        _setLoading(false);
        return false;
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _loadAdminData(result.user!.uid);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // PRIVATE LOAD METHODS
  Future<void> _loadAdminData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _admin = UserModel.fromMap(userDoc.data()!);
      }
      await refreshAllData();
    } catch (e) {
      _errorMessage = 'Error loading admin data: $e';
      print(_errorMessage);
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .get();

      _allUsers =
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error loading users: $e');
      _errorMessage = 'Error loading users';
    }
  }

  Future<void> _loadAllProperties() async {
    try {
      final snapshot =
          await _firestore
              .collection('properties')
              .orderBy('createdAt', descending: true)
              .get();

      _allProperties =
          snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading properties: $e');
      _errorMessage = 'Error loading properties';
    }
  }

  Future<void> _loadAllChatRooms() async {
    try {
      final snapshot =
          await _firestore
              .collection('chatRooms')
              .orderBy('lastMessageTime', descending: true)
              .get();

      _allChatRooms =
          snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading chat rooms: $e');
      _errorMessage = 'Error loading chat rooms';
    }
  }

  // PUBLIC REFRESH METHODS
  Future<void> refreshAllData() async {
    try {
      _setLoading(true);
      await Future.wait([
        _loadAllUsers(),
        _loadAllProperties(),
        _loadAllChatRooms(),
      ]);
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error refreshing data: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async {
    try {
      await _loadAllUsers();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error refreshing users: $e';
      notifyListeners();
    }
  }

  Future<void> refreshProperties() async {
    try {
      await _loadAllProperties();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error refreshing properties: $e';
      notifyListeners();
    }
  }

  Future<void> refreshChatRooms() async {
    try {
      await _loadAllChatRooms();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error refreshing chat rooms: $e';
      notifyListeners();
    }
  }

  // USER MANAGEMENT
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete user's properties first
      final propertiesSnapshot =
          await _firestore
              .collection('properties')
              .where('ownerId', isEqualTo: userId)
              .get();

      for (var doc in propertiesSnapshot.docs) {
        await deleteProperty(doc.id);
      }

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Update local list
      _allUsers.removeWhere((user) => user.id == userId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting user: $e';
      print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  Future<bool> blockUser(String userId, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': isBlocked,
        'blockedAt': isBlocked ? DateTime.now().toIso8601String() : null,
      });

      // Refresh users to get updated data
      await refreshUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Error blocking user: $e';
      print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // PROPERTY MANAGEMENT
  Future<bool> deleteProperty(String propertyId) async {
    try {
      // Delete related chat rooms first
      final chatRoomsSnapshot =
          await _firestore
              .collection('chatRooms')
              .where('propertyId', isEqualTo: propertyId)
              .get();

      for (var doc in chatRoomsSnapshot.docs) {
        await deleteChatRoom(doc.id);
      }

      // Delete property document
      await _firestore.collection('properties').doc(propertyId).delete();

      // Update local list
      _allProperties.removeWhere((property) => property.id == propertyId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting property: $e';
      print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePropertyAvailability(
    String propertyId,
    bool isAvailable,
  ) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'isAvailable': isAvailable,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local list
      final index = _allProperties.indexWhere((prop) => prop.id == propertyId);
      if (index != -1) {
        _allProperties[index] = _allProperties[index].copyWith(
          isAvailable: isAvailable,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error toggling property availability: $e';
      print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // CHAT MANAGEMENT
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete related messages first
      final messagesSnapshot =
          await _firestore
              .collection('messages')
              .where('chatRoomId', isEqualTo: chatRoomId)
              .get();

      // Use batch delete for better performance
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete chat room document
      await _firestore.collection('chatRooms').doc(chatRoomId).delete();

      // Update local list
      _allChatRooms.removeWhere((room) => room.id == chatRoomId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting chat room: $e';
      print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // STATISTICS
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final propertiesCount =
          await _firestore.collection('properties').count().get();
      final chatRoomsCount =
          await _firestore.collection('chatRooms').count().get();

      final availableProperties =
          _allProperties.where((p) => p.isAvailable).length;
      final rentedProperties = _allProperties.length - availableProperties;
      final propertyOwners =
          _allUsers.where((u) => u.userType == UserType.propertyOwner).length;
      final roomSeekers =
          _allUsers.where((u) => u.userType == UserType.roomSeeker).length;

      return {
        'totalUsers': usersCount.count ?? 0,
        'totalProperties': propertiesCount.count ?? 0,
        'totalChatRooms': chatRoomsCount.count ?? 0,
        'availableProperties': availableProperties,
        'rentedProperties': rentedProperties,
        'propertyOwners': propertyOwners,
        'roomSeekers': roomSeekers,
      };
    } catch (e) {
      _errorMessage = 'Error getting statistics: $e';
      print(_errorMessage);
      return {
        'totalUsers': 0,
        'totalProperties': 0,
        'totalChatRooms': 0,
        'availableProperties': 0,
        'rentedProperties': 0,
        'propertyOwners': 0,
        'roomSeekers': 0,
      };
    }
  }

  // SEARCH FUNCTIONALITY
  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _allUsers;

    final lowerQuery = query.toLowerCase();
    return _allUsers.where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery) ||
          user.phone.contains(query);
    }).toList();
  }

  List<PropertyModel> searchProperties(String query) {
    if (query.isEmpty) return _allProperties;

    final lowerQuery = query.toLowerCase();
    return _allProperties.where((property) {
      return property.title.toLowerCase().contains(lowerQuery) ||
          property.description.toLowerCase().contains(lowerQuery) ||
          property.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // UTILITY METHODS
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No admin account found with this email';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _admin = null;
    _allUsers.clear();
    _allProperties.clear();
    _allChatRooms.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
