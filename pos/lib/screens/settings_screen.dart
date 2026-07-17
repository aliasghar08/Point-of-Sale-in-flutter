import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/settings_model.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/providers/theme_provider.dart';
import 'package:pos/screens/login_screen.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.restore,
              color: isDarkMode ? Colors.white : Colors.white,
            ),
            onPressed: _showResetDialog,
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: settingsProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildUserInfoSection(authProvider, isDarkMode),
                  const SizedBox(height: 16),
                  _buildThemeSection(themeProvider, isDarkMode),
                  const SizedBox(height: 16),
                  _buildCurrencySection(settingsProvider, settings, isDarkMode),
                  const SizedBox(height: 16),
                  _buildInventorySection(settingsProvider, settings, isDarkMode),
                  const SizedBox(height: 16),
                  _buildPOSSection(settingsProvider, settings, isDarkMode),
                  const SizedBox(height: 16),
                  _buildNotificationSection(settingsProvider, settings, isDarkMode),
                  const SizedBox(height: 16),
                  _buildDataSection(settingsProvider, settings, isDarkMode),
                  const SizedBox(height: 16),
                  _buildAboutSection(isDarkMode),
                  const SizedBox(height: 24),
                  _buildLogoutButton(authProvider, isDarkMode),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ==================== USER INFO SECTION ====================
  Widget _buildUserInfoSection(AuthProvider authProvider, bool isDarkMode) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.blue.shade100,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.blue.shade700,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role, isDarkMode).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.roleDisplay,
                      style: TextStyle(
                        color: _getRoleColor(user.role, isDarkMode),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
              onPressed: () {
                _showSnackBar('Edit profile coming soon!', isDarkMode);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role, bool isDarkMode) {
    switch (role) {
      case 'owner':
        return isDarkMode ? Colors.green.shade400 : Colors.green;
      case 'manager':
        return isDarkMode ? Colors.blue.shade400 : Colors.blue;
      case 'worker':
        return isDarkMode ? Colors.orange.shade400 : Colors.orange;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey;
    }
  }

  // ==================== THEME SECTION ====================
  Widget _buildThemeSection(ThemeProvider themeProvider, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
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
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  icon: Icons.dark_mode,
                  label: 'Dark',
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildThemeOption(
                  icon: Icons.phone_android,
                  label: 'System',
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  isDarkMode: isDarkMode,
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
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (themeProvider.isDarkMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dark Mode Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
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
    required bool isDarkMode,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? isDarkMode
                    ? Colors.blue.shade900
                    : Colors.blue.shade100
                : isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? isDarkMode
                      ? Colors.blue.shade400
                      : Colors.blue.shade700
                  : isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? isDarkMode
                        ? Colors.blue.shade400
                        : Colors.blue.shade700
                    : isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700
                      : isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CURRENCY SECTION ====================
  Widget _buildCurrencySection(SettingsProvider provider, AppSettings settings, bool isDarkMode) {
    final currencies = [
      // ===== ASIAN CURRENCIES =====
      {'symbol': '₹', 'code': 'INR', 'name': 'Indian Rupee'},
      {'symbol': '₨', 'code': 'PKR', 'name': 'Pakistani Rupee'},
      {'symbol': '৳', 'code': 'BDT', 'name': 'Bangladeshi Taka'},
      {'symbol': 'Rp', 'code': 'IDR', 'name': 'Indonesian Rupiah'},
      {'symbol': 'RM', 'code': 'MYR', 'name': 'Malaysian Ringgit'},
      {'symbol': '₱', 'code': 'PHP', 'name': 'Philippine Peso'},
      {'symbol': 'S\$', 'code': 'SGD', 'name': 'Singapore Dollar'},
      {'symbol': '฿', 'code': 'THB', 'name': 'Thai Baht'},
      {'symbol': '₫', 'code': 'VND', 'name': 'Vietnamese Dong'},
      {'symbol': '¥', 'code': 'CNY', 'name': 'Chinese Yuan'},
      {'symbol': '¥', 'code': 'JPY', 'name': 'Japanese Yen'},
      {'symbol': '₩', 'code': 'KRW', 'name': 'South Korean Won'},
      {'symbol': '₮', 'code': 'MNT', 'name': 'Mongolian Tugrik'},
      {'symbol': 'Rs', 'code': 'NPR', 'name': 'Nepalese Rupee'},
      {'symbol': 'Rs', 'code': 'LKR', 'name': 'Sri Lankan Rupee'},
      
      // ===== MIDDLE EASTERN CURRENCIES =====
      {'symbol': 'د.إ', 'code': 'AED', 'name': 'UAE Dirham'},
      {'symbol': 'ر.س', 'code': 'SAR', 'name': 'Saudi Riyal'},
      {'symbol': 'ر.ق', 'code': 'QAR', 'name': 'Qatari Riyal'},
      {'symbol': 'د.ك', 'code': 'KWD', 'name': 'Kuwaiti Dinar'},
      {'symbol': 'ر.ع.', 'code': 'OMR', 'name': 'Omani Rial'},
      {'symbol': 'د.ب', 'code': 'BHD', 'name': 'Bahraini Dinar'},
      {'symbol': 'ل.ل', 'code': 'LBP', 'name': 'Lebanese Pound'},
      {'symbol': 'د.ا', 'code': 'JOD', 'name': 'Jordanian Dinar'},
      {'symbol': '₪', 'code': 'ILS', 'name': 'Israeli Shekel'},
      {'symbol': '﷼', 'code': 'IRR', 'name': 'Iranian Rial'},
      {'symbol': 'د.ع', 'code': 'IQD', 'name': 'Iraqi Dinar'},
      {'symbol': 'ل.س', 'code': 'SYP', 'name': 'Syrian Pound'},
      {'symbol': 'ل.د', 'code': 'LYD', 'name': 'Libyan Dinar'},
      
      // ===== EUROPEAN CURRENCIES =====
      {'symbol': '€', 'code': 'EUR', 'name': 'Euro'},
      {'symbol': '£', 'code': 'GBP', 'name': 'British Pound'},
      {'symbol': 'CHF', 'code': 'CHF', 'name': 'Swiss Franc'},
      {'symbol': 'kr', 'code': 'NOK', 'name': 'Norwegian Krone'},
      {'symbol': 'kr', 'code': 'SEK', 'name': 'Swedish Krona'},
      {'symbol': 'kr', 'code': 'DKK', 'name': 'Danish Krone'},
      {'symbol': 'zł', 'code': 'PLN', 'name': 'Polish Zloty'},
      {'symbol': 'Kč', 'code': 'CZK', 'name': 'Czech Koruna'},
      {'symbol': 'Ft', 'code': 'HUF', 'name': 'Hungarian Forint'},
      {'symbol': 'лв', 'code': 'BGN', 'name': 'Bulgarian Lev'},
      {'symbol': 'lei', 'code': 'RON', 'name': 'Romanian Leu'},
      {'symbol': '₽', 'code': 'RUB', 'name': 'Russian Ruble'},
      {'symbol': '₴', 'code': 'UAH', 'name': 'Ukrainian Hryvnia'},
      {'symbol': '₺', 'code': 'TRY', 'name': 'Turkish Lira'},
      
      // ===== NORTH AMERICAN CURRENCIES =====
      {'symbol': '\$', 'code': 'USD', 'name': 'US Dollar'},
      {'symbol': 'CA\$', 'code': 'CAD', 'name': 'Canadian Dollar'},
      {'symbol': 'MX\$', 'code': 'MXN', 'name': 'Mexican Peso'},
      
      // ===== SOUTH AMERICAN CURRENCIES =====
      {'symbol': 'R\$', 'code': 'BRL', 'name': 'Brazilian Real'},
      {'symbol': '\$', 'code': 'ARS', 'name': 'Argentine Peso'},
      {'symbol': 'S/', 'code': 'PEN', 'name': 'Peruvian Sol'},
      {'symbol': 'CLP\$', 'code': 'CLP', 'name': 'Chilean Peso'},
      {'symbol': 'COP\$', 'code': 'COP', 'name': 'Colombian Peso'},
      {'symbol': 'Bs.', 'code': 'VES', 'name': 'Venezuelan Bolívar'},
      {'symbol': 'Bs.', 'code': 'BOB', 'name': 'Bolivian Boliviano'},
      {'symbol': '₲', 'code': 'PYG', 'name': 'Paraguayan Guarani'},
      {'symbol': '\$', 'code': 'UYU', 'name': 'Uruguayan Peso'},
      
      // ===== AFRICAN CURRENCIES =====
      {'symbol': 'R', 'code': 'ZAR', 'name': 'South African Rand'},
      {'symbol': '₦', 'code': 'NGN', 'name': 'Nigerian Naira'},
      {'symbol': 'KSh', 'code': 'KES', 'name': 'Kenyan Shilling'},
      {'symbol': 'TSh', 'code': 'TZS', 'name': 'Tanzanian Shilling'},
      {'symbol': 'USh', 'code': 'UGX', 'name': 'Ugandan Shilling'},
      {'symbol': 'GH₵', 'code': 'GHS', 'name': 'Ghanaian Cedi'},
      {'symbol': 'CFA', 'code': 'XOF', 'name': 'West African CFA Franc'},
      {'symbol': 'CFA', 'code': 'XAF', 'name': 'Central African CFA Franc'},
      {'symbol': 'د.ج', 'code': 'DZD', 'name': 'Algerian Dinar'},
      {'symbol': 'د.م.', 'code': 'MAD', 'name': 'Moroccan Dirham'},
      {'symbol': 'EGP', 'code': 'EGP', 'name': 'Egyptian Pound'},
      {'symbol': 'SDG', 'code': 'SDG', 'name': 'Sudanese Pound'},
      {'symbol': 'DT', 'code': 'TND', 'name': 'Tunisian Dinar'},
      
      // ===== OCEANIAN CURRENCIES =====
      {'symbol': 'A\$', 'code': 'AUD', 'name': 'Australian Dollar'},
      {'symbol': 'NZ\$', 'code': 'NZD', 'name': 'New Zealand Dollar'},
      {'symbol': '₨', 'code': 'MUR', 'name': 'Mauritian Rupee'},
      {'symbol': 'T\$', 'code': 'TOP', 'name': 'Tongan Paʻanga'},
      {'symbol': 'S\$', 'code': 'SBD', 'name': 'Solomon Islands Dollar'},
      {'symbol': 'VT', 'code': 'VUV', 'name': 'Vanuatu Vatu'},
      
      // ===== OTHER CURRENCIES =====
      {'symbol': '₡', 'code': 'CRC', 'name': 'Costa Rican Colón'},
      {'symbol': 'C\$', 'code': 'NIO', 'name': 'Nicaraguan Córdoba'},
      {'symbol': 'B/.', 'code': 'PAB', 'name': 'Panamanian Balboa'},
      {'symbol': 'L', 'code': 'HNL', 'name': 'Honduran Lempira'},
      {'symbol': 'Q', 'code': 'GTQ', 'name': 'Guatemalan Quetzal'},
      {'symbol': 'soʻm', 'code': 'UZS', 'name': 'Uzbekistani Som'},
      {'symbol': 'som', 'code': 'KGS', 'name': 'Kyrgyzstani Som'},
      {'symbol': 'T', 'code': 'TMT', 'name': 'Turkmenistani Manat'},
      {'symbol': 'AZN', 'code': 'AZN', 'name': 'Azerbaijani Manat'},
      {'symbol': '₾', 'code': 'GEL', 'name': 'Georgian Lari'},
      {'symbol': 'AMD', 'code': 'AMD', 'name': 'Armenian Dram'},
      {'symbol': 'ден', 'code': 'MKD', 'name': 'Macedonian Denar'},
      {'symbol': 'KM', 'code': 'BAM', 'name': 'Bosnian Convertible Mark'},
      {'symbol': 'с', 'code': 'KZT', 'name': 'Kazakhstani Tenge'},
      {'symbol': 'm', 'code': 'MDL', 'name': 'Moldovan Leu'},
    ];

    String currentDisplay = '${settings.currencySymbol} (${settings.currencyCode})';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'Currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: settings.currencyCode,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
                items: currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency['code'],
                    child: Text(
                      '${currency['symbol']} - ${currency['name']} (${currency['code']})',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: $currentDisplay',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${currencies.length} currencies',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
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

  // ==================== INVENTORY SECTION ====================
  Widget _buildInventorySection(SettingsProvider provider, AppSettings settings, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'Inventory Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
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
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: settings.lowStockThreshold,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    items: [5, 10, 15, 20, 25, 30, 50].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.toString(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
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
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== POS SECTION ====================
  Widget _buildPOSSection(SettingsProvider provider, AppSettings settings, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'POS Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Show Profit in POS',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Display profit per item during checkout',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.showProfitInPOS,
              onChanged: (_) => provider.toggleShowProfit(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(
                'Auto Print Receipt',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Automatically print receipt after checkout',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.autoPrintReceipt,
              onChanged: (_) => provider.toggleAutoPrint(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== NOTIFICATION SECTION ====================
  Widget _buildNotificationSection(SettingsProvider provider, AppSettings settings, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications & Sounds',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Enable Notifications',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Show notifications for sales and stock alerts',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.enableNotifications,
              onChanged: (_) => provider.toggleNotifications(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(
                'Sound Effects',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Play sounds during scanning and checkout',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.enableSound,
              onChanged: (_) => provider.toggleSound(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(
                'Vibration',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Vibrate on successful scan',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.enableVibration,
              onChanged: (_) => provider.toggleVibration(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DATA SECTION ====================
  Widget _buildDataSection(SettingsProvider provider, AppSettings settings, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: isDarkMode ? Colors.cyan.shade400 : Colors.cyan.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data & Sync',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Offline Mode',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Work offline and sync when online',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.enableOfflineMode,
              onChanged: (_) => provider.toggleOfflineMode(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(
                'Auto Sync Data',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Automatically sync data with cloud',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: settings.autoSyncData,
              onChanged: (_) => provider.toggleAutoSync(),
              activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _showSnackBar('Syncing data... Please wait', isDarkMode);
              },
              icon: Icon(
                Icons.sync,
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
              label: Text(
                'Sync Now',
                style: TextStyle(
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ABOUT SECTION ====================
  Widget _buildAboutSection(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.storefront,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'POS System',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              onTap: () {
                _showAboutDialog(isDarkMode);
              },
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(
                Icons.privacy_tip,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              onTap: () {
                _showSnackBar('Privacy Policy coming soon!', isDarkMode);
              },
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(
                Icons.help,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Help & Support',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              onTap: () {
                _showSnackBar('Help & Support coming soon!', isDarkMode);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LOGOUT BUTTON ====================
  Widget _buildLogoutButton(AuthProvider authProvider, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
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
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
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

  // ==================== DIALOGS ====================
  void _showResetDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all settings to default values?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<SettingsProvider>(context, listen: false);
              await provider.resetToDefault();
              Navigator.pop(context);
              _showSnackBar('Settings reset to default', isDarkMode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(bool isDarkMode) {
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
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
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
            const Divider(),
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
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, bool isDarkMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}