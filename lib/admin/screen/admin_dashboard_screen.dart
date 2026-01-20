import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/admin/providers/admin_provider.dart';
import 'package:renthive/admin/screen/admin_users_screen.dart';
import 'package:renthive/admin/screen/AdminPropertiesScreen.dart';
import 'package:renthive/admin/screen/AdminChatsScreen.dart';
import 'package:renthive/admin/screen/admin_login_screen.dart';
import 'package:renthive/admin/screen/statistics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminUsersScreen(),
    AdminPropertiesScreen(),
    AdminChatsScreen(),
    StatisticsScreen(),
  ];

  final List<String> _titles = const [
    'Users Management',
    'Properties Management',
    'Chats Management',
    'Statistics',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('RentHive Admin - ${_titles[_selectedIndex]}'),
            actions: [
              // Admin info
              if (provider.admin != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 16,
                          child: Text(
                            provider.admin!.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.admin!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh All Data',
                onPressed: () async {
                  await provider.refreshAllData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data refreshed successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              // Logout button
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: Row(
            children: [
              // Sidebar Navigation
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.grey[100],
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Properties'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_outlined),
                    selectedIcon: Icon(Icons.chat),
                    label: Text('Chats'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics),
                    label: Text('Statistics'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),

              // Main content
              Expanded(
                child:
                    provider.isLoading
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading data...'),
                            ],
                          ),
                        )
                        : _screens[_selectedIndex],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.logout();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
        );
      }
    }
  }
}
