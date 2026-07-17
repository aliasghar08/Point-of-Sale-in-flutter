import 'package:flutter/material.dart';
import 'package:pos/models/settings_model.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/providers/theme_provider.dart';
import 'package:pos/screens/login_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _showResetDialog,
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildUserInfoSection(authProvider),
                  const SizedBox(height: 16),
                  _buildThemeSection(themeProvider), // Updated
                  const SizedBox(height: 16),
                  _buildCurrencySection(settingsProvider, settings),
                  const SizedBox(height: 16),
                  _buildInventorySection(settingsProvider, settings),
                  const SizedBox(height: 16),
                  _buildPOSSection(settingsProvider, settings),
                  const SizedBox(height: 16),
                  _buildNotificationSection(settingsProvider, settings),
                  const SizedBox(height: 16),
                  _buildDataSection(settingsProvider, settings),
                  const SizedBox(height: 16),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(authProvider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.roleDisplay,
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                // TODO: Edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.green;
      case 'manager':
        return Colors.blue;
      case 'worker':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ==================== UPDATED THEME SECTION ====================
  Widget _buildThemeSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildThemeOption(
                  icon: Icons.light_mode,
                  label: 'Light',
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  icon: Icons.dark_mode,
                  label: 'Dark',
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  icon: Icons.phone_android,
                  label: 'System',
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${themeProvider.getThemeName()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (themeProvider.isDarkMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Dark Mode Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade100
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.shade700
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.blue.shade700
                    : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== REST OF THE METHODS (Unchanged) ====================

  Widget _buildCurrencySection(SettingsProvider provider, AppSettings settings) {
    final currencies = [
      {'symbol': '₹', 'code': 'INR', 'name': 'Indian Rupee'},
      {'symbol': '\$', 'code': 'USD', 'name': 'US Dollar'},
      {'symbol': '€', 'code': 'EUR', 'name': 'Euro'},
      {'symbol': '£', 'code': 'GBP', 'name': 'British Pound'},
      {'symbol': '¥', 'code': 'JPY', 'name': 'Japanese Yen'},
      {'symbol': 'A\$', 'code': 'AUD', 'name': 'Australian Dollar'},
      {'symbol': 'C\$', 'code': 'CAD', 'name': 'Canadian Dollar'},
      {'symbol': 'CHF', 'code': 'CHF', 'name': 'Swiss Franc'},
      {'symbol': '¥', 'code': 'CNY', 'name': 'Chinese Yuan'},
      {'symbol': '₩', 'code': 'KRW', 'name': 'South Korean Won'},
    ];

    String currentDisplay = '${settings.currencySymbol} (${settings.currencyCode})';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: settings.currencyCode,
                isExpanded: true,
                underline: const SizedBox(),
                items: currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency['code'],
                    child: Text(
                      '${currency['symbol']} - ${currency['name']} (${currency['code']})',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final selected = currencies.firstWhere(
                      (c) => c['code'] == value,
                    );
                    provider.updateCurrency(
                      selected['symbol']!,
                      selected['code']!,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: $currentDisplay',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(SettingsProvider provider, AppSettings settings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Inventory Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Low Stock Threshold',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: settings.lowStockThreshold,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [5, 10, 15, 20, 25, 30, 50].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateLowStockThreshold(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Products with stock below this value will be marked as "Low Stock"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPOSSection(SettingsProvider provider, AppSettings settings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                const Text(
                  'POS Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Profit in POS'),
              subtitle: Text(
                'Display profit per item during checkout',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.showProfitInPOS,
              onChanged: (_) => provider.toggleShowProfit(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Auto Print Receipt'),
              subtitle: Text(
                'Automatically print receipt after checkout',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.autoPrintReceipt,
              onChanged: (_) => provider.toggleAutoPrint(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(SettingsProvider provider, AppSettings settings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.red.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Notifications & Sounds',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(
                'Show notifications for sales and stock alerts',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.enableNotifications,
              onChanged: (_) => provider.toggleNotifications(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Sound Effects'),
              subtitle: Text(
                'Play sounds during scanning and checkout',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.enableSound,
              onChanged: (_) => provider.toggleSound(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: Text(
                'Vibrate on successful scan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.enableVibration,
              onChanged: (_) => provider.toggleVibration(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(SettingsProvider provider, AppSettings settings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.cyan.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Data & Sync',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Offline Mode'),
              subtitle: Text(
                'Work offline and sync when online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.enableOfflineMode,
              onChanged: (_) => provider.toggleOfflineMode(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Auto Sync Data'),
              subtitle: Text(
                'Automatically sync data with cloud',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              value: settings.autoSyncData,
              onChanged: (_) => provider.toggleAutoSync(),
              activeColor: Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _showSnackBar('Syncing data... Please wait');
                // TODO: Implement sync functionality
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('POS System'),
              subtitle: const Text('Version 1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showAboutDialog();
              },
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showSnackBar('Privacy Policy coming soon!');
              },
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showSnackBar('Help & Support coming soon!');
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<SettingsProvider>(context, listen: false);
              await provider.resetToDefault();
              Navigator.pop(context);
              _showSnackBar('Settings reset to default');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storefront, color: Colors.blue),
            SizedBox(width: 8),
            Text('About POS System'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Point of Sale System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'A complete POS solution with inventory management,\n'
              'barcode scanning, and real-time reporting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© ${DateTime.now().year} POS System',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
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

  void _saveAllSettings() {
    setState(() => _isSaving = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isSaving = false);
      _showSnackBar('Settings saved successfully!');
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}