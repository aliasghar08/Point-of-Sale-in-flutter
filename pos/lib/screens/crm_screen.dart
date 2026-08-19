import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/services/customer_service.dart';
import 'package:pos/services/format_service.dart';
import 'package:pos/services/export_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/services/validation_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/stat_badge.dart';
import 'package:pos/widgets/empty_state_view.dart';
import 'package:pos/screens/customer_detail_screen.dart';

/// Modern Customer Relationship Management (CRM) & Loyalty Directory.
class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';
  String _selectedTier = 'All';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _customerService.getAllCustomers(forceRefresh: force);
      setState(() {
        _customers = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackService.error();
    }
  }

  void _applyFilters() {
    List<Customer> list = List.from(_customers);

    if (_selectedTier != 'All') {
      list = list
          .where((c) => c.customerValueCategory.contains(_selectedTier))
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q);
      }).toList();
    }

    setState(() => _filteredCustomers = list);
  }

  void _exportCustomers() {
    final csv = ExportService.exportCustomersToCsv(_filteredCustomers);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported Customers CRM (CSV)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer directory ready!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Full Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => ValidationService.validateRequired(
                    v,
                    fieldName: 'Full Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => ValidationService.isValidPhone(v)
                      ? null
                      : 'Enter valid phone number',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return ValidationService.isValidEmail(v)
                        ? null
                        : 'Enter valid email';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  await _customerService.addCustomer(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addrCtrl.text.trim(),
                  );
                  FeedbackService.success();
                  _loadCustomers(force: true);
                } catch (e) {
                  FeedbackService.error();
                }
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalSpent = _customers.fold(0.0, (sum, c) => sum + c.totalSpent);
    final avgSpend = _customers.isEmpty ? 0.0 : totalSpent / _customers.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerModal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Customer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
      ),
      body: Column(
        children: [
          // Top Search & Actions
          _buildTopBar(isDark),

          // Overview Metrics Bar
          _buildMetricsBar(
            totalCustomers: _customers.length,
            totalSpent: totalSpent,
            avgSpend: avgSpend,
            currencySymbol: currencySymbol,
            isDark: isDark,
          ),

          // Tier Filter Chips
          _buildTierFilter(isDark),

          // Customers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? EmptyStateView(
                    icon: Icons.people_outline,
                    title: 'No customers found',
                    description: _customers.isEmpty
                        ? 'Your customer directory is empty. Register your first customer!'
                        : 'No customer matches your search criteria.',
                    actionLabel: 'Add New Customer',
                    onAction: _showAddCustomerModal,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCustomers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _buildCustomerCard(
                      _filteredCustomers[i],
                      currencySymbol,
                      isDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _searchQuery = val;
                _applyFilters();
              },
              decoration: const InputDecoration(
                hintText: 'Search customers by name, phone, or email...',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exportCustomers,
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadCustomers(force: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBar({
    required int totalCustomers,
    required double totalSpent,
    required double avgSpend,
    required String currencySymbol,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: PosCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Directory',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalCustomers Clients',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PosCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LTV Revenue',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FormatService.formatCurrency(
                      totalSpent,
                      symbol: currencySymbol,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PosCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg Value',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FormatService.formatCurrency(
                      avgSpend,
                      symbol: currencySymbol,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierFilter(bool isDark) {
    final tiers = ['All', 'High Value', 'Medium Value', 'Low Value'];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tiers.length,
        itemBuilder: (ctx, i) {
          final t = tiers[i];
          final isSelected = _selectedTier == t;
          final primaryColor = isDark
              ? AppColors.primaryLight
              : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(t),
              selected: isSelected,
              selectedColor: primaryColor.withValues(alpha: 0.2),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : null,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedTier = t;
                  _applyFilters();
                });
                FeedbackService.lightTap();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerCard(Customer c, String currencySymbol, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(
              customer: {
                'id': c.id,
                'name': c.name,
                'phone': c.phone,
                'email': c.email,
                'address': c.address,
                'totalSpent': c.totalSpent,
                'totalOrders': c.totalOrders,
                'averageOrderValue': c.averageOrderValue,
                'lastPurchaseDate': c.lastPurchaseDate?.toIso8601String(),
              },
            ),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                (isDark ? AppColors.primaryLight : AppColors.primary)
                    .withValues(alpha: 0.15),
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatBadge.tier(c.customerValueCategory),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.phone} • ${c.totalOrders} Orders • Lifetime: ${FormatService.formatCurrency(c.totalSpent, symbol: currencySymbol)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ],
      ),
    );
  }
}
