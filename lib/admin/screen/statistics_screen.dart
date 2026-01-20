import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/admin/providers/admin_provider.dart';
import 'package:renthive/models/user_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final stats = await provider.getStatistics();
    setState(() {
      _statistics = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: _loadStatistics,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          const Text(
                            'Platform Statistics',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated: ${DateTime.now().toString().split('.')[0]}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Overview Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _StatCard(
                                title: 'Total Users',
                                value: '${_statistics['totalUsers'] ?? 0}',
                                icon: Icons.people,
                                color: Colors.blue,
                                subtitle:
                                    'Owners: ${_statistics['propertyOwners'] ?? 0} | Seekers: ${_statistics['roomSeekers'] ?? 0}',
                              ),
                              _StatCard(
                                title: 'Total Properties',
                                value: '${_statistics['totalProperties'] ?? 0}',
                                icon: Icons.home,
                                color: Colors.green,
                                subtitle:
                                    'Available: ${_statistics['availableProperties'] ?? 0} | Rented: ${_statistics['rentedProperties'] ?? 0}',
                              ),
                              _StatCard(
                                title: 'Chat Rooms',
                                value: '${_statistics['totalChatRooms'] ?? 0}',
                                icon: Icons.chat,
                                color: Colors.orange,
                                subtitle: 'Active conversations',
                              ),
                              _StatCard(
                                title: 'Available Properties',
                                value:
                                    '${_statistics['availableProperties'] ?? 0}',
                                icon: Icons.check_circle,
                                color: Colors.purple,
                                subtitle:
                                    '${_getPercentage(_statistics['availableProperties'], _statistics['totalProperties'])}% of total',
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // User Breakdown
                          const Text(
                            'User Breakdown',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _ProgressRow(
                                    label: 'Property Owners',
                                    value: _statistics['propertyOwners'] ?? 0,
                                    total: _statistics['totalUsers'] ?? 1,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 16),
                                  _ProgressRow(
                                    label: 'Room Seekers',
                                    value: _statistics['roomSeekers'] ?? 0,
                                    total: _statistics['totalUsers'] ?? 1,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 16),
                                  _ProgressRow(
                                    label: 'Verified Users',
                                    value:
                                        provider.allUsers
                                            .where((u) => u.isVerified)
                                            .length,
                                    total: _statistics['totalUsers'] ?? 1,
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Property Breakdown
                          const Text(
                            'Property Breakdown',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _ProgressRow(
                                    label: 'Available',
                                    value:
                                        _statistics['availableProperties'] ?? 0,
                                    total: _statistics['totalProperties'] ?? 1,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 16),
                                  _ProgressRow(
                                    label: 'Rented',
                                    value: _statistics['rentedProperties'] ?? 0,
                                    total: _statistics['totalProperties'] ?? 1,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recent Activity
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ActivityTile(
                                    icon: Icons.person_add,
                                    title: 'Recent Users',
                                    subtitle:
                                        '${provider.allUsers.take(5).length} users joined recently',
                                    color: Colors.blue,
                                  ),
                                  const Divider(),
                                  _ActivityTile(
                                    icon: Icons.home_work,
                                    title: 'Recent Properties',
                                    subtitle:
                                        '${provider.allProperties.take(5).length} properties listed recently',
                                    color: Colors.green,
                                  ),
                                  const Divider(),
                                  _ActivityTile(
                                    icon: Icons.chat_bubble,
                                    title: 'Active Chats',
                                    subtitle:
                                        '${provider.allChatRooms.where((c) => c.isActive).length} active conversations',
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quick Actions
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _ActionButton(
                                icon: Icons.refresh,
                                label: 'Refresh All Data',
                                onPressed: () async {
                                  await provider.refreshAllData();
                                  await _loadStatistics();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('All data refreshed'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: _loadStatistics,
            tooltip: 'Refresh Statistics',
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  String _getPercentage(int? value, int? total) {
    if (total == null || total == 0 || value == null) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$value / $total (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
