import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? profileImage;
  final UserType userType;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final double rating;
  final int totalRatings;
  final List<String> favoriteProperties;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.profileImage,
    required this.userType,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.favoriteProperties = const [],
    this.preferences = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType.toString(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'rating': rating,
      'totalRatings': totalRatings,
      'favoriteProperties': favoriteProperties,
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == map['userType'],
        orElse: () => UserType.roomSeeker,
      ),
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isVerified: map['isVerified'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      favoriteProperties: List<String>.from(map['favoriteProperties'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    UserType? userType,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    double? rating,
    int? totalRatings,
    List<String>? favoriteProperties,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      favoriteProperties: favoriteProperties ?? this.favoriteProperties,
      preferences: preferences ?? this.preferences,
    );
  }
}

enum UserType {
  roomSeeker,
  propertyOwner,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.roomSeeker:
        return 'Room Seeker';
      case UserType.propertyOwner:
        return 'Property Owner';
    }
  }

  String get description {
    switch (this) {
      case UserType.roomSeeker:
        return 'Looking for rooms, hostels, and accommodations';
      case UserType.propertyOwner:
        return 'Renting out rooms, properties, and hostels';
    }
  }
}