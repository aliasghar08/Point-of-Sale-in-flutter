import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/models/sale.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/format_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/stat_badge.dart';
import 'package:pos/widgets/empty_state_view.dart';

/// Modern Customer Profile, Analytics & Purchase History Screen.
class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final String? customerId;
  final String? customerName;

  const CustomerDetailScreen({
    super.key,
    this.customer,
    this.customerId,
    this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  Customer? _customer;
  List<Sale> _purchaseHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCustomerAndSales();
  }

  Future<void> _loadCustomerAndSales() async {
    setState(() => _isLoading = true);
    try {
      final effectiveId =
          widget.customerId ??
          widget.customer?['id'] ??
          widget.customer?['customerId'] ??
          '';

      if (widget.customer != null) {
        _customer = Customer.fromMap(widget.customer!, effectiveId);
      } else if (effectiveId.isNotEmpty) {
        final doc = await _firebaseService.getCustomerById(effectiveId);
        if (doc != null) {
          _customer = Customer.fromMap(doc, effectiveId);
        }
      }

      if (effectiveId.isNotEmpty) {
        final salesSnap = await _firebaseService.getCustomerSales(effectiveId);
        _purchaseHistory = salesSnap.docs.map((d) {
          return Sale.fromMap(d.data() as Map<String, dynamic>, d.id);
        }).toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customerName =
        _customer?.name ?? widget.customerName ?? 'Customer Profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadCustomerAndSales,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
          ? const EmptyStateView(
              icon: Icons.person_off_outlined,
              title: 'Customer not found',
              description:
                  'Unable to load customer profile details from database.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Client Header Card
                _buildProfileHeader(_customer!, currencySymbol, isDark),
                const SizedBox(height: 16),

                // Lifetime Stats Banner
                _buildStatsRow(_customer!, currencySymbol, isDark),
                const SizedBox(height: 20),

                // Purchase History Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Purchase & Order History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_purchaseHistory.length} Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Orders List
                if (_purchaseHistory.isEmpty)
                  const PosCard(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No previous transactions recorded for this customer.',
                      ),
                    ),
                  )
                else
                  ..._purchaseHistory.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOrderCard(s, currencySymbol, isDark),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(Customer c, String currencySymbol, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    (isDark ? AppColors.primaryLight : AppColors.primary)
                        .withValues(alpha: 0.15),
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontSize: 26,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatBadge.tier(c.customerValueCategory),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.phone.isNotEmpty ? c.phone : 'No Phone Provided',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (c.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        c.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (c.address.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(Customer c, String currencySymbol, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: PosCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spend (LTV)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FormatService.formatCurrency(
                    c.totalSpent,
                    symbol: currencySymbol,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Orders',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.totalOrders}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PosCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loyalty Pts',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.loyaltyPoints}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Sale s, String currencySymbol, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              s.receiptNumber,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.quantity}x ${s.productName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${FormatService.formatDateTime(s.saleDate)} • ${s.paymentMethod}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            FormatService.formatCurrency(s.total, symbol: currencySymbol),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias
typedef CustomerDetailsScreen = CustomerDetailScreen;
