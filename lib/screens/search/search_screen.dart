import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:renthive/providers/location_provider.dart';
import 'package:renthive/screens/home/home_screen.dart';
import 'package:renthive/screens/search/filter_search.dart';
import '../../providers/property_provider.dart';
import '../../models/property_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../property/property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;
  
  List<PropertyModel> _searchResults = [];
  bool _isSearching = false;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Search Header
                _buildSearchHeader(propertyProvider),
                
                // Filter Tabs
                _buildFilterTabs(),
                
                // Search Results
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSearchResults(propertyProvider),
                      _buildMapView(propertyProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader(PropertyProvider propertyProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
              ),
              
              Expanded(
                child: CustomSearchField(
                  controller: _searchController,
                  hintText: 'Search rooms, hostels, PG...',
                  onChanged: _onSearchChanged,
                  onSubmitted: _performSearch,
                  showClearButton: true,
                  margin: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: () => _openFilterScreen(propertyProvider),
                icon: Stack(
                  children: [
                    const Icon(Icons.tune_rounded),
                    if (_hasActiveFilters(propertyProvider))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                color: AppColors.textPrimary,
              ),
            ],
          ),
          
          if (_hasActiveFilters(propertyProvider)) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(propertyProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryColor,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: const [
          Tab(text: 'List View'),
          Tab(text: 'Map View'),
        ],
      ),
    );
  }

  Widget _buildSearchResults(PropertyProvider propertyProvider) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    List<PropertyModel> results = _currentSearchQuery.isNotEmpty 
        ? _searchResults 
        : propertyProvider.properties;

    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final property = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PropertyListTile(
            property: property,
            onTap: () => _navigateToPropertyDetail(property),
          ),
        );
      },
    );
  }

 Widget _buildMapView(PropertyProvider propertyProvider) {
  List<PropertyModel> results = _currentSearchQuery.isNotEmpty 
      ? _searchResults 
      : propertyProvider.properties;

  if (results.isEmpty) {
    return _buildEmptyState();
  }

  return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(27.7172, 85.3240), // Use initialCenter instead of center
      initialZoom: 12.0,
      maxZoom: 18.0,
      minZoom: 5.0,
    ),
    children: [
      // Map tiles
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.renthive',
        maxZoom: 18,
        subdomains: const ['a', 'b', 'c'],
      ),
      
      // Property markers
      MarkerLayer(
        markers: results.map((property) {
          return Marker(
            point: LatLng(
              property.latitude != 0 ? property.latitude : 27.7172,
              property.longitude != 0 ? property.longitude : 85.3240,
            ),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showPropertyPopup(property),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      
      // User location marker (if available)
      if (Provider.of<LocationProvider>(context, listen: false).currentLocation != null)
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(
                Provider.of<LocationProvider>(context, listen: false).currentLocation!.latitude,
                Provider.of<LocationProvider>(context, listen: false).currentLocation!.longitude,
              ),
              width: 30,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

void _showPropertyPopup(PropertyModel property) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              color: AppColors.borderColor,
              child: property.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: property.images.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: AppColors.textLight,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Property Title
          Text(
            property.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Property Details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  property.propertyType.displayName,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${property.details.bedrooms} BHK • ${property.details.furnishing.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price and View Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${property.price.toStringAsFixed(0)}/${property.priceType.displayName.split(' ').last.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToPropertyDetail(property);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentSearchQuery.isNotEmpty 
                  ? Icons.search_off_rounded 
                  : Icons.home_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _currentSearchQuery.isNotEmpty 
                  ? 'No Properties Found' 
                  : 'Start Your Search',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _currentSearchQuery.isNotEmpty 
                  ? 'Try adjusting your search criteria or filters'
                  : 'Search for rooms, hostels, and accommodations',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (_currentSearchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: 'Clear Filters',
                onPressed: () {
                  final propertyProvider = Provider.of<PropertyProvider>(
                    context, 
                    listen: false,
                  );
                  propertyProvider.clearFilters();
                  _clearSearch();
                },
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(PropertyProvider propertyProvider) {
    List<Widget> filterChips = [];

    if (propertyProvider.selectedPropertyType != null) {
      filterChips.add(_buildFilterChip(
        propertyProvider.selectedPropertyType!.displayName,
        () => propertyProvider.setPropertyTypeFilter(null),
      ));
    }

    if (propertyProvider.minPrice != null || propertyProvider.maxPrice != null) {
      String priceText = '';
      if (propertyProvider.minPrice != null && propertyProvider.maxPrice != null) {
        priceText = '₹${propertyProvider.minPrice!.toInt()}-${propertyProvider.maxPrice!.toInt()}';
      } else if (propertyProvider.minPrice != null) {
        priceText = '₹${propertyProvider.minPrice!.toInt()}+';
      } else {
        priceText = 'Up to ₹${propertyProvider.maxPrice!.toInt()}';
      }
      
      filterChips.add(_buildFilterChip(
        priceText,
        () => propertyProvider.setPriceFilter(null, null),
      ));
    }

    if (propertyProvider.location != null && propertyProvider.location!.isNotEmpty) {
      filterChips.add(_buildFilterChip(
        propertyProvider.location!,
        () => propertyProvider.setLocationFilter(null),
      ));
    }

    if (propertyProvider.selectedFurnishing != null) {
      filterChips.add(_buildFilterChip(
        propertyProvider.selectedFurnishing!.displayName,
        () => propertyProvider.setFurnishingFilter(null),
      ));
    }

    if (propertyProvider.selectedAmenities.isNotEmpty) {
      filterChips.add(_buildFilterChip(
        '${propertyProvider.selectedAmenities.length} Amenities',
        () => propertyProvider.setAmenitiesFilter([]),
      ));
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filterChips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => filterChips[index],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentSearchQuery = query;
    });
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _performSearch(query);
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final results = propertyProvider.searchProperties(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearchQuery = '';
      _searchResults = [];
      _isSearching = false;
    });
  }

  bool _hasActiveFilters(PropertyProvider propertyProvider) {
    return propertyProvider.selectedPropertyType != null ||
           propertyProvider.minPrice != null ||
           propertyProvider.maxPrice != null ||
           (propertyProvider.location != null && propertyProvider.location!.isNotEmpty) ||
           propertyProvider.selectedFurnishing != null ||
           propertyProvider.selectedAmenities.isNotEmpty;
  }

  void _openFilterScreen(PropertyProvider propertyProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
      ),
    );
  }

  void _navigateToPropertyDetail(PropertyModel property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
      ),
    );
  }
}