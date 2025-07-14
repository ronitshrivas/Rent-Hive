import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/screens/home/home_screen.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/app_colors.dart';
import 'search/search_screen.dart';
import 'favorites/favorites_screen.dart';
import 'chat/chat_list_screen.dart';
import 'profile/profile_screen.dart';
import 'owner/owner_dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final UserType userType = authProvider.user!.userType;
        final List<NavigationItem> navigationItems = _getNavigationItems(userType);

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: navigationItems.map((item) => item.screen).toList(),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: navigationItems.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final NavigationItem item = entry.value;
                    final bool isSelected = _currentIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onItemTapped(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    color: isSelected 
                                        ? AppColors.primaryColor 
                                        : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                  if (item.showBadge) ...[
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
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.w500,
                                  color: isSelected 
                                      ? AppColors.primaryColor 
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<NavigationItem> _getNavigationItems(UserType userType) {
    if (userType == UserType.propertyOwner) {
      return [
        NavigationItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          screen: const OwnerDashboardScreen(),
        ),
        NavigationItem(
          label: 'Properties',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          screen: const HomeScreen(),
        ),
        NavigationItem(
          label: 'Messages',
          icon: Icons.chat_outlined,
          activeIcon: Icons.chat_rounded,
          screen: const ChatListScreen(),
          showBadge: false, // TODO: Implement unread count
        ),
        NavigationItem(
          label: 'Profile',
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          screen: const ProfileScreen(),
        ),
      ];
    } else {
      return [
        NavigationItem(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          screen: const HomeScreen(),
        ),
        NavigationItem(
          label: 'Search',
          icon: Icons.search_outlined,
          activeIcon: Icons.search_rounded,
          screen: const SearchScreen(),
        ),
        NavigationItem(
          label: 'Favorites',
          icon: Icons.favorite_outline,
          activeIcon: Icons.favorite_rounded,
          screen: const FavoritesScreen(),
        ),
        NavigationItem(
          label: 'Messages',
          icon: Icons.chat_outlined,
          activeIcon: Icons.chat_rounded,
          screen: const ChatListScreen(),
          showBadge: false, // TODO: Implement unread count
        ),
        NavigationItem(
          label: 'Profile',
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          screen: const ProfileScreen(),
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  final bool showBadge;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
    this.showBadge = false,
  });
}

// Custom Bottom Navigation Bar Widget
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItem> items;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final int index = entry.key;
          final NavigationItem item = entry.value;
          final bool isSelected = currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primaryColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected 
                                ? AppColors.primaryColor 
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          if (item.showBadge) ...[
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.errorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.w500,
                        color: isSelected 
                            ? AppColors.primaryColor 
                            : AppColors.textSecondary,
                      ),
                      child: Text(item.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}