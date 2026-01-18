import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/property_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_overlay.dart';
import '../property/property_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.loadProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, authProvider, propertyProvider, child) {
        if (authProvider.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final favoritePropertyIds = authProvider.user!.favoriteProperties;
        final favoriteProperties = propertyProvider.properties
            .where((property) => favoritePropertyIds.contains(property.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Favorites'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            automaticallyImplyLeading: false,
            actions: [
              if (favoriteProperties.isNotEmpty)
                IconButton(
                  onPressed: () => _showClearAllDialog(authProvider),
                  icon: const Icon(Icons.clear_all_rounded),
                  tooltip: 'Clear All',
                ),
            ],
          ),
          body: LoadingOverlay(
            isLoading: propertyProvider.isLoading,
            child: RefreshIndicator(
              onRefresh: () async {
                await propertyProvider.loadProperties();
              },
              color: AppColors.primaryColor,
              child: favoriteProperties.isEmpty
                  ? _buildEmptyState()
                  : _buildFavoritesList(favoriteProperties, authProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Properties you save will appear here.\nStart exploring to find your perfect place!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to search/home
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.search_rounded),
              label: const Text('Explore Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
    List<PropertyModel> favoriteProperties,
    AuthProvider authProvider,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: AppColors.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${favoriteProperties.length} Saved Properties',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        // Properties List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: favoriteProperties.length,
            itemBuilder: (context, index) {
              final property = favoriteProperties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FavoritePropertyCard(
                  property: property,
                  onTap: () => _navigateToPropertyDetail(property),
                  onRemoveFavorite: () => _removeFavorite(property.id, authProvider),
                ),
              );
            },
          ),
        ),
      ],
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

  void _removeFavorite(String propertyId, AuthProvider authProvider) {
    authProvider.toggleFavoriteProperty(propertyId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Removed from favorites'),
        backgroundColor: AppColors.errorColor,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            authProvider.toggleFavoriteProperty(propertyId);
          },
        ),
      ),
    );
  }

  void _showClearAllDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear All Favorites?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will remove all properties from your favorites list. This action cannot be undone.',
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
              _clearAllFavorites(authProvider);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFavorites(AuthProvider authProvider) {
    final favoriteIds = List<String>.from(authProvider.user!.favoriteProperties);
    
    // Clear all favorites
    for (String propertyId in favoriteIds) {
      authProvider.toggleFavoriteProperty(propertyId);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All favorites cleared'),
        backgroundColor: AppColors.errorColor,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Restore all favorites
            for (String propertyId in favoriteIds) {
              authProvider.toggleFavoriteProperty(propertyId);
            }
          },
        ),
      ),
    );
  }
}

class FavoritePropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onRemoveFavorite;

  const FavoritePropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.borderColor,
                    child: property.images.isNotEmpty
                        ? Image.network(
                            property.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: AppColors.textLight,
                                ),
                              );
                            },
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
                
                // Favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onRemoveFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.errorColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
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

                  // Type and details
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price and rating
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
                      if (property.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.ratingColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}