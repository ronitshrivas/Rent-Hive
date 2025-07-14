import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:renthive/models/property_model.dart';
import '../services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class PropertyProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<PropertyModel> _properties = [];
  List<PropertyModel> _ownerProperties = [];
  List<PropertyModel> _filteredProperties = [];
  bool _isLoading = false;
  String? _errorMessage;
  PropertyModel? _selectedProperty;

  // Filter options
  PropertyType? _selectedPropertyType;
  double? _minPrice;
  double? _maxPrice;
  String? _location;
  List<String> _selectedAmenities = [];
  FurnishingType? _selectedFurnishing;

  List<PropertyModel> get properties => _filteredProperties.isNotEmpty 
      ? _filteredProperties 
      : _properties;
  List<PropertyModel> get ownerProperties => _ownerProperties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PropertyModel? get selectedProperty => _selectedProperty;

  // Filter getters
  PropertyType? get selectedPropertyType => _selectedPropertyType;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get location => _location;
  List<String> get selectedAmenities => _selectedAmenities;
  FurnishingType? get selectedFurnishing => _selectedFurnishing;

  Future<void> loadProperties() async {
    try {
      _setLoading(true);
      _clearError();

      _properties = await _firebaseService.getAllProperties();
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load properties: $e');
      _setLoading(false);
    }
  }

  Future<void> loadOwnerProperties(String ownerId) async {
    try {
      _setLoading(true);
      _clearError();

      _ownerProperties = await _firebaseService.getPropertiesByOwner(ownerId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load owner properties: $e');
      _setLoading(false);
    }
  }

  // Fixed PropertyProvider with correct upload flow

Future<bool> addProperty(PropertyModel property, {
  List<File>? propertyImages,
  List<File>? virtualTourImages,
}) async {
  try {
    _setLoading(true);
    _clearError();

    print('PropertyProvider: Starting to add property');
    
    // Step 1: Upload images to user's folder first (using userId, not propertyId)
    List<String> imageUrls = [];
    if (propertyImages != null && propertyImages.isNotEmpty) {
      print('PropertyProvider: Uploading ${propertyImages.length} property images');
      imageUrls = await _firebaseService.uploadPropertyImages(
        propertyImages, 
        property.ownerId, // Use userId instead of propertyId
      );
      print('PropertyProvider: Property images uploaded successfully');
    }
    
    // Step 2: Upload virtual tour images to user's folder
    List<String> virtualTourUrls = [];
    if (virtualTourImages != null && virtualTourImages.isNotEmpty) {
      print('PropertyProvider: Uploading ${virtualTourImages.length} virtual tour images');
      virtualTourUrls = await _firebaseService.uploadVirtualTourImages(
        virtualTourImages, 
        property.ownerId, // Use userId instead of propertyId
      );
      print('PropertyProvider: Virtual tour images uploaded successfully');
    }
    
    // Step 3: Create property with uploaded image URLs
    final propertyWithImages = property.copyWith(
      images: imageUrls,
      virtualTourImages: virtualTourUrls,
    );

    print('PropertyProvider: Calling Firebase service to add property');
    String propertyId = await _firebaseService.addProperty(propertyWithImages);
    
    print('PropertyProvider: Property added with ID: $propertyId');
    
    // Step 4: Update the property with the Firestore-generated ID
    final finalProperty = propertyWithImages.copyWith(id: propertyId);
    
    _ownerProperties.add(finalProperty);
    _properties.add(finalProperty);
    _applyFilters();
    _setLoading(false);
    
    print('PropertyProvider: Property added successfully');
    return true;
  } catch (e) {
    print('PropertyProvider: Error adding property: $e');
    _setError('Failed to add property: $e');
    _setLoading(false);
    return false;
  }
}

  Future<bool> updateProperty(PropertyModel property, {
  List<File>? newPropertyImages,
  List<File>? newVirtualTourImages,
  List<String>? imagesToDelete,
  List<String>? virtualTourImagesToDelete,
}) async {
  try {
    _setLoading(true);
    _clearError();

    List<String> updatedImageUrls = List.from(property.images);
    List<String> updatedVirtualTourUrls = List.from(property.virtualTourImages);
    
    // Delete old images if specified
    if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
      await _firebaseService.deleteImagesFromStorage(imagesToDelete);
      updatedImageUrls.removeWhere((url) => imagesToDelete.contains(url));
    }
    
    if (virtualTourImagesToDelete != null && virtualTourImagesToDelete.isNotEmpty) {
      await _firebaseService.deleteImagesFromStorage(virtualTourImagesToDelete);
      updatedVirtualTourUrls.removeWhere((url) => virtualTourImagesToDelete.contains(url));
    }
    
    // Upload new images
    if (newPropertyImages != null && newPropertyImages.isNotEmpty) {
      final newImageUrls = await _firebaseService.uploadPropertyImages(newPropertyImages, property.id);
      updatedImageUrls.addAll(newImageUrls);
    }
    
    if (newVirtualTourImages != null && newVirtualTourImages.isNotEmpty) {
      final newVirtualTourUrls = await _firebaseService.uploadVirtualTourImages(newVirtualTourImages, property.id);
      updatedVirtualTourUrls.addAll(newVirtualTourUrls);
    }
    
    // Update property with new image URLs
    final updatedProperty = property.copyWith(
      images: updatedImageUrls,
      virtualTourImages: updatedVirtualTourUrls,
      updatedAt: DateTime.now(),
    );
    
    await _firebaseService.updateProperty(updatedProperty);
    
    // Update in local lists
    final ownerIndex = _ownerProperties.indexWhere((p) => p.id == property.id);
    if (ownerIndex != -1) {
      _ownerProperties[ownerIndex] = updatedProperty;
    }

    final allIndex = _properties.indexWhere((p) => p.id == property.id);
    if (allIndex != -1) {
      _properties[allIndex] = updatedProperty;
    }

    _applyFilters();
    _setLoading(false);
    return true;
  } catch (e) {
    _setError('Failed to update property: $e');
    _setLoading(false);
    return false;
  }
}

  Future<bool> deleteProperty(String propertyId) async {
  try {
    _setLoading(true);
    _clearError();

    // Find the property to get image URLs
    final property = _properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => _ownerProperties.firstWhere((p) => p.id == propertyId),
    );

    // Delete all images from storage
    final allImageUrls = [...property.images, ...property.virtualTourImages];
    if (allImageUrls.isNotEmpty) {
      await _firebaseService.deleteImagesFromStorage(allImageUrls);
    }

    // Delete property from Firestore
    await _firebaseService.deleteProperty(propertyId);
    
    // Remove from local lists
    _ownerProperties.removeWhere((p) => p.id == propertyId);
    _properties.removeWhere((p) => p.id == propertyId);
    _applyFilters();
    _setLoading(false);
    return true;
  } catch (e) {
    _setError('Failed to delete property: $e');
    _setLoading(false);
    return false;
  }
}

  Future<void> incrementPropertyViews(String propertyId) async {
    try {
      await _firebaseService.incrementPropertyViews(propertyId);
      
      // Update in local lists
      final allIndex = _properties.indexWhere((p) => p.id == propertyId);
      if (allIndex != -1) {
        _properties[allIndex] = _properties[allIndex].copyWith(
          views: _properties[allIndex].views + 1,
        );
      }

      final ownerIndex = _ownerProperties.indexWhere((p) => p.id == propertyId);
      if (ownerIndex != -1) {
        _ownerProperties[ownerIndex] = _ownerProperties[ownerIndex].copyWith(
          views: _ownerProperties[ownerIndex].views + 1,
        );
      }

      _applyFilters();
    } catch (e) {
      // Silently handle view increment errors
      print('Error incrementing views: $e');
    }
  }

  void setSelectedProperty(PropertyModel? property) {
    _selectedProperty = property;
    if (property != null) {
      incrementPropertyViews(property.id);
    }
    notifyListeners();
  }

  // Filter methods
  void setPropertyTypeFilter(PropertyType? type) {
    _selectedPropertyType = type;
    _applyFilters();
  }

  void setPriceFilter(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
  }

  void setLocationFilter(String? location) {
    _location = location;
    _applyFilters();
  }

  void setAmenitiesFilter(List<String> amenities) {
    _selectedAmenities = amenities;
    _applyFilters();
  }

  void setFurnishingFilter(FurnishingType? furnishing) {
    _selectedFurnishing = furnishing;
    _applyFilters();
  }

  void clearFilters() {
    _selectedPropertyType = null;
    _minPrice = null;
    _maxPrice = null;
    _location = null;
    _selectedAmenities = [];
    _selectedFurnishing = null;
    _applyFilters();
  }

  void _applyFilters() {
    List<PropertyModel> filtered = List.from(_properties);

    if (_selectedPropertyType != null) {
      filtered = filtered.where((p) => p.propertyType == _selectedPropertyType).toList();
    }

    if (_minPrice != null) {
      filtered = filtered.where((p) => p.price >= _minPrice!).toList();
    }

    if (_maxPrice != null) {
      filtered = filtered.where((p) => p.price <= _maxPrice!).toList();
    }

    if (_location != null && _location!.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.address.toLowerCase().contains(_location!.toLowerCase())
      ).toList();
    }

    if (_selectedAmenities.isNotEmpty) {
      filtered = filtered.where((p) => 
        _selectedAmenities.every((amenity) => p.amenities.contains(amenity))
      ).toList();
    }

    if (_selectedFurnishing != null) {
      filtered = filtered.where((p) => p.details.furnishing == _selectedFurnishing).toList();
    }

    _filteredProperties = filtered;
    notifyListeners();
  }

  List<PropertyModel> searchProperties(String query) {
    if (query.isEmpty) return properties;

    return properties.where((property) {
      return property.title.toLowerCase().contains(query.toLowerCase()) ||
             property.description.toLowerCase().contains(query.toLowerCase()) ||
             property.address.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<PropertyModel> getNearbyProperties(double latitude, double longitude, {double radiusKm = 10}) {
    return properties.where((property) {
      double distance = _calculateDistance(
        latitude, longitude,
        property.latitude, property.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
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