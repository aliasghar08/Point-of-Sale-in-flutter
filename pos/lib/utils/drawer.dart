import 'package:flutter/material.dart';
import 'package:pos/models/user.dart';
import 'package:pos/screens/reports_screen.dart';
import 'package:pos/screens/sales_history_screen.dart';
import 'package:pos/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.currentUser;
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Drawer(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        child: Center(
          child: Text(
            'No user logged in',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: Column(
        children: [
          // User Header
          _buildUserHeader(context, user, currencySymbol, isDarkMode),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                // ===== DASHBOARD (Main Screen / POS) =====
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: currentIndex == 0,
                  isDarkMode: isDarkMode,
                  onTap: () => _navigateTo(context, 0),
                ),

                // ===== INVENTORY =====
                if (user.canManageInventory)
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Inventory',
                    isSelected: currentIndex == 1,
                    isDarkMode: isDarkMode,
                    onTap: () => _navigateTo(context, 1),
                  ),

                // ===== USER MANAGEMENT =====
                if (user.canManageUsers)
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'User Management',
                    isSelected: currentIndex == 2,
                    isDarkMode: isDarkMode,
                    onTap: () => _navigateTo(context, 2),
                  ),

                const Divider(),

                // ===== FEATURES =====
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'Sales History',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _showSalesHistory(context, isDarkMode);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Reports',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _showReports(context, isDarkMode);
                  },
                ),

                const Divider(),

                // ===== SETTINGS =====
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSettings(context);
                  },
                ),

                const Divider(),

                // ===== HELP & ABOUT =====
                _buildDrawerItem(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _showHelp(context, isDarkMode);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info,
                  title: 'About',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _showAbout(context, isDarkMode);
                  },
                ),
              ],
            ),
          ),

          // Logout Button at Bottom
          _buildLogoutButton(context, authProvider, isDarkMode),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==================== BUILD METHODS ====================

  Widget _buildUserHeader(
    BuildContext context,
    AppUser user,
    String currencySymbol,
    bool isDarkMode,
  ) {
    return Container(
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
          const SizedBox(height: 8),
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
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    int? index,
    bool isSelected = false,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700)
            : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700)
              : (isDarkMode ? Colors.white : Colors.grey.shade800),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AuthProvider authProvider,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(context, authProvider, isDarkMode),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode
                ? Colors.red.shade900.withOpacity(0.5)
                : Colors.red.shade50,
            foregroundColor: isDarkMode
                ? Colors.red.shade400
                : Colors.red.shade700,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(
            Icons.logout,
            color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
          ),
          label: Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== NAVIGATION METHODS ====================

  void _navigateTo(BuildContext context, int index) {
    // Close the drawer first
    Navigator.pop(context);

    // Then navigate using the callback
    // The parent widget (DashboardScreen) will handle the navigation
    onItemSelected(index);
  }

  void _navigateToSettings(BuildContext context) {
    // Close drawer
    Navigator.pop(context);
    // Navigate to settings
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // ==================== DIALOG METHODS ====================

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
    bool isDarkMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? Colors.red.shade400
                  : Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSalesHistory(BuildContext context, bool isDarkMode) {

      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SalesHistoryScreen(),
      ),
    );
  }

  void _showReports(BuildContext context, bool isDarkMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsScreen(),
      ),
    );

  
  }

  void _showHelp(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Help & Support',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📧 Email: support@posapp.com',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              '📞 Phone: +92 300 1234567',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              '🌐 Website: www.posapp.com',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              'For any issues, please contact our support team.',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.storefront,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'About POS System',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart,
              size: 64,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Point of Sale System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'A complete POS solution with inventory management,\n'
              'barcode scanning, and real-time reporting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© ${DateTime.now().year} POS System',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
