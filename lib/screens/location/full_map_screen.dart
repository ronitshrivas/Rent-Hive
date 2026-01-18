import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:renthive/services/location_services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/property_model.dart';
import '../../utils/app_colors.dart';

class FullMapScreen extends StatefulWidget {
  final PropertyModel property;
  final bool showNavigation;

  const FullMapScreen({
    super.key,
    required this.property,
    this.showNavigation = true,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<LatLng> _routePoints = [];
  bool _isTrackingLocation = false;
  bool _isNavigating = false;
  double? _distanceToProperty;
  double? _estimatedTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _calculateDistance();
        });

        // Center map to show both user and property
        _centerMapToShowBoth();

        // Start tracking if navigation is enabled
        if (widget.showNavigation) {
          _startLocationTracking();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _startLocationTracking() {
    setState(() {
      _isTrackingLocation = true;
    });

    _positionStreamSubscription = LocationService().getPositionStream().listen((
      Position position,
    ) {
      setState(() {
        _currentPosition = position;

        // Add to route if navigating
        if (_isNavigating) {
          _routePoints.add(LatLng(position.latitude, position.longitude));
        }

        _calculateDistance();
      });

      // Auto-center map if navigating
      if (_isNavigating) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTrackingLocation = false;
      _isNavigating = false;
    });
  }

  void _calculateDistance() {
    if (_currentPosition != null) {
      final distance = LocationService().calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.property.latitude,
        widget.property.longitude,
      );

      setState(() {
        _distanceToProperty = distance;
        // Estimate time (assuming average walking speed of 5 km/h)
        _estimatedTime = (distance / 1000) / 5 * 60; // in minutes
      });
    }
  }

  void _centerMapToShowBoth() {
    if (_currentPosition == null) return;

    final bounds = LatLngBounds(
      LatLng(
        math.min(_currentPosition!.latitude, widget.property.latitude),
        math.min(_currentPosition!.longitude, widget.property.longitude),
      ),
      LatLng(
        math.max(_currentPosition!.latitude, widget.property.latitude),
        math.max(_currentPosition!.longitude, widget.property.longitude),
      ),
    );

    // Calculate center and zoom to fit both points
    final center = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );

    // Calculate appropriate zoom level
    final double latDiff = (bounds.north - bounds.south).abs();
    final double lngDiff = (bounds.east - bounds.west).abs();
    final double maxDiff = math.max(latDiff, lngDiff);

    double zoom = 15.0;
    if (maxDiff > 0.1)
      zoom = 11.0;
    else if (maxDiff > 0.05)
      zoom = 12.0;
    else if (maxDiff > 0.01)
      zoom = 13.0;
    else if (maxDiff > 0.005)
      zoom = 14.0;

    _mapController.move(center, zoom);
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _routePoints = [];
      if (_currentPosition != null) {
        _routePoints.add(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
      }
    });

    if (!_isTrackingLocation) {
      _startLocationTracking();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation started'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _routePoints.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation stopped'),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition != null
                      ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                      : LatLng(
                        widget.property.latitude,
                        widget.property.longitude,
                      ),
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              // Map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.renthive',
              ),

              // Route polyline
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primaryColor,
                      strokeWidth: 4.0,
                      borderStrokeWidth: 6.0,
                      borderColor: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Property marker
                  Marker(
                    point: LatLng(
                      widget.property.latitude,
                      widget.property.longitude,
                    ),
                    width: 60,
                    height: 60,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Property',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: AppColors.errorColor,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User location marker
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 60,
                      height: 60,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.successColor.withOpacity(
                                      0.3,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.property.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_distanceToProperty != null)
                          Text(
                            '${(_distanceToProperty! / 1000).toStringAsFixed(2)} km away',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Distance info card
          if (_currentPosition != null && _distanceToProperty != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      Icons.straighten_rounded,
                      'Distance',
                      '${(_distanceToProperty! / 1000).toStringAsFixed(2)} km',
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildInfoItem(
                      Icons.access_time_rounded,
                      'Est. Time',
                      '${_estimatedTime?.toStringAsFixed(0) ?? 0} min',
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildInfoItem(
                      Icons.directions_walk_rounded,
                      'Mode',
                      'Walking',
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isNavigating)
                      ElevatedButton.icon(
                        onPressed: _startNavigation,
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Start Navigation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _stopNavigation,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Stop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.errorColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _centerMapToShowBoth,
                              icon: const Icon(
                                Icons.center_focus_strong_rounded,
                              ),
                              label: const Text('Recenter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Map controls
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        16.0,
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_currentPosition == null && _errorMessage == null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        _initializeLocation();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
