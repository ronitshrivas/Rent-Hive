import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import '../../models/property_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late PropertyProvider _propertyProvider;
  
  // Filter values
  PropertyType? _selectedPropertyType;
  double? _minPrice;
  double? _maxPrice;
  String? _location;
  List<String> _selectedAmenities = [];
  FurnishingType? _selectedFurnishing;
  
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<String> _availableAmenities = [
    'WiFi',
    'AC',
    'Parking',
    'Gym',
    'Swimming Pool',
    'Elevator',
    'Security',
    'Power Backup',
    'Water Supply',
    'Laundry',
    'Kitchen',
    'Balcony',
    'Garden',
    'CCTV',
    'Intercom',
  ];

  @override
  void initState() {
    super.initState();
    _propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    _selectedPropertyType = _propertyProvider.selectedPropertyType;
    _minPrice = _propertyProvider.minPrice;
    _maxPrice = _propertyProvider.maxPrice;
    _location = _propertyProvider.location;
    _selectedAmenities = List.from(_propertyProvider.selectedAmenities);
    _selectedFurnishing = _propertyProvider.selectedFurnishing;
    
    _locationController.text = _location ?? '';
    _minPriceController.text = _minPrice?.toInt().toString() ?? '';
    _maxPriceController.text = _maxPrice?.toInt().toString() ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Type
                  _buildSectionTitle('Property Type'),
                  const SizedBox(height: 12),
                  _buildPropertyTypeFilter(),
                  
                  const SizedBox(height: 32),
                  
                  // Price Range
                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 12),
                  _buildPriceRangeFilter(),
                  
                  const SizedBox(height: 32),
                  
                  // Location
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 12),
                  _buildLocationFilter(),
                  
                  const SizedBox(height: 32),
                  
                  // Furnishing
                  _buildSectionTitle('Furnishing'),
                  const SizedBox(height: 12),
                  _buildFurnishingFilter(),
                  
                  const SizedBox(height: 32),
                  
                  // Amenities
                  _buildSectionTitle('Amenities'),
                  const SizedBox(height: 12),
                  _buildAmenitiesFilter(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Apply Filters Button
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPropertyTypeFilter() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: PropertyType.values.map((type) {
        bool isSelected = _selectedPropertyType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPropertyType = isSelected ? null : type;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primaryColor 
                  : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primaryColor 
                    : AppColors.borderColor,
              ),
            ),
            child: Text(
              type.displayName,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _minPriceController,
                label: 'Min Price',
                hintText: '0',
                prefixIcon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minPrice = value.isNotEmpty ? double.tryParse(value) : null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _maxPriceController,
                label: 'Max Price',
                hintText: '100000',
                prefixIcon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxPrice = value.isNotEmpty ? double.tryParse(value) : null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Quick price options
        Wrap(
          spacing: 8,
          children: [
            _buildQuickPriceChip('Under ₹10K', null, 10000),
            _buildQuickPriceChip('₹10K - ₹25K', 10000, 25000),
            _buildQuickPriceChip('₹25K - ₹50K', 25000, 50000),
            _buildQuickPriceChip('Above ₹50K', 50000, null),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPriceChip(String label, double? min, double? max) {
    bool isSelected = _minPrice == min && _maxPrice == max;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _minPrice = min;
          _maxPrice = max;
          _minPriceController.text = min?.toInt().toString() ?? '';
          _maxPriceController.text = max?.toInt().toString() ?? '';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryColor 
                : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? AppColors.primaryColor 
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return CustomTextField(
      controller: _locationController,
      label: 'Location',
      hintText: 'Enter city, area, or landmark',
      prefixIcon: Icons.location_on_outlined,
      onChanged: (value) {
        _location = value.isNotEmpty ? value : null;
      },
    );
  }

  Widget _buildFurnishingFilter() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: FurnishingType.values.map((type) {
        bool isSelected = _selectedFurnishing == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFurnishing = isSelected ? null : type;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primaryColor 
                  : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primaryColor 
                    : AppColors.borderColor,
              ),
            ),
            child: Text(
              type.displayName,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmenitiesFilter() {
    return Wrap(
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
              color: isSelected 
                  ? AppColors.primaryColor 
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primaryColor 
                    : AppColors.borderColor,
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
                    color: isSelected 
                        ? Colors.white 
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomActions() {
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
            Expanded(
              child: CustomOutlinedButton(
                text: 'Reset',
                onPressed: _clearAllFilters,
                borderColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Apply Filters',
                onPressed: _applyFilters,
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedPropertyType = null;
      _minPrice = null;
      _maxPrice = null;
      _location = null;
      _selectedAmenities.clear();
      _selectedFurnishing = null;
      
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    _propertyProvider.setPropertyTypeFilter(_selectedPropertyType);
    _propertyProvider.setPriceFilter(_minPrice, _maxPrice);
    _propertyProvider.setLocationFilter(_location);
    _propertyProvider.setAmenitiesFilter(_selectedAmenities);
    _propertyProvider.setFurnishingFilter(_selectedFurnishing);
    
    Navigator.pop(context);
  }
}