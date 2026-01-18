// providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authStateSubscription;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
      _configureAuth();

    _initializeAuth();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _configureAuth() {
  // Configure reCAPTCHA settings
  _auth.setSettings(
    appVerificationDisabledForTesting: false, // Set to true only for testing
    userAccessGroup: null,
  );
}

  void _initializeAuth() {
    _authStateSubscription = _auth.authStateChanges().listen((User? firebaseUser) async {
      try {
        if (firebaseUser != null) {
          print('Auth state changed: User signed in (${firebaseUser.uid})');
          await _loadUserData(firebaseUser.uid);
        } else {
          print('Auth state changed: User signed out');
          _user = null;
          await _clearUserLocally();
          notifyListeners();
        }
      } catch (e) {
        print('Auth state change error: $e');
        _setError('Authentication error occurred');
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
  try {
    print('📱 Loading user data for UID: $uid');
    final userData = await _firebaseService.getUserById(uid);
    
    if (userData != null) {
      _user = userData;
      await _saveUserLocally();
      print('✅ User data loaded successfully');
      print('   - User Type: ${userData.userType}'); // Debug log
      notifyListeners();
    } else {
      print('❌ User document not found - creating it...');
      
      // Get current Firebase user info
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // DON'T create user here - let signup method handle it
        print('⚠️ User document missing, but signup should handle creation');
        _setError('Profile setup incomplete. Please complete signup.');
      }
    }
  } catch (e) {
    print('🔥 Load user data error: $e');
    _setError('Failed to load user profile');
    notifyListeners();
  }
}

  // Enhanced signUp method with PigeonUserDetails error handling
  Future<bool> signUp({
  required String email,
  required String password,
  required String name,
  required String phone,
  required UserType userType,
}) async {
  try {
    _setLoading(true);
    _clearError();

    print('Starting signup process for email: $email');
    print('Selected user type: $userType'); // Debug log

    // Check if user already exists first
    try {
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());
      if (signInMethods.isNotEmpty) {
        _setError('This email is already registered. Please sign in instead.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Could not check existing email: $e');
    }

    UserCredential? result;
    
    try {
      result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(const Duration(seconds: 30));
      
      print('✅ Firebase Auth successful');
      
    } catch (e) {
      if (e.toString().contains('PigeonUserDetails')) {
        print('PigeonUserDetails error during signup, checking auth state...');
        await Future.delayed(const Duration(seconds: 2));
        
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email.trim()) {
          print('✅ User was created despite PigeonUserDetails error');
          result = _MockUserCredential(currentUser);
        } else {
          _setError('Account creation failed. Please try again.');
          _setLoading(false);
          return false;
        }
      } else {
        throw e;
      }
    }

    if (result?.user != null) {
      final firebaseUser = result!.user!;
      
      try {
        await firebaseUser.sendEmailVerification();
        print('Email verification sent');
      } catch (e) {
        print('Could not send verification email: $e');
      }
      
      // Create user document with the CORRECT user type
      final newUser = UserModel(
        id: firebaseUser.uid,
        email: email.trim(),
        name: name.trim(),
        phone: phone.trim(),
        userType: userType, // ✅ Use the actual selected userType
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Creating user document with type: ${newUser.userType}');
      print('User data to save: ${newUser.toMap()}'); // Debug log
      
      await _firebaseService.createUser(newUser);
      _user = newUser;
      await _saveUserLocally();
      
      print('✅ Signup completed with user type: ${_user!.userType}');
      _setLoading(false);
      return true;
    }
    
    _setError('Failed to create account');
    _setLoading(false);
    return false;
    
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error: ${e.code} - ${e.message}');
    _setError(_getAuthErrorMessage(e.code));
    _setLoading(false);
    return false;
  } catch (e) {
    print('Unexpected signup error: $e');
    _setError('An unexpected error occurred: ${e.toString()}');
    _setLoading(false);
    return false;
  }
}

  // Enhanced signIn method with PigeonUserDetails error handling
  Future<bool> signIn({
  required String email,
  required String password,
}) async {
  try {
    _setLoading(true);
    _clearError();

    print('Starting signin process for email: $email');

    // Simple signin without retry mechanism
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (result.user != null) {
      print('✅ Firebase Auth successful');
      
      // Wait a moment for auth state to settle
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Check if we have a user in our provider
      if (_user != null) {
        _setLoading(false);
        return true;
      }
      
      // If no user data, try loading it manually
      await _loadUserData(result.user!.uid);
      _setLoading(false);
      return _user != null;
    }
    
    _setLoading(false);
    return false;
    
  } catch (e) {
    print('Signin error: $e');
    
    // Handle PigeonUserDetails error specifically
    if (e.toString().contains('PigeonUserDetails')) {
      print('PigeonUserDetails error - checking current user...');
      
      await Future.delayed(const Duration(seconds: 2));
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('User is actually signed in');
        await _loadUserData(currentUser.uid);
        _setLoading(false);
        return _user != null;
      }
    }
    
    if (e is FirebaseAuthException) {
      _setError(_getAuthErrorMessage(e.code));
    } else {
      _setError('Login failed. Please try again.');
    }
    
    _setLoading(false);
    return false;
  }
}

  // Check if email exists
  Future<bool> checkIfEmailExists(String email) async {
    try {
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Resend email verification
  Future<bool> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Email verification sent');
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending verification email: $e');
      _setError('Failed to send verification email');
      return false;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Signing out user...');
      await _auth.signOut();
      await _clearUserLocally();
      _user = null;
      _clearError();
      notifyListeners();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      _setError('Failed to sign out');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if email exists first
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());
      if (signInMethods.isEmpty) {
        _setError('No account found with this email address');
        _setLoading(false);
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      print('Password reset email sent to: $email');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('Unexpected password reset error: $e');
      _setError('Failed to send reset email: ${e.toString()}');
    }

    _setLoading(false);
    return false;
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImage,
    Map<String, dynamic>? preferences,
  }) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final updatedUser = _user!.copyWith(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        address: address ?? _user!.address,
        latitude: latitude ?? _user!.latitude,
        longitude: longitude ?? _user!.longitude,
        profileImage: profileImage ?? _user!.profileImage,
        preferences: preferences ?? _user!.preferences,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateUser(updatedUser);
      _user = updatedUser;
      await _saveUserLocally();
      _setLoading(false);
      print('Profile updated successfully');
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Toggle favorite property
  Future<void> toggleFavoriteProperty(String propertyId) async {
    if (_user == null) return;

    try {
      List<String> favorites = List.from(_user!.favoriteProperties);
      
      if (favorites.contains(propertyId)) {
        favorites.remove(propertyId);
        print('Removed property $propertyId from favorites');
      } else {
        favorites.add(propertyId);
        print('Added property $propertyId to favorites');
      }

      final updatedUser = _user!.copyWith(
        favoriteProperties: favorites,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateUser(updatedUser);
      _user = updatedUser;
      await _saveUserLocally();
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      _setError('Failed to update favorites: ${e.toString()}');
    }
  }

  // Check if property is favorite
  bool isFavoriteProperty(String propertyId) {
    return _user?.favoriteProperties.contains(propertyId) ?? false;
  }

  // Local storage methods
  Future<void> _saveUserLocally() async {
    if (_user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = jsonEncode(_user!.toMap());
        await prefs.setString('user_data', userJson);
        print('User data saved locally');
      } catch (e) {
        print('Error saving user locally: $e');
      }
    }
  }

  Future<void> _clearUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      print('Local user data cleared');
    } catch (e) {
      print('Error clearing local user data: $e');
    }
  }

  Future<void> _loadUserLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _user = UserModel.fromMap(userMap);
        print('User data loaded from local storage');
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user from local storage: $e');
    }
  }

  // Utility methods
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

  // Enhanced error message mapping
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead';
      case 'weak-password':
        return 'Password should be at least 6 characters long';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled. Contact support';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Contact support';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to continue';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  // Debug method
  Future<void> debugAuth() async {
    print('=== AUTH DEBUG INFO ===');
    print('Current user: ${_auth.currentUser?.uid}');
    print('Current user email: ${_auth.currentUser?.email}');
    print('Provider user: ${_user?.id}');
    print('Provider user email: ${_user?.email}');
    print('Is authenticated: $isAuthenticated');
    print('Is loading: $isLoading');
    print('Error message: $errorMessage');
    print('======================');
  }
}

// Mock UserCredential class for handling PigeonUserDetails errors
class _MockUserCredential implements UserCredential {
  @override
  final User user;

  _MockUserCredential(this.user);

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}