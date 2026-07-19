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

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
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