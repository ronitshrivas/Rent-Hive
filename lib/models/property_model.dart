import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final PropertyType propertyType;
  final double price;
  final PriceType priceType;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> amenities;
  final PropertyDetails details;
  final ContactInfo contactInfo;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int totalRatings;
  final int views;
  final List<String> virtualTourImages;
  final Map<String, dynamic> rules;

  PropertyModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.price,
    required this.priceType,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.images = const [],
    this.amenities = const [],
    required this.details,
    required this.contactInfo,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.views = 0,
    this.virtualTourImages = const [],
    this.rules = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'propertyType': propertyType.toString(),
      'price': price,
      'priceType': priceType.toString(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'amenities': amenities,
      'details': details.toMap(),
      'contactInfo': contactInfo.toMap(),
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rating': rating,
      'totalRatings': totalRatings,
      'views': views,
      'virtualTourImages': virtualTourImages,
      'rules': rules,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      propertyType: PropertyType.values.firstWhere(
        (e) => e.toString() == map['propertyType'],
        orElse: () => PropertyType.room,
      ),
      price: (map['price'] ?? 0.0).toDouble(),
      priceType: PriceType.values.firstWhere(
        (e) => e.toString() == map['priceType'],
        orElse: () => PriceType.monthly,
      ),
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      details: PropertyDetails.fromMap(map['details'] ?? {}),
      contactInfo: ContactInfo.fromMap(map['contactInfo'] ?? {}),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      views: map['views'] ?? 0,
      virtualTourImages: List<String>.from(map['virtualTourImages'] ?? []),
      rules: Map<String, dynamic>.from(map['rules'] ?? {}),
    );
  }

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PropertyModel.fromMap(data);
  }

  PropertyModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    PropertyType? propertyType,
    double? price,
    PriceType? priceType,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? images,
    List<String>? amenities,
    PropertyDetails? details,
    ContactInfo? contactInfo,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? totalRatings,
    int? views,
    List<String>? virtualTourImages,
    Map<String, dynamic>? rules,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyType: propertyType ?? this.propertyType,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      details: details ?? this.details,
      contactInfo: contactInfo ?? this.contactInfo,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      views: views ?? this.views,
      virtualTourImages: virtualTourImages ?? this.virtualTourImages,
      rules: rules ?? this.rules,
    );
  }
}

class PropertyDetails {
  final int bedrooms;
  final int bathrooms;
  final double areaInSqFt;
  final int floor;
  final int totalFloors;
  final FurnishingType furnishing;
  final String? parking;
  final String? securityDeposit;
  final String? maintenanceCharges;

  PropertyDetails({
    required this.bedrooms,
    required this.bathrooms,
    required this.areaInSqFt,
    required this.floor,
    required this.totalFloors,
    required this.furnishing,
    this.parking,
    this.securityDeposit,
    this.maintenanceCharges,
  });

  Map<String, dynamic> toMap() {
    return {
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaInSqFt': areaInSqFt,
      'floor': floor,
      'totalFloors': totalFloors,
      'furnishing': furnishing.toString(),
      'parking': parking,
      'securityDeposit': securityDeposit,
      'maintenanceCharges': maintenanceCharges,
    };
  }

  factory PropertyDetails.fromMap(Map<String, dynamic> map) {
    return PropertyDetails(
      bedrooms: map['bedrooms'] ?? 1,
      bathrooms: map['bathrooms'] ?? 1,
      areaInSqFt: (map['areaInSqFt'] ?? 0.0).toDouble(),
      floor: map['floor'] ?? 1,
      totalFloors: map['totalFloors'] ?? 1,
      furnishing: FurnishingType.values.firstWhere(
        (e) => e.toString() == map['furnishing'],
        orElse: () => FurnishingType.unfurnished,
      ),
      parking: map['parking'],
      securityDeposit: map['securityDeposit'],
      maintenanceCharges: map['maintenanceCharges'],
    );
  }
}

class ContactInfo {
  final String name;
  final String phone;
  final String? email;
  final String? whatsapp;

  ContactInfo({
    required this.name,
    required this.phone,
    this.email,
    this.whatsapp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'whatsapp': whatsapp,
    };
  }

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      whatsapp: map['whatsapp'],
    );
  }
}

enum PropertyType {
  room,
  apartment,
  hostel,
  pg,
  house,
}

enum PriceType {
  daily,
  weekly,
  monthly,
  yearly,
}

enum FurnishingType {
  furnished,
  semiFurnished,
  unfurnished,
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.room:
        return 'Room';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.hostel:
        return 'Hostel';
      case PropertyType.pg:
        return 'PG';
      case PropertyType.house:
        return 'House';
    }
  }
}

extension PriceTypeExtension on PriceType {
  String get displayName {
    switch (this) {
      case PriceType.daily:
        return 'Per Day';
      case PriceType.weekly:
        return 'Per Week';
      case PriceType.monthly:
        return 'Per Month';
      case PriceType.yearly:
        return 'Per Year';
    }
  }
}

extension FurnishingTypeExtension on FurnishingType {
  String get displayName {
    switch (this) {
      case FurnishingType.furnished:
        return 'Fully Furnished';
      case FurnishingType.semiFurnished:
        return 'Semi Furnished';
      case FurnishingType.unfurnished:
        return 'Unfurnished';
    }
  }
}