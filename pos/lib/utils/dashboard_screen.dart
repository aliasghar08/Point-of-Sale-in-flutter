import 'package:flutter/material.dart';
import 'package:pos/models/user.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/screens/home.dart';
import 'package:pos/screens/inventory_screen.dart';
import 'package:pos/screens/login_screen.dart';
import 'package:pos/screens/user_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:pos/utils/drawer.dart';

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
    items.add(
      BottomNavigationBarItem(
        icon: Icon(
          Icons.shopping_cart,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        activeIcon: Icon(
          Icons.shopping_cart,
          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
        ),
        label: 'POS',
      ),
    );

    // Inventory - Only owner and manager
    if (user.canManageInventory) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(
            Icons.inventory_2,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          activeIcon: Icon(
            Icons.inventory_2,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
          ),
          label: 'Inventory',
        ),
      );
    }

    // User Management - Only owner
    if (user.canManageUsers) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(
            Icons.people,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          activeIcon: Icon(
            Icons.people,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
          ),
          label: 'Users',
        ),
      );
    }

    return items;
  }

  // Get title based on current tab
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Point of Sale';
      case 1:
        return 'Inventory Management';
      case 2:
        return 'User Management';
      default:
        return 'POS System';
    }
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
      // ✅ ADDED APP BAR WITH DRAWER ICON
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        // ✅ The drawer icon (☰) appears automatically
        // because the Scaffold has a drawer
        actions: [
          // Optional: Add global actions here
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Show sales history
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sales History'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: isDarkMode
            ? Colors.blue.shade400
            : Colors.blue.shade700,
        unselectedItemColor: isDarkMode
            ? Colors.grey.shade500
            : Colors.grey.shade600,
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: navItems,
      ),
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}