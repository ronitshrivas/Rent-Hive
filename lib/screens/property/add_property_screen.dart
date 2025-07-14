import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:renthive/providers/location_provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/property_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final PageController _pageController = PageController();
  
  // Basic Info Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Details Controllers
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _parkingController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  
  // Contact Controllers
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  int _currentStep = 0;
  PropertyType _selectedPropertyType = PropertyType.room;
  PriceType _selectedPriceType = PriceType.monthly;
  FurnishingType _selectedFurnishing = FurnishingType.unfurnished;
  List<String> _selectedAmenities = [];
  List<File> _selectedImages = [];
  bool _isAvailable = true;
 
  double _latitude = 27.7172; // Default to Kathmandu
double _longitude = 85.3240;
bool _isGeocodingAddress = false;

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _availableAmenities = [
    'WiFi', 'AC', 'Parking', 'Gym', 'Swimming Pool', 'Elevator',
    'Security', 'Power Backup', 'Water Supply', 'Laundry', 'Kitchen',
    'Balcony', 'Garden', 'CCTV', 'Intercom', 'Playground'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserContactInfo();
  }

  void _loadUserContactInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _contactNameController.text = user.name;
      _contactPhoneController.text = user.phone;
      _contactEmailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _floorController.dispose();
    _totalFloorsController.dispose();
    _parkingController.dispose();
    _securityDepositController.dispose();
    _maintenanceController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _whatsappController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, authProvider, propertyProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Property'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          body: LoadingOverlay(
            isLoading: propertyProvider.isLoading,
            child: Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                
                // Form Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildBasicInfoStep(),
                      _buildDetailsStep(),
                      _buildImagesStep(),
                      _buildContactStep(),
                    ],
                  ),
                ),
                
                // Navigation Buttons
                _buildNavigationButtons(authProvider, propertyProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(4, (index) {
          bool isActive = index <= _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryColor : AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _geocodeAddress(String address) async {
  if (address.trim().isEmpty) return;
  
  setState(() {
    _isGeocodingAddress = true;
  });

  try {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      setState(() {
        _latitude = locations.first.latitude;
        _longitude = locations.first.longitude;
      });
      print('Geocoded address: $address to $_latitude, $_longitude');
    }
  } catch (e) {
    print('Geocoding failed: $e');
    // Keep default coordinates
  } finally {
    setState(() {
      _isGeocodingAddress = false;
    });
  }
}


  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Tell us about your property',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Property Type
          const Text(
            'Property Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PropertyType.values.map((type) {
              bool isSelected = _selectedPropertyType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPropertyType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                    ),
                  ),
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          CustomTextField(
            controller: _titleController,
            label: 'Property Title',
            hintText: 'e.g., 2 BHK Apartment in Kathmandu',
          ),
          
          const SizedBox(height: 20),
          
          // Description
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            hintText: 'Describe your property...',
            maxLines: 4,
          ),
          
          const SizedBox(height: 20),
          
          // Address
          CustomTextField(
  controller: _addressController,
  label: 'Address',
  hintText: 'Full address of the property',
  prefixIcon: Icons.location_on_outlined,
  onChanged: (value) {
    // Debounce geocoding to avoid too many API calls
    if (value.length > 10) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_addressController.text == value) {
          _geocodeAddress(value);
        }
      });
    }
  },
  
  suffixIcon: _isGeocodingAddress
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : IconButton(
          icon: const Icon(Icons.my_location_rounded),
          onPressed: _getCurrentLocationForAddress,
        ),
),
        _buildLocationDisplay(),

          
          const SizedBox(height: 20),
          
          // Price Section
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _priceController,
                  label: 'Price',
                  hintText: '25000',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: _buildPriceTypeDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocationForAddress() async {
  final locationProvider = Provider.of<LocationProvider>(context, listen: false);
  
  setState(() {
    _isGeocodingAddress = true;
  });

  try {
    await locationProvider.getCurrentLocation();
    
    if (locationProvider.currentLocation != null) {
      setState(() {
        _latitude = locationProvider.currentLocation!.latitude;
        _longitude = locationProvider.currentLocation!.longitude;
      });
      
      // Get address from coordinates
      final address = await locationProvider.getFullAddress(_latitude, _longitude);
      if (address != null) {
        _addressController.text = address;
      }
    }
  } catch (e) {
    print('Error getting current location: $e');
    _showErrorSnackBar('Failed to get current location');
  } finally {
    setState(() {
      _isGeocodingAddress = false;
    });
  }
}

