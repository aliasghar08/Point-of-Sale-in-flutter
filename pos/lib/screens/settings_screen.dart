import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/settings_model.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/providers/theme_provider.dart';
import 'package:pos/services/sample_data_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/screens/login_screen.dart';
import 'package:pos/services/local_auth_service.dart';

/// Modern Settings & System Configuration Screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSeeding = false;

  final List<Map<String, String>> _currencyOptions = [
    {'code': 'PKR', 'symbol': '₨', 'name': 'Pakistani Rupee (₨ - PKR)'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar (\$ - USD)'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro (€ - EUR)'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound (£ - GBP)'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham (د.إ - AED)'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Saudi Riyal (ر.س - SAR)'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee (₹ - INR)'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar (C\$ - CAD)'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar (A\$ - AUD)'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen (¥ - JPY)'},
  ];

  Future<void> _seedDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Sample Catalog?'),
        content: const Text(
          'This will populate your catalog with 12+ pre-configured items with barcodes and images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seed Catalog'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final count = await SampleDataService.seedSampleProducts();
      FeedbackService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded $count demo items!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      FeedbackService.error();
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = settingsProvider.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: () => _showResetDialog(settingsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. User Profile Card
                    _buildUserCard(authProvider, isDark),
                    const SizedBox(height: 16),

                    // 2. Appearance & Theme
                    _buildThemeCard(themeProvider, isDark),
                    const SizedBox(height: 16),

                    // 3. Currency & Localization
                    _buildCurrencyCard(settingsProvider, settings, isDark),
                    const SizedBox(height: 16),

                    // 4. POS Register & Receipt
                    _buildPosConfigCard(settingsProvider, settings, isDark),
                    const SizedBox(height: 16),

                    // 5. CRM & Loyalty
                    _buildCrmConfigCard(settingsProvider, settings, isDark),
                    const SizedBox(height: 16),

                    // 6. Security
                    _buildSecurityCard(settingsProvider, settings, isDark),
                    const SizedBox(height: 16),

                    // 7. Demo Data & Developer Tools
                    _buildDemoDataCard(isDark),
                    const SizedBox(height: 16),

                    // 8. About Info
                    _buildAboutCard(isDark),
                    const SizedBox(height: 24),

                    // 9. Logout
                    _buildLogoutButton(authProvider, isDark),
                    const SizedBox(height: 16),

                    // 10. Account Deletion (Apple App Store Guideline 5.1.1(v))
                    _buildAccountDeletionCard(authProvider, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserCard(AuthProvider authProvider, bool isDark) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                (isDark ? AppColors.primaryLight : AppColors.primary)
                    .withValues(alpha: 0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.roleDisplay,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ThemeProvider themeProvider, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Theme & Appearance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text(
              'High-contrast sleek slate theme for low-light environments',
            ),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard(
    SettingsProvider provider,
    AppSettings settings,
    bool isDark,
  ) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Currency & Regional',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _currencyOptions.any((c) => c['code'] == settings.currencyCode)
                ? settings.currencyCode
                : 'PKR',
            decoration: const InputDecoration(
              labelText: 'Primary Currency',
              border: OutlineInputBorder(),
            ),
            items: {
              ...{for (var c in _currencyOptions) c['code']!: c},
              if (settings.currencyCode.isNotEmpty)
                settings.currencyCode: {
                  'code': settings.currencyCode,
                  'symbol': settings.currencySymbol,
                  'name': '${settings.currencyCode} (${settings.currencySymbol})'
                }
            }.values.map((c) {
              return DropdownMenuItem<String>(
                value: c['code'],
                child: Text(c['name']!),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final match = _currencyOptions.firstWhere(
                  (e) => e['code'] == val,
                  orElse: () => {
                    'code': val,
                    'symbol': settings.currencySymbol,
                    'name': val,
                  },
                );
                provider.updateCurrency(match['symbol']!, match['code']!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPosConfigCard(
    SettingsProvider provider,
    AppSettings settings,
    bool isDark,
  ) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.point_of_sale_outlined,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'POS Register Behavior',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Audio & Haptic Feedback'),
            subtitle: const Text(
              'Play sound and vibrate when scanning items or parking orders',
            ),
            value: settings.enableSound,
            onChanged: (_) => provider.toggleSound(),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Auto-Print Thermal Receipt'),
            subtitle: const Text(
              'Automatically generate PDF receipt on successful checkout',
            ),
            value: settings.autoPrintReceipt,
            onChanged: (_) => provider.toggleAutoPrint(),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCrmConfigCard(
    SettingsProvider provider,
    AppSettings settings,
    bool isDark,
  ) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_membership_outlined,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Customer Loyalty Program',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Enable Loyalty Points'),
            subtitle: const Text(
              'Earn points on completed transactions for registered clients',
            ),
            value: settings.enableCustomerLoyalty,
            onChanged: (_) => provider.toggleCustomerLoyalty(),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(
    SettingsProvider provider,
    AppSettings settings,
    bool isDark,
  ) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Biometric Login'),
            subtitle: const Text(
              'Use Face ID or Fingerprint to unlock the app quickly',
            ),
            value: settings.enableBiometrics,
            onChanged: (val) async {
              if (val) {
                // Check if device supports biometrics
                final hasBio = await LocalAuthService.hasBiometrics();
                if (!hasBio) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biometrics not available on this device',
                        ),
                      ),
                    );
                  }
                  return;
                }

                // Prompt user to test it before enabling
                final authenticated = await LocalAuthService.authenticate();
                if (authenticated) {
                  provider.toggleBiometrics();
                  FeedbackService.success();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Authentication failed')),
                    );
                  }
                }
              } else {
                // Just disable
                provider.toggleBiometrics();
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoDataCard(bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dataset_outlined,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Sample Catalog & Seed Data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Need realistic catalog products for testing? Load pre-configured items with categories, barcodes, and prices in one tap.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isSeeding ? null : _seedDemoData,
            icon: _isSeeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _isSeeding ? 'Loading Catalog...' : 'Load Sample Retail Catalog',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'About PosHub',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Version 2.0.0 (Native Dart Architecture)\nDesigned for high-throughput retail stores and tablets with zero lag and offline cache support.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Log Out'),
              content: const Text(
                'Are you sure you want to sign out of this POS terminal?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            await authProvider.signOut();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Sign Out Terminal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAccountDeletionCard(AuthProvider authProvider, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
              SizedBox(width: 10),
              Text(
                'Account & Data Privacy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your POS Hub account and remove all personal profile records, business memberships, and credentials from cloud servers. Compliant with Apple App Store Guideline 5.1.1(v).',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAccountDeletionDialog(authProvider),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text(
                'Delete Account & Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountDeletionDialog(AuthProvider authProvider) {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete Account?'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to permanently delete your account?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In accordance with Apple App Store Guideline 5.1.1(v) and privacy standards, this will:\n'
                    '• Permanently delete your user credentials\n'
                    '• Remove your store member records\n'
                    '• Revoke all cloud POS terminal access\n'
                    '• Erase associated personal profile data',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your password to verify ownership:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                  if (isDeleting) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
            actions: isDeleting
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final password = passwordController.text.trim();
                        if (password.isEmpty) {
                          setDialogState(() {
                            localError = 'Please enter your password to confirm.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isDeleting = true;
                          localError = null;
                        });

                        final success = await authProvider.deleteAccount(
                          password: password,
                        );

                        if (!mounted) return;

                        if (success) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          FeedbackService.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your account has been permanently deleted.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        } else {
                          setDialogState(() {
                            isDeleting = false;
                            localError = authProvider.error ?? 'Failed to delete account.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Permanently Delete'),
                    ),
                  ],
          );
        },
      ),
    );
  }

  void _showResetDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Restore default application settings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.resetToDefault();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
