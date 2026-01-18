import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:renthive/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_overlay.dart';
import '../property/add_property_screen.dart';
import '../property/property_detail_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOwnerData();
    });
  }

  void _loadOwnerData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      propertyProvider.loadOwnerProperties(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PropertyProvider>(
      builder: (context, authProvider, propertyProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: LoadingOverlay(
            isLoading: propertyProvider.isLoading,
            child: RefreshIndicator(
              onRefresh: () async {
                await propertyProvider.loadOwnerProperties(user.id);
              },
              color: AppColors.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Header
                  _buildHeader(user),

                  // Statistics Cards
                  SliverToBoxAdapter(
                    child: _buildStatisticsCards(propertyProvider, user.id),
                  ),

                  // Quick Actions
                  SliverToBoxAdapter(child: _buildQuickActions()),

                  // Recent Properties
                  SliverToBoxAdapter(
                    child: _buildRecentProperties(
                      propertyProvider.ownerProperties,
                    ),
                  ),

                  // Bottom Padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddProperty(),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Property'),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel user) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      backgroundColor: AppColors.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage:
                            user.profileImage != null
                                ? CachedNetworkImageProvider(user.profileImage!)
                                : null,
                        child:
                            user.profileImage == null
                                ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),

                      const SizedBox(width: 12),

                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notifications
                      IconButton(
                        onPressed: () {
                          // Navigate to notifications
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(
    PropertyProvider propertyProvider,
    String ownerId,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: FirebaseService().getOwnerAnalytics(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Error loading analytics',
                style: TextStyle(color: AppColors.errorColor),
              ),
            ),
          );
        }

        final analytics = snapshot.data!;
        final totalProperties = analytics['totalProperties'] as int;
        final availableProperties = analytics['availableProperties'] as int;
        final totalViews = analytics['totalViews'] as int;
        final averageRating = analytics['averageRating'] as double;
        final properties = analytics['properties'] as List<PropertyModel>;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // First Row
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatCard(
                      context,
                      'Total Properties',
                      totalProperties.toString(),
                      Icons.home_rounded,
                      AppColors.primaryColor,
                      () => _showAllPropertiesBottomSheet(context, properties),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildClickableStatCard(
                      context,
                      'Available',
                      availableProperties.toString(),
                      Icons.check_circle_rounded,
                      AppColors.successColor,
                      () => _showAvailablePropertiesBottomSheet(
                        context,
                        properties,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Second Row
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatCard(
                      context,
                      'Total Views',
                      totalViews.toString(),
                      Icons.visibility_rounded,
                      AppColors.infoColor,
                      () => _showViewsDetailsBottomSheet(context, properties),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildClickableStatCard(
                      context,
                      'Avg. Rating',
                      averageRating.toStringAsFixed(1),
                      Icons.star_rounded,
                      AppColors.ratingColor,
                      () => _showRatingsDetailsBottomSheet(context, properties),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Clickable stat card with ripple effect
  Widget _buildClickableStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textLight,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show all properties bottom sheet
  void _showAllPropertiesBottomSheet(
    BuildContext context,
    List<PropertyModel> properties,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All Properties (${properties.length})',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      // Properties list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: properties.length,
                          itemBuilder: (context, index) {
                            final property = properties[index];
                            return _buildPropertyDetailCard(context, property);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // Show available properties bottom sheet
  void _showAvailablePropertiesBottomSheet(
    BuildContext context,
    List<PropertyModel> allProperties,
  ) {
    final availableProperties =
        allProperties.where((p) => p.isAvailable).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.successColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Available Properties (${availableProperties.length})',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      Expanded(
                        child:
                            availableProperties.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.home_outlined,
                                        size: 64,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No available properties',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount: availableProperties.length,
                                  itemBuilder: (context, index) {
                                    final property = availableProperties[index];
                                    return _buildPropertyDetailCard(
                                      context,
                                      property,
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // Show views details bottom sheet
  void _showViewsDetailsBottomSheet(
    BuildContext context,
    List<PropertyModel> properties,
  ) {
    // Sort by views (highest first)
    final sortedProperties = List<PropertyModel>.from(properties)
      ..sort((a, b) => b.views.compareTo(a.views));

    final totalViews = properties.fold(0, (sum, p) => sum + p.views);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.visibility_rounded,
                                    color: AppColors.infoColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Property Views',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Total: $totalViews views',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.infoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildViewStat(
                                    'Highest',
                                    sortedProperties.first.views.toString(),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: AppColors.borderColor,
                                  ),
                                  _buildViewStat(
                                    'Average',
                                    (totalViews / properties.length)
                                        .toStringAsFixed(0),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: AppColors.borderColor,
                                  ),
                                  _buildViewStat(
                                    'Lowest',
                                    sortedProperties.last.views.toString(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: sortedProperties.length,
                          itemBuilder: (context, index) {
                            final property = sortedProperties[index];
                            return _buildPropertyDetailCard(
                              context,
                              property,
                              showViews: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildViewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.infoColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Show ratings details bottom sheet
  void _showRatingsDetailsBottomSheet(
    BuildContext context,
    List<PropertyModel> properties,
  ) {
    // Sort by rating (highest first)
    final sortedProperties = List<PropertyModel>.from(properties)
      ..sort((a, b) => b.rating.compareTo(a.rating));

    final propertiesWithRatings =
        sortedProperties.where((p) => p.rating > 0).toList();
    final averageRating =
        propertiesWithRatings.isEmpty
            ? 0.0
            : propertiesWithRatings.fold(0.0, (sum, p) => sum + p.rating) /
                propertiesWithRatings.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.ratingColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.ratingColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Property Ratings',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Average: ${averageRating.toStringAsFixed(1)} ⭐',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.ratingColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildRatingStat(
                                    'Rated',
                                    '${propertiesWithRatings.length}',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: AppColors.borderColor,
                                  ),
                                  _buildRatingStat(
                                    'Unrated',
                                    '${properties.length - propertiesWithRatings.length}',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: AppColors.borderColor,
                                  ),
                                  _buildRatingStat(
                                    'Best',
                                    propertiesWithRatings.isEmpty
                                        ? '0.0'
                                        : propertiesWithRatings.first.rating
                                            .toStringAsFixed(1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      Expanded(
                        child:
                            propertiesWithRatings.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.star_border_rounded,
                                        size: 64,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No ratings yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount: propertiesWithRatings.length,
                                  itemBuilder: (context, index) {
                                    final property =
                                        propertiesWithRatings[index];
                                    return _buildPropertyDetailCard(
                                      context,
                                      property,
                                      showRating: true,
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildRatingStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ratingColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Build property detail card
  Widget _buildPropertyDetailCard(
    BuildContext context,
    PropertyModel property, {
    bool showViews = false,
    bool showRating = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailScreen(property: property),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.borderColor,
                child:
                    property.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: property.images.first,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Center(child: Icon(Icons.error)),
                        )
                        : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.textLight,
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // Property Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              property.isAvailable
                                  ? AppColors.successColor.withOpacity(0.1)
                                  : AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          property.isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color:
                                property.isAvailable
                                    ? AppColors.successColor
                                    : AppColors.errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${property.details.bedrooms} BHK',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${property.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      if (showViews)
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility_rounded,
                              size: 14,
                              color: AppColors.infoColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${property.views}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.infoColor,
                              ),
                            ),
                          ],
                        ),
                      if (showRating && property.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.ratingColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ratingColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: color.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(
  //                 icon,
  //                 color: color,
  //                 size: 20,
  //               ),
  //             ),
  //             const Spacer(),
  //           ],
  //         ),

  //         const SizedBox(height: 12),

  //         Text(
  //           value,
  //           style: TextStyle(
  //             fontSize: 24,
  //             fontWeight: FontWeight.bold,
  //             color: color,
  //           ),
  //         ),

  //         const SizedBox(height: 4),

  //         Text(
  //           title,
  //           style: const TextStyle(
  //             fontSize: 12,
  //             color: AppColors.textSecondary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Add Property',
                  'List a new property',
                  Icons.add_home_rounded,
                  AppColors.primaryColor,
                  () => _navigateToAddProperty(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Analytics',
                  'View performance',
                  Icons.analytics_rounded,
                  AppColors.secondaryColor,
                  () {
                    // Navigate to analytics
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Messages',
                  'Chat with tenants',
                  Icons.chat_rounded,
                  AppColors.infoColor,
                  () {
                    // Navigate to messages
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Settings',
                  'Manage account',
                  Icons.settings_rounded,
                  AppColors.textSecondary,
                  () {
                    // Navigate to settings
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProperties(List<PropertyModel> properties) {
    if (properties.isEmpty) {
      return _buildEmptyProperties();
    }

    final recentProperties = properties.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (properties.length > 5)
                TextButton(
                  onPressed: () {
                    // Navigate to all properties
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentProperties.length,
            itemBuilder: (context, index) {
              final property = recentProperties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPropertyTile(property),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(PropertyModel property) {
    return GestureDetector(
      onTap: () => _navigateToPropertyDetail(property),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.borderColor,
                child:
                    property.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: property.images.first,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Center(child: Icon(Icons.error)),
                        )
                        : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.textLight,
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // Property Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₹${property.price.toStringAsFixed(0)}/${property.priceType.displayName.split(' ').last.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Status & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        property.isAvailable
                            ? AppColors.successColor.withOpacity(0.1)
                            : AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          property.isAvailable
                              ? AppColors.successColor
                              : AppColors.errorColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${property.views}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProperties() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No Properties Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Start by adding your first property to rent out',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => _navigateToAddProperty(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Property'),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _navigateToAddProperty() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
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
