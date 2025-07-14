import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/property_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../chat/chat_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _imagePageController = PageController();
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    const threshold = 200.0;
    bool isCollapsed = _scrollController.offset > threshold;
    
    if (isCollapsed != _isAppBarCollapsed) {
      setState(() {
        _isAppBarCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final bool isFavorite = authProvider.isFavoriteProperty(widget.property.id);
        
        return Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar with Images
              _buildSliverAppBar(authProvider, isFavorite),
              
              // Property Details
              SliverToBoxAdapter(
                child: _buildPropertyDetails(),
              ),
            ],
          ),
          
          // Bottom Action Bar
          bottomNavigationBar: _buildBottomActionBar(authProvider),
        );
      },
    );
  }

  Widget _buildSliverAppBar(AuthProvider authProvider, bool isFavorite) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _toggleFavorite(authProvider),
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_outline,
              color: isFavorite ? AppColors.errorColor : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _shareProperty,
            icon: const Icon(
              Icons.share_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageCarousel(),
      ),
      title: _isAppBarCollapsed
          ? Text(
              widget.property.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildImageCarousel() {
    if (widget.property.images.isEmpty) {
      return Container(
        color: AppColors.borderColor,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: AppColors.textLight,
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _imagePageController,
          itemCount: widget.property.images.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: widget.property.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.borderColor,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.borderColor,
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            );
          },
        ),
        
        // Virtual Tour Button
        Positioned(
  bottom: 16,
  left: 16,
  child: GestureDetector(
    onTap: () => _openVirtualTour(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.property.virtualTourImages.isNotEmpty 
            ? AppColors.secondaryColor.withOpacity(0.9)
            : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.view_in_ar_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            widget.property.virtualTourImages.isNotEmpty 
                ? 'Virtual Tour' 
                : 'View Gallery',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
),
        
        // Page Indicator
        if (widget.property.images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SmoothPageIndicator(
                controller: _imagePageController,
                count: widget.property.images.length,
                effect: const WormEffect(
                  dotColor: Colors.white54,
                  activeDotColor: Colors.white,
                  dotHeight: 6,
                  dotWidth: 6,
                  spacing: 4,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPropertyDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          _buildTitleSection(),
          
          const SizedBox(height: 20),
          
          // Quick Info
          _buildQuickInfo(),
          
          const SizedBox(height: 24),
          
          // Description
          _buildDescription(),
          
          const SizedBox(height: 24),
          
          // Amenities
          _buildAmenities(),
          
          const SizedBox(height: 24),
          
          // Property Details
          _buildPropertyDetailsSection(),
          
          const SizedBox(height: 24),
          
          // Location
          _buildLocation(),
          
          const SizedBox(height: 24),
          
          // Rules and Policies
          _buildRulesAndPolicies(),
          
          const SizedBox(height: 24),
          
          // Contact Information
          _buildContactInfo(),
          
          const SizedBox(height: 100), // Bottom padding for action bar
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.property.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (widget.property.rating > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.ratingColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.property.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ratingColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
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
                widget.property.address,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Text(
          '₹${widget.property.price.toStringAsFixed(0)}/${widget.property.priceType.displayName.split(' ').last.toLowerCase()}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfo() {
    return Row(
      children: [
        _buildInfoChip(
          Icons.bed_rounded,
          '${widget.property.details.bedrooms} BHK',
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          Icons.bathtub_outlined,
          '${widget.property.details.bathrooms} Bath',
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          Icons.square_foot_outlined,
          '${widget.property.details.areaInSqFt.toInt()} sq ft',
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.property.description,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    if (widget.property.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.property.amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                amenity,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Property Type', widget.property.propertyType.displayName),
        _buildDetailRow('Furnishing', widget.property.details.furnishing.displayName),
        _buildDetailRow('Floor', '${widget.property.details.floor} of ${widget.property.details.totalFloors}'),
        if (widget.property.details.parking != null)
          _buildDetailRow('Parking', widget.property.details.parking!),
        if (widget.property.details.securityDeposit != null)
          _buildDetailRow('Security Deposit', widget.property.details.securityDeposit!),
        if (widget.property.details.maintenanceCharges != null)
          _buildDetailRow('Maintenance', widget.property.details.maintenanceCharges!),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.borderColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 8),
                Text(
                  'Map View Coming Soon',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRulesAndPolicies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rules & Policies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• No smoking inside the property',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• No pets allowed',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Visitors allowed with prior notice',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Quiet hours: 10 PM - 7 AM',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              _buildContactRow(
                Icons.person_outline,
                'Contact Person',
                widget.property.contactInfo.name,
              ),
              const Divider(height: 24),
              _buildContactRow(
                Icons.phone_outlined,
                'Phone',
                widget.property.contactInfo.phone,
                onTap: () => _makePhoneCall(widget.property.contactInfo.phone),
              ),
              if (widget.property.contactInfo.email != null) ...[
                const Divider(height: 24),
                _buildContactRow(
                  Icons.email_outlined,
                  'Email',
                  widget.property.contactInfo.email!,
                  onTap: () => _sendEmail(widget.property.contactInfo.email!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onTap != null 
                        ? AppColors.primaryColor 
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(AuthProvider authProvider) {
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
            // Call Button
            Expanded(
              child: CustomOutlinedButton(
                text: 'Call',
                icon: Icons.phone_outlined,
                onPressed: () => _makePhoneCall(widget.property.contactInfo.phone),
                borderColor: AppColors.primaryColor,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Chat Button
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Message',
                icon: Icons.chat_outlined,
                onPressed: () => _startChat(authProvider),
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(AuthProvider authProvider) {
    authProvider.toggleFavoriteProperty(widget.property.id);
    
    final isFavorite = authProvider.isFavoriteProperty(widget.property.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite 
              ? 'Added to favorites' 
              : 'Removed from favorites',
        ),
        backgroundColor: isFavorite 
            ? AppColors.successColor 
            : AppColors.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareProperty() {
    // TODO: Implement property sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }

  void _openVirtualTour() {
  if (widget.property.virtualTourImages.isNotEmpty || widget.property.images.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VirtualTourScreen(
          property: widget.property,
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No images available for this property'),
      ),
    );
  }
}

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Inquiry about ${widget.property.title}',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email'),
          ),
        );
      }
    }
  }

  Future<void> _startChat(AuthProvider authProvider) async {
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to start a conversation'),
        ),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final participants = [authProvider.user!.id, widget.property.ownerId];
    
    final chatRoomId = await chatProvider.createOrGetChatRoom(
      participants: participants,
      propertyId: widget.property.id,
    );

    if (chatRoomId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            otherUserId: widget.property.ownerId,
            propertyId: widget.property.id,
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start conversation'),
          ),
        );
      }
    }
  }
}

// Virtual Tour Screen Implementation
class VirtualTourScreen extends StatefulWidget {
  final PropertyModel property;

  const VirtualTourScreen({
    super.key,
    required this.property,
  });

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<String> _allImages;
  late List<String> _imageLabels;

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  void _initializeImages() {
    _allImages = [];
    _imageLabels = [];
    
    // Add virtual tour images first
    if (widget.property.virtualTourImages.isNotEmpty) {
      _allImages.addAll(widget.property.virtualTourImages);
      for (int i = 0; i < widget.property.virtualTourImages.length; i++) {
        _imageLabels.add('Virtual Tour ${i + 1}');
      }
    }
    
    // Add regular images
    if (widget.property.images.isNotEmpty) {
      _allImages.addAll(widget.property.images);
      for (int i = 0; i < widget.property.images.length; i++) {
        _imageLabels.add('Gallery ${i + 1}');
      }
    }
    
    // If no images, use placeholder
    if (_allImages.isEmpty) {
      _allImages.add('https://via.placeholder.com/800x600?text=No+Images');
      _imageLabels.add('No Images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.property.virtualTourImages.isNotEmpty 
              ? 'Virtual Tour' 
              : 'Property Gallery',
        ),
        actions: [
          if (widget.property.virtualTourImages.isNotEmpty)
            IconButton(
              onPressed: () => _showVirtualTourInfo(),
              icon: const Icon(Icons.info_outline),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Images PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _allImages.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: _allImages[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Navigation and Info Overlay
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Current Image Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _imageLabels[_currentIndex],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentIndex + 1} / ${_allImages.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavButton(
                      Icons.arrow_back_ios_rounded,
                      _currentIndex > 0,
                      _previousImage,
                    ),
                    const SizedBox(width: 32),
                    _buildNavButton(
                      Icons.fullscreen_rounded,
                      true,
                      _toggleFullscreen,
                    ),
                    const SizedBox(width: 32),
                    _buildNavButton(
                      Icons.arrow_forward_ios_rounded,
                      _currentIndex < _allImages.length - 1,
                      _nextImage,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Property Info Panel
          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.property.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.property.price.toStringAsFixed(0)}/${widget.property.priceType.displayName.split(' ').last.toLowerCase()}',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Virtual Tour Badge
          if (_currentIndex < widget.property.virtualTourImages.length)
            Positioned(
              top: 200,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_in_ar_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Virtual Tour',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < _allImages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleFullscreen() {
    // TODO: Implement fullscreen toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fullscreen mode coming soon!'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }

  void _showVirtualTourInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Virtual Tour'),
        content: const Text(
          'Navigate through the virtual tour using swipe gestures or navigation buttons. Pinch to zoom and explore each area in detail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}