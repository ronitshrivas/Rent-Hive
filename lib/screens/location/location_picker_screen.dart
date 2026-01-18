import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as Geolocator;
import 'package:provider/provider.dart';
import 'package:renthive/providers/location_provider.dart';
import 'package:renthive/utils/app_colors.dart';
import 'package:renthive/widgets/custom_button.dart';
import 'package:renthive/widgets/custom_text_field.dart';
import 'package:renthive/widgets/loading_overlay.dart';


class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<String> _recentLocations = [
    'Kathmandu, Nepal',
    'Pokhara, Nepal',
    'Lalitpur, Nepal',
    'Bhaktapur, Nepal',
  ];

  List<String> _popularLocations = [
    'Thamel, Kathmandu',
    'Lakeside, Pokhara',
    'Patan Durbar Square',
    'Boudhanath, Kathmandu',
    'Sarangkot, Pokhara',
    'Baneshwor, Kathmandu',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Location'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          body: LoadingOverlay(
            isLoading: locationProvider.isLoading,
            child: Column(
              children: [
                // Search Section
                _buildSearchSection(locationProvider),
                
                // Current Location Button
                _buildCurrentLocationButton(locationProvider),
                
                // Location Lists
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recent Locations
                        _buildLocationSection(
                          'Recent Locations',
                          _recentLocations,
                          Icons.history_rounded,
                          locationProvider,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Popular Locations
                        _buildLocationSection(
                          'Popular Locations',
                          _popularLocations,
                          Icons.trending_up_rounded,
                          locationProvider,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSection(LocationProvider locationProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        hintText: 'Search city, area, or landmark',
        prefixIcon: Icons.search_rounded,
        onSubmitted: (value) => _searchLocation(value, locationProvider),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
      ),
    );
  }

  Widget _buildCurrentLocationButton(LocationProvider locationProvider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      child: CustomButton(
        text: 'Use Current Location',
        icon: Icons.my_location_rounded,
        onPressed: () => _getCurrentLocation(locationProvider),
        gradient: AppColors.primaryGradient,
      ),
    );
  }

  Widget _buildLocationSection(
    String title,
    List<String> locations,
    IconData icon,
    LocationProvider locationProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final location = locations[index];
            return _buildLocationTile(location, locationProvider);
          },
        ),
      ],
    );
  }

  Widget _buildLocationTile(String location, LocationProvider locationProvider) {
    final isSelected = locationProvider.currentAddress == location;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppColors.primaryColor 
              : AppColors.borderColor,
        ),
      ),
      child: ListTile(
        onTap: () => _selectLocation(location, locationProvider),
        leading: CircleAvatar(
          backgroundColor: isSelected 
              ? AppColors.primaryColor 
              : AppColors.borderColor,
          radius: 20,
          child: Icon(
            Icons.location_on_rounded,
            color: isSelected 
                ? Colors.white 
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          location,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? AppColors.primaryColor 
                : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryColor,
                size: 24,
              )
            : Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textLight,
                size: 16,
              ),
      ),
    );
  }

  Future<void> _getCurrentLocation(LocationProvider locationProvider) async {
    // Check and request permissions first
    final hasPermission = await locationProvider.hasLocationPermission();
    
    if (!hasPermission) {
      final granted = await locationProvider.requestLocationPermission();
      if (!granted) {
        _showPermissionDialog();
        return;
      }
    }

    await locationProvider.getCurrentLocation();
    
    if (locationProvider.currentLocation != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location updated: ${locationProvider.currentAddress ?? "Current location"}',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else if (locationProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationProvider.errorMessage!),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _searchLocation(String query, LocationProvider locationProvider) async {
    if (query.trim().isEmpty) return;

    await locationProvider.getLocationFromAddress(query.trim());
    
    if (locationProvider.currentLocation != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location set to: $query'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not found. Please try a different search.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _selectLocation(String location, LocationProvider locationProvider) async {
    await locationProvider.getLocationFromAddress(location);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location set to: $location'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Location Permission Required',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This app needs location permission to find properties near you. Please enable location access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}