import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/admin/providers/admin_provider.dart';
import 'package:renthive/models/property_model.dart';
import 'package:renthive/models/user_model.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PropertyModel> _filteredProperties = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProperties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties() {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final query = _searchController.text;

    setState(() {
      _filteredProperties = provider.searchProperties(query);

      // Apply availability filter
      if (_filter == 'available') {
        _filteredProperties =
            _filteredProperties
                .where((property) => property.isAvailable)
                .toList();
      } else if (_filter == 'rented') {
        _filteredProperties =
            _filteredProperties
                .where((property) => !property.isAvailable)
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (_filteredProperties.isEmpty && _searchController.text.isEmpty) {
          _filteredProperties = provider.allProperties;
          _filterProperties();
        }

        final availableCount =
            provider.allProperties.where((p) => p.isAvailable).length;
        final rentedCount = provider.allProperties.length - availableCount;

        return Scaffold(
          body: Column(
            children: [
              // Search and Filter Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search properties by title, location...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterProperties();
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Filter dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filter,
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Properties'),
                            ),
                            DropdownMenuItem(
                              value: 'available',
                              child: Text('Available'),
                            ),
                            DropdownMenuItem(
                              value: 'rented',
                              child: Text('Rented'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filter = value!;
                              _filterProperties();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                      title: 'Total',
                      count: provider.allProperties.length,
                      icon: Icons.home,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'Available',
                      count: availableCount,
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'Rented',
                      count: rentedCount,
                      icon: Icons.cancel,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Properties List
              Expanded(
                child:
                    provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredProperties.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No properties found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => _refreshProperties(provider),
                          child: ListView.builder(
                            itemCount: _filteredProperties.length,
                            itemBuilder: (context, index) {
                              final property = _filteredProperties[index];
                              final owner = provider.allUsers.firstWhere(
                                (user) => user.id == property.ownerId,
                                orElse:
                                    () => UserModel(
                                      id: '',
                                      name: 'Unknown',
                                      email: '',
                                      phone: '',
                                      userType: UserType.propertyOwner,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                      isVerified: false,
                                    ),
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading:
                                      property.images.isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              property.images.first,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stack) =>
                                                      Container(
                                                        width: 60,
                                                        height: 60,
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.error,
                                                        ),
                                                      ),
                                            ),
                                          )
                                          : Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.home,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  title: Text(
                                    property.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${property.propertyType.displayName} • \$${property.price}/${property.priceType.displayName}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        property.address,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Owner: ${owner.name}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              property.isAvailable
                                                  ? Colors.green[50]
                                                  : Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color:
                                                property.isAvailable
                                                    ? Colors.green
                                                    : Colors.orange,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          property.isAvailable
                                              ? 'Available'
                                              : 'Rented',
                                          style: TextStyle(
                                            color:
                                                property.isAvailable
                                                    ? Colors.green
                                                    : Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        tooltip: 'View Details',
                                        onPressed:
                                            () => _viewPropertyDetails(
                                              property,
                                              owner,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          property.isAvailable
                                              ? Icons.block
                                              : Icons.check_circle,
                                        ),
                                        color:
                                            property.isAvailable
                                                ? Colors.orange
                                                : Colors.green,
                                        tooltip:
                                            property.isAvailable
                                                ? 'Mark as Rented'
                                                : 'Mark as Available',
                                        onPressed:
                                            () => _togglePropertyAvailability(
                                              property,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        tooltip: 'Delete Property',
                                        onPressed:
                                            () => _deleteProperty(property.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _refreshProperties(provider),
            tooltip: 'Refresh Properties',
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  Future<void> _viewPropertyDetails(
    PropertyModel property,
    UserModel owner,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(property.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (property.images.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        property.images.first,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stack) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _DetailRow(
                    label: 'Type',
                    value: property.propertyType.displayName,
                  ),
                  _DetailRow(
                    label: 'Price',
                    value:
                        '\$${property.price}/${property.priceType.displayName}',
                  ),
                  _DetailRow(label: 'Address', value: property.address),
                  _DetailRow(
                    label: 'Bedrooms',
                    value: '${property.details.bedrooms}',
                  ),
                  _DetailRow(
                    label: 'Bathrooms',
                    value: '${property.details.bathrooms}',
                  ),
                  _DetailRow(
                    label: 'Area',
                    value: '${property.details.areaInSqFt} sq ft',
                  ),
                  _DetailRow(
                    label: 'Furnishing',
                    value: property.details.furnishing.displayName,
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: property.isAvailable ? 'Available' : 'Rented',
                  ),
                  _DetailRow(label: 'Views', value: '${property.views}'),
                  _DetailRow(
                    label: 'Rating',
                    value:
                        '${property.rating.toStringAsFixed(1)} (${property.totalRatings} ratings)',
                  ),
                  const Divider(height: 24),
                  _DetailRow(label: 'Owner', value: owner.name),
                  _DetailRow(label: 'Owner Email', value: owner.email),
                  _DetailRow(label: 'Owner Phone', value: owner.phone),
                  if (property.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(property.description),
                  ],
                  if (property.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Amenities:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          property.amenities
                              .map(
                                (amenity) => Chip(
                                  label: Text(
                                    amenity,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.blue[50],
                                  padding: EdgeInsets.zero,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _togglePropertyAvailability(PropertyModel property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Property Status'),
            content: Text(
              'Mark this property as ${property.isAvailable ? "rented" : "available"}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      final success = await provider.togglePropertyAvailability(
        property.id,
        !property.isAvailable,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Property status updated' : 'Error updating property',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _filterProperties();
        }
      }
    }
  }

  Future<void> _deleteProperty(String propertyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Property'),
            content: const Text(
              'Are you sure you want to delete this property? '
              'This will also delete all related chat rooms and messages. '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      final success = await provider.deleteProperty(propertyId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Property deleted successfully'
                  : 'Error deleting property',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _filterProperties();
        }
      }
    }
  }

  Future<void> _refreshProperties(AdminProvider provider) async {
    await provider.refreshProperties();
    _filterProperties();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Properties refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
