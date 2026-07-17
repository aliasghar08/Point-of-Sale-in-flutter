import 'package:flutter/material.dart';
import 'package:pos/models/user.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/screens/settings_screen.dart';
import 'package:pos/screens/home.dart';
import 'package:pos/screens/inventory_screen.dart';
import 'package:pos/screens/login_screen.dart';
import 'package:pos/screens/user_management_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Define tabs with role-based access
  List<Widget> _getTabs(AppUser user) {
    List<Widget> tabs = [];
    
    // POS - All users can access
    tabs.add(const HomeScreen());
    
    // Inventory - Only owner and manager
    if (user.canManageInventory) {
      tabs.add(const InventoryScreen());
    }
    
    // User Management - Only owner
    if (user.canManageUsers) {
      tabs.add(const UserManagementScreen());
    }
    
    return tabs;
  }

  List<BottomNavigationBarItem> _getNavItems(AppUser user, bool isDarkMode) {
    List<BottomNavigationBarItem> items = [];
    
    // POS
    items.add(BottomNavigationBarItem(
      icon: Icon(
        Icons.shopping_cart,
        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      activeIcon: Icon(
        Icons.shopping_cart,
        color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
      ),
      label: 'POS',
    ));
    
    // Inventory - Only owner and manager
    if (user.canManageInventory) {
      items.add(BottomNavigationBarItem(
        icon: Icon(
          Icons.inventory_2,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        activeIcon: Icon(
          Icons.inventory_2,
          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
        ),
        label: 'Inventory',
      ));
    }
    
    // User Management - Only owner
    if (user.canManageUsers) {
      items.add(BottomNavigationBarItem(
        icon: Icon(
          Icons.people,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        activeIcon: Icon(
          Icons.people,
          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
        ),
        label: 'Users',
      ));
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const LoginScreen();
    }

    List<Widget> tabs = _getTabs(user);
    List<BottomNavigationBarItem> navItems = _getNavItems(user, isDarkMode);

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
        unselectedItemColor: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: navItems,
      ),
      drawer: _buildDrawer(context, user, authProvider, isDarkMode),
    );
  }

  Widget _buildDrawer(
    BuildContext context, 
    AppUser user, 
    AuthProvider authProvider,
    bool isDarkMode,
  ) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;

    return Drawer(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: Column(
        children: [
          // User Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 30,
                      color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.roleDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.currency_exchange,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currencySymbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Navigation items
          ListTile(
            leading: Icon(
              Icons.dashboard,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            title: Text(
              'Dashboard',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shopping_cart,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            title: Text(
              'POS',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          if (user.canManageInventory)
            ListTile(
              leading: Icon(
                Icons.inventory_2,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              title: Text(
                'Inventory',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
          if (user.canManageUsers)
            ListTile(
              leading: Icon(
                Icons.people,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              title: Text(
                'User Management',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: Icon(
              Icons.receipt_long,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            title: Text(
              'Sales History',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sales History coming soon!',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                ),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.bar_chart,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            title: Text(
              'Reports',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Reports coming soon!',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                ),
              );
              Navigator.pop(context);
            },
          ),
          const Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: isDarkMode ? Colors.red.shade400 : Colors.red,
              ),
            ),
            onTap: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ) ?? false;

              if (confirm && context.mounted) {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}