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

  List<BottomNavigationBarItem> _getNavItems(AppUser user) {
    List<BottomNavigationBarItem> items = [];
    
    // POS
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: 'POS',
    ));
    
    // Inventory - Only owner and manager
    if (user.canManageInventory) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2),
        label: 'Inventory',
      ));
    }
    
    // User Management - Only owner
    if (user.canManageUsers) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Users',
      ));
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    List<Widget> tabs = _getTabs(user);
    List<BottomNavigationBarItem> navItems = _getNavItems(user);

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
      drawer: _buildDrawer(context, user, authProvider),
    );
  }

  Widget _buildDrawer(BuildContext context, AppUser user, AuthProvider authProvider) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;

    return Drawer(
      child: Column(
        children: [
          // User Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
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
                      color: Colors.blue.shade700,
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
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('POS'),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          if (user.canManageInventory)
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Inventory'),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
          if (user.canManageUsers)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Sales History'),
            onTap: () {
              // TODO: Navigate to sales history
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sales History coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              // TODO: Navigate to reports
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reports coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Colors.blue.shade700,
            ),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Settings Screen
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
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
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