Widget _buildLocationDisplay() {
  if (_latitude == 27.7172 && _longitude == 85.3240) {
    return const SizedBox.shrink();
  }
  
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.successColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AppColors.successColor.withOpacity(0.3),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.successColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Location: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildPriceTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Period',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PriceType>(
              value: _selectedPriceType,
              isExpanded: true,
              items: PriceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriceType = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Provide detailed information',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Room Details
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _bedroomsController,
                  label: 'Bedrooms',
                  hintText: '2',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _bathroomsController,
                  label: 'Bathrooms',
                  hintText: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Area and Floor
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _areaController,
                  label: 'Area (sq ft)',
                  hintText: '1200',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _floorController,
                  label: 'Floor',
                  hintText: '2',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _totalFloorsController,
            label: 'Total Floors',
            hintText: '4',
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 24),
          
          // Furnishing
          const Text(
            'Furnishing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: FurnishingType.values.map((type) {
              bool isSelected = _selectedFurnishing == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFurnishing = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                    ),
                  ),
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Additional Details
          CustomTextField(
            controller: _parkingController,
            label: 'Parking',
            hintText: 'e.g., 2 Car parking, Bike parking',
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _securityDepositController,
                  label: 'Security Deposit',
                  hintText: '50000',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _maintenanceController,
                  label: 'Maintenance',
                  hintText: '2000',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Amenities
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
              bool isSelected = _selectedAmenities.contains(amenity);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAmenities.remove(amenity);
                    } else {
                      _selectedAmenities.add(amenity);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      if (isSelected) const SizedBox(width: 4),
                      Text(
                        amenity,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesStep() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Images',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Add photos to showcase your property',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Regular Images Section
        const Text(
          'Property Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Add Images Button
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor,
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  'Tap to select images',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Selected Images Grid
        if (_selectedImages.isNotEmpty) ...[
          const Text(
            'Selected Photos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
        ],
        
        // Virtual Tour Images Section
        const Text(
          'Virtual Tour Images (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Add 360° or wide-angle photos for virtual tours',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Add Virtual Tour Images Button
        GestureDetector(
          onTap: _pickVirtualTourImages,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondaryColor,
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.view_in_ar_rounded,
                  size: 32,
                  color: AppColors.secondaryColor,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Virtual Tour Images',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Virtual Tour Images Grid
        if (_virtualTourImages.isNotEmpty) ...[
          const Text(
            'Virtual Tour Photos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _virtualTourImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.secondaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.file(
                        _virtualTourImages[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Virtual Tour Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeVirtualTourImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
        ],
        
        // Image Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Image Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Regular Photos: ${_selectedImages.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Virtual Tour Photos: ${_virtualTourImages.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Total Images: ${_selectedImages.length + _virtualTourImages.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Image Upload Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Photo Tips',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• Add at least 3-5 high-quality photos\n'
                '• Include photos of all rooms\n'
                '• Show natural lighting\n'
                '• Virtual tour images are optional but recommended\n'
                '• Highlight unique features',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'How should interested tenants contact you?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          CustomTextField(
            controller: _contactNameController,
            label: 'Contact Name',
            hintText: 'Your name or property manager name',
            prefixIcon: Icons.person_outline,
          ),
          
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _contactPhoneController,
            label: 'Phone Number',
            hintText: 'Primary contact number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _contactEmailController,
            label: 'Email Address',
            hintText: 'contact@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _whatsappController,
            label: 'WhatsApp Number (Optional)',
            hintText: 'WhatsApp number for quick contact',
            prefixIcon: Icons.chat_outlined,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 24),
          
          // Availability Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Is this property currently available for rent?',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AuthProvider authProvider, PropertyProvider propertyProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: CustomOutlinedButton(
                  text: 'Previous',
                  onPressed: _previousStep,
                  borderColor: AppColors.primaryColor,
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),
            
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: CustomButton(
                text: _currentStep == 3 ? 'Add Property' : 'Next',
                onPressed: _currentStep == 3 
                    ? () => _addProperty(authProvider, propertyProvider)
                    : _nextStep,
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    print('Current step: $_currentStep');
    
    bool canProceed = false;
    
    switch (_currentStep) {
      case 0:
        canProceed = _validateBasicInfo();
        break;
      case 1:
        canProceed = _validateDetails();
        break;
      case 2:
        canProceed = _validateImages();
        break;
      default:
        canProceed = true;
    }
    
    if (canProceed && _currentStep < 3) {
      print('Moving to next step');
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      print('Cannot proceed: validation failed');
    }
  }

  Future<void> _pickVirtualTourImages() async {
  try {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _virtualTourImages.addAll(images.map((image) => File(image.path)).toList());
      });
      print('Added ${images.length} virtual tour images. Total: ${_virtualTourImages.length}');
    }
  } catch (e) {
    print('Error picking virtual tour images: $e');
    _showErrorSnackBar('Failed to pick virtual tour images: $e');
  }
}



List<File> _virtualTourImages = [];

// Add this method
void _removeVirtualTourImage(int index) {
  setState(() {
    _virtualTourImages.removeAt(index);
  });
}

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateBasicInfo() {
    print('Validating basic info fields manually');
    
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Property title is required');
      return false;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Property description is required');
      return false;
    }
    
    if (_addressController.text.trim().isEmpty) {
      _showErrorSnackBar('Property address is required');
      return false;
    }
    
    if (_priceController.text.trim().isEmpty) {
      _showErrorSnackBar('Property price is required');
      return false;
    }
    
    // Validate price is a number
    if (double.tryParse(_priceController.text.trim()) == null) {
      _showErrorSnackBar('Please enter a valid price');
      return false;
    }
    
    print('Basic info validation passed');
    return true;
  }

  bool _validateDetails() {
    print('Validating details fields manually');
    
    if (_bedroomsController.text.trim().isEmpty) {
      _showErrorSnackBar('Number of bedrooms is required');
      return false;
    }
    
    if (_bathroomsController.text.trim().isEmpty) {
      _showErrorSnackBar('Number of bathrooms is required');
      return false;
    }
    
    if (_areaController.text.trim().isEmpty) {
      _showErrorSnackBar('Property area is required');
      return false;
    }
    
    if (_floorController.text.trim().isEmpty) {
      _showErrorSnackBar('Floor number is required');
      return false;
    }
    
    if (_totalFloorsController.text.trim().isEmpty) {
      _showErrorSnackBar('Total floors is required');
      return false;
    }
    
    // Validate numbers
    if (int.tryParse(_bedroomsController.text.trim()) == null) {
      _showErrorSnackBar('Please enter a valid number of bedrooms');
      return false;
    }
    
    if (int.tryParse(_bathroomsController.text.trim()) == null) {
      _showErrorSnackBar('Please enter a valid number of bathrooms');
      return false;
    }
    
    if (double.tryParse(_areaController.text.trim()) == null) {
      _showErrorSnackBar('Please enter a valid area');
      return false;
    }
    
    if (int.tryParse(_floorController.text.trim()) == null) {
      _showErrorSnackBar('Please enter a valid floor number');
      return false;
    }
    
    if (int.tryParse(_totalFloorsController.text.trim()) == null) {
      _showErrorSnackBar('Please enter a valid total floors');
      return false;
    }
    
    print('Details validation passed');
    return true;
  }

  bool _validateImages() {
  print('Validating images');
  print('Selected images count: ${_selectedImages.length}');
  print('Virtual tour images count: ${_virtualTourImages.length}');
  
  // Check if either regular images or virtual tour images are present
  if (_selectedImages.isEmpty && _virtualTourImages.isEmpty) {
    _showErrorSnackBar('Please add at least one property image');
    return false;
  }
  
  print('Images validation passed');
  return true;
}

  bool _validateContact() {
    print('Validating contact info fields manually');
    
    if (_contactNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Contact name is required');
      return false;
    }
    
    if (_contactPhoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Contact phone number is required');
      return false;
    }
    
    // Basic phone validation
    if (_contactPhoneController.text.trim().length < 10) {
      _showErrorSnackBar('Please enter a valid phone number');
      return false;
    }
    
    print('Contact validation passed');
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImages() async {
  try {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });
      print('Added ${images.length} regular images. Total: ${_selectedImages.length}');
    }
  } catch (e) {
    print('Error picking images: $e');
    _showErrorSnackBar('Failed to pick images: $e');
  }
}

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
      print('Removed regular image. Remaining: ${_selectedImages.length}');

  }

Future<void> _addProperty(AuthProvider authProvider, PropertyProvider propertyProvider) async {
  print('Starting _addProperty method');
  
  // Validate all steps manually
  if (!_validateAllSteps()) {
    print('Validation failed');
    return;
  }

  try {
    final user = authProvider.user!;
    
    // Create property model (without images first)
    final property = PropertyModel(
      id: '', // Will be set by PropertyProvider
      ownerId: user.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      propertyType: _selectedPropertyType,
      price: double.parse(_priceController.text.trim()),
      priceType: _selectedPriceType,
      address: _addressController.text.trim(),
      latitude: _latitude, // TODO: Get from geocoding
      longitude: _longitude, // TODO: Get from geocoding
      images: [], // Will be populated after upload
      amenities: _selectedAmenities,
      details: PropertyDetails(
        bedrooms: int.parse(_bedroomsController.text.trim()),
        bathrooms: int.parse(_bathroomsController.text.trim()),
        areaInSqFt: double.parse(_areaController.text.trim()),
        floor: int.parse(_floorController.text.trim()),
        totalFloors: int.parse(_totalFloorsController.text.trim()),
        furnishing: _selectedFurnishing,
        parking: _parkingController.text.trim().isNotEmpty 
            ? _parkingController.text.trim() 
            : null,
        securityDeposit: _securityDepositController.text.trim().isNotEmpty 
            ? _securityDepositController.text.trim() 
            : null,
        maintenanceCharges: _maintenanceController.text.trim().isNotEmpty 
            ? _maintenanceController.text.trim() 
            : null,
      ),
      contactInfo: ContactInfo(
        name: _contactNameController.text.trim(),
        phone: _contactPhoneController.text.trim(),
        email: _contactEmailController.text.trim().isNotEmpty 
            ? _contactEmailController.text.trim() 
            : null,
        whatsapp: _whatsappController.text.trim().isNotEmpty 
            ? _whatsappController.text.trim() 
            : null,
      ),
      isAvailable: _isAvailable,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      virtualTourImages: [], // Will be populated after upload
    );

    print('Calling propertyProvider.addProperty with images');
    final success = await propertyProvider.addProperty(
      property,
      propertyImages: _selectedImages.isNotEmpty ? _selectedImages : null,
      virtualTourImages: _virtualTourImages.isNotEmpty ? _virtualTourImages : null,
    );

    if (success && mounted) {
      print('Property added successfully');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property added successfully!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else {
      print('Failed to add property');
      _showErrorSnackBar('Failed to add property. Please try again.');
    }
  } catch (e) {
    print('Error adding property: $e');
    _showErrorSnackBar('Error: $e');
  }
}
  bool _validateAllSteps() {
    print('Starting comprehensive validation');
    
    // Validate basic info
    print('Validating basic info');
    if (!_validateBasicInfo()) {
      print('Basic info validation failed');
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    // Validate details
    print('Validating details');
    if (!_validateDetails()) {
      print('Details validation failed');
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    // Validate images
    print('Validating images');
    if (!_validateImages()) {
      print('Images validation failed');
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    // Validate contact info
    print('Validating contact info');
    if (!_validateContact()) {
      print('Contact info validation failed');
      _pageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    print('All validations passed');
    return true;
  }

  Future<List<String>> _uploadImages(List<File> images, String path) async {
  List<String> urls = [];
  
  for (int i = 0; i < images.length; i++) {
    try {
      // Upload to Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('$path/$fileName');
      
      await ref.putFile(images[i]);
      final String downloadUrl = await ref.getDownloadURL();
      urls.add(downloadUrl);
    } catch (e) {
      print('Error uploading image $i: $e');
      // Continue with other images
    }
  }
  
  return urls;
}
}