import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/models/user_model.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final query = _searchController.text;

    setState(() {
      _filteredUsers = provider.searchUsers(query);

      // Apply type filter
      if (_filterType == 'owner') {
        _filteredUsers =
            _filteredUsers
                .where((user) => user.userType == UserType.propertyOwner)
                .toList();
      } else if (_filterType == 'seeker') {
        _filteredUsers =
            _filteredUsers
                .where((user) => user.userType == UserType.roomSeeker)
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (_filteredUsers.isEmpty && _searchController.text.isEmpty) {
          _filteredUsers = provider.allUsers;
        }

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
                          hintText: 'Search by name, email, or phone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterUsers();
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
                          value: _filterType,
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Users'),
                            ),
                            DropdownMenuItem(
                              value: 'owner',
                              child: Text('Property Owners'),
                            ),
                            DropdownMenuItem(
                              value: 'seeker',
                              child: Text('Room Seekers'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterType = value!;
                              _filterUsers();
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
                      title: 'Total Users',
                      count: provider.allUsers.length,
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'Property Owners',
                      count:
                          provider.allUsers
                              .where(
                                (u) => u.userType == UserType.propertyOwner,
                              )
                              .length,
                      icon: Icons.business,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'Room Seekers',
                      count:
                          provider.allUsers
                              .where((u) => u.userType == UserType.roomSeeker)
                              .length,
                      icon: Icons.person,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Users List
              Expanded(
                child:
                    provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredUsers.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => _refreshUsers(provider),
                          child: ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        user.userType == UserType.propertyOwner
                                            ? Colors.green
                                            : Colors.blue,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(user.name)),
                                      if (user.isVerified)
                                        const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${user.userType.displayName} • ${user.email}',
                                      ),
                                      Text(
                                        'Phone: ${user.phone}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        tooltip: 'View Details',
                                        onPressed: () => _viewUserDetails(user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        tooltip: 'Delete User',
                                        onPressed: () => _deleteUser(user.id),
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
            onPressed: () => _refreshUsers(provider),
            tooltip: 'Refresh Users',
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  Future<void> _viewUserDetails(UserModel user) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final userProperties =
        provider.allProperties
            .where((prop) => prop.ownerId == user.id)
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text('User Details - ${user.name}')),
                if (user.isVerified)
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DetailRow(label: 'Email', value: user.email),
                  _DetailRow(label: 'Phone', value: user.phone),
                  _DetailRow(
                    label: 'User Type',
                    value: user.userType.displayName,
                  ),
                  _DetailRow(
                    label: 'Joined',
                    value: user.createdAt.toString().split('.')[0],
                  ),
                  _DetailRow(
                    label: 'Verified',
                    value: user.isVerified ? 'Yes' : 'No',
                  ),
                  _DetailRow(
                    label: 'Rating',
                    value:
                        '${user.rating.toStringAsFixed(1)} (${user.totalRatings} ratings)',
                  ),
                  if (user.address != null)
                    _DetailRow(label: 'Address', value: user.address!),

                  if (userProperties.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Properties (${userProperties.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...userProperties.map(
                      (property) => Card(
                        child: ListTile(
                          dense: true,
                          title: Text(property.title),
                          subtitle: Text('\$${property.price}/month'),
                          trailing: Icon(
                            property.isAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                property.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
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

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: const Text(
              'Are you sure you want to delete this user? '
              'This will also delete all their properties and related data. '
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
      final success = await provider.deleteUser(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'User deleted successfully' : 'Error deleting user',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _filterUsers();
        }
      }
    }
  }

  Future<void> _refreshUsers(AdminProvider provider) async {
    await provider.refreshUsers();
    _filterUsers();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Users refreshed'),
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
            width: 80,
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
