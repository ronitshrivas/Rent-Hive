import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentLocation;
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocationServiceEnabled = false;

  Position? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  Future<void> getCurrentLocation() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        _setError('Location services are disabled');
        _setLoading(false);
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied');
          _setLoading(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied');
        _setLoading(false);
        return;
      }

      // Get current position with compatible settings for geolocator ^9.0.2
      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false,
        timeLimit: const Duration(seconds: 30),
      );

      // Get address from coordinates
      await _getAddressFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      _setLoading(false);
    } catch (e) {
      _setError('Failed to get location: $e');
      _setLoading(false);
    }
  }

  Future<void> getLocationFromAddress(String address) async {
    try {
      _setLoading(true);
      _clearError();

      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        _currentLocation = Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _currentAddress = address;
        notifyListeners();
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to get location from address: $e');
      _setLoading(false);
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _currentAddress = '${place.locality}, ${place.administrativeArea}';
        notifyListeners();
      }
    } catch (e) {
      _currentAddress = 'Unknown location';
      notifyListeners();
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void setLocation(Position position, String address) {
    _currentLocation = position;
    _currentAddress = address;
    notifyListeners();
  }

  void clearLocation() {
    _currentLocation = null;
    _currentAddress = null;
    notifyListeners();
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Get location with timeout and error handling
  Future<Position?> getLocationWithTimeout({
    Duration timeout = const Duration(seconds: 30),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: false,
        timeLimit: timeout,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Open app settings
      await Geolocator.openAppSettings();
      return false;
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Get detailed address with all components
  Future<Map<String, String>?> getDetailedAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return {
          'street': place.street ?? '',
          'locality': place.locality ?? '',
          'subLocality': place.subLocality ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'country': place.country ?? '',
          'postalCode': place.postalCode ?? '',
          'name': place.name ?? '',
        };
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Get formatted full address
  Future<String?> getFullAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        
        if (place.name != null && place.name!.isNotEmpty) {
          addressParts.add(place.name!);
        }
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        
        return addressParts.join(', ');
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Check if GPS is enabled
  Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  // Listen to position changes (for real-time tracking)
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    locationSettings ??= const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
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