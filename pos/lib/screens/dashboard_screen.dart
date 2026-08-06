import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/user.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/providers/theme_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/app_drawer.dart';
import 'package:pos/screens/home.dart';
import 'package:pos/screens/inventory_screen.dart';
import 'package:pos/screens/reports_screen.dart';
import 'package:pos/screens/crm_screen.dart';
import 'package:pos/screens/user_management_screen.dart';
import 'package:pos/screens/sales_history_screen.dart';
import 'package:pos/screens/settings_screen.dart';
import 'package:pos/screens/login_screen.dart';

/// Central Dashboard Shell providing role-based tab switching and unified AppDrawer.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  List<Widget> _getTabs(AppUser user) {
    final List<Widget> tabs = [];

    // 0: Point of Sale
    tabs.add(const HomeScreen());

    // 1: Inventory
    if (user.canManageInventory) {
      tabs.add(const InventoryScreen());
    }

    // 2: Analytics & Reports
    tabs.add(const ReportsScreen());

    // 3: Customers CRM
    tabs.add(const CrmScreen());

    // 4: Staff & Roles (Admin/Owner only)
    if (user.canManageUsers) {
      tabs.add(const UserManagementScreen());
    }

    return tabs;
  }

  List<NavigationDestination> _getDestinations(AppUser user) {
    final List<NavigationDestination> dests = [];

    dests.add(const NavigationDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: 'POS Register',
    ));

    if (user.canManageInventory) {
      dests.add(const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Inventory',
      ));
    }

    dests.add(const NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analytics',
    ));

    dests.add(const NavigationDestination(
      icon: Icon(Icons.people_alt_outlined),
      selectedIcon: Icon(Icons.people_alt),
      label: 'CRM',
    ));

    if (user.canManageUsers) {
      dests.add(const NavigationDestination(
        icon: Icon(Icons.manage_accounts_outlined),
        selectedIcon: Icon(Icons.manage_accounts),
        label: 'Staff',
      ));
    }

    return dests;
  }

  String _getTitle(int index, AppUser user) {
    switch (index) {
      case 0:
        return 'Point of Sale Register';
      case 1:
        return user.canManageInventory ? 'Inventory Management' : 'Analytics & Insights';
      case 2:
        return user.canManageInventory ? 'Analytics & Insights' : 'Customers & Loyalty';
      case 3:
        return user.canManageInventory ? 'Customers & Loyalty' : 'Staff & Roles';
      case 4:
        return 'Staff & Roles';
      default:
        return 'POS Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const LoginScreen();
    }

    final tabs = _getTabs(user);
    final destinations = _getDestinations(user);

    // Safeguard index bounds
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          if (index < tabs.length) {
            setState(() => _currentIndex = index);
          }
        },
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getTitle(_currentIndex, user),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${user.roleDisplay} • ${settingsProvider.currencySymbol}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Sales History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: destinations,
      ),
    );
  }
}