import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/sale.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/format_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/empty_state_view.dart';

/// Modern Executive BI, Analytics & Reports Screen.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String _selectedPeriod = 'Today'; // 'Today', 'Week', 'Month', 'Year', 'All'
  bool _isLoading = true;

  // Aggregated BI Metrics
  double _grossSales = 0.0;
  double _netProfit = 0.0;
  int _totalOrders = 0;
  int _totalUnits = 0;
  double _avgOrderValue = 0.0;

  final Map<String, double> _paymentMethodSplit = {};
  final List<Map<String, dynamic>> _topProducts = [];
  final List<Map<String, dynamic>> _topCustomers = [];

  final List<String> _periodOptions = ['Today', 'Week', 'Month', 'Year', 'All'];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'Today':
          snapshot = await _firebaseService.getTodaySales();
          break;
        case 'Week':
          snapshot = await _firebaseService.getWeekSales();
          break;
        case 'Month':
          snapshot = await _firebaseService.getMonthSales();
          break;
        case 'Year':
          final startOfYear = DateTime(now.year, 1, 1);
          snapshot = await _firebaseService.getSalesByDateRange(startDate: startOfYear, endDate: now, limit: 2000);
          break;
        case 'All':
        default:
          snapshot = await _firebaseService.getAllSales();
          break;
      }

      _calculateMetrics(snapshot.docs);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackService.error();
    }
  }

  void _calculateMetrics(List<QueryDocumentSnapshot> docs) {
    _grossSales = 0.0;
    _netProfit = 0.0;
    _totalUnits = 0;
    _totalOrders = docs.length;
    _paymentMethodSplit.clear();
    _topProducts.clear();
    _topCustomers.clear();

    final Map<String, Map<String, dynamic>> productMap = {};
    final Map<String, Map<String, dynamic>> customerMap = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sale = Sale.fromMap(data, doc.id);

      _grossSales += sale.total;
      _netProfit += sale.profit;
      _totalUnits += sale.quantity;

      // Payment Split
      final method = sale.paymentMethod.isNotEmpty ? sale.paymentMethod : 'Cash';
      _paymentMethodSplit[method] = (_paymentMethodSplit[method] ?? 0.0) + sale.total;

      // Product Aggregates
      final pName = sale.productName.isNotEmpty ? sale.productName : 'General Item';
      if (!productMap.containsKey(pName)) {
        productMap[pName] = {'name': pName, 'revenue': 0.0, 'qty': 0};
      }
      productMap[pName]!['revenue'] = (productMap[pName]!['revenue'] as double) + sale.total;
      productMap[pName]!['qty'] = (productMap[pName]!['qty'] as int) + sale.quantity;

      // Customer Aggregates
      final cName = sale.customerDisplayName;
      if (cName != 'Guest' && cName.isNotEmpty) {
        if (!customerMap.containsKey(cName)) {
          customerMap[cName] = {'name': cName, 'spent': 0.0, 'orders': 0};
        }
        customerMap[cName]!['spent'] = (customerMap[cName]!['spent'] as double) + sale.total;
        customerMap[cName]!['orders'] = (customerMap[cName]!['orders'] as int) + 1;
      }
    }

    _avgOrderValue = _totalOrders > 0 ? _grossSales / _totalOrders : 0.0;

    // Sort Top Products
    _topProducts.addAll(productMap.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double)));

    // Sort Top Customers
    _topCustomers.addAll(customerMap.values.toList()
      ..sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double)));
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profitMargin = _grossSales > 0 ? (_netProfit / _grossSales) * 100 : 0.0;

    return Scaffold(
      body: Column(
        children: [
          // Period Switcher Bar
          _buildPeriodSelector(isDark),

          // Scrollable Reports Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _totalOrders == 0
                    ? const EmptyStateView(
                        icon: Icons.analytics_outlined,
                        title: 'No sales data for this period',
                        description: 'Select a different time period or process new sales on the POS register.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAnalytics,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Executive Profit & Loss Cards
                            _buildFinancialOverview(currencySymbol, profitMargin, isDark),
                            const SizedBox(height: 16),

                            // Payment Methods Split
                            _buildPaymentMethodChart(currencySymbol, isDark),
                            const SizedBox(height: 16),

                            // Top Products Leaderboard
                            _buildTopProductsCard(currencySymbol, isDark),
                            const SizedBox(height: 16),

                            // Top Spenders CRM Card
                            if (_topCustomers.isNotEmpty) ...[
                              _buildTopCustomersCard(currencySymbol, isDark),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periodOptions.map((period) {
            final isSelected = _selectedPeriod == period;
            final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(period),
                selected: isSelected,
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : null,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedPeriod = period;
                    _loadAnalytics();
                  });
                  FeedbackService.lightTap();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(String currencySymbol, double profitMargin, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: PosCard(
                gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gross Sales Revenue',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatService.formatCurrency(_grossSales, symbol: currencySymbol),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalOrders Transactions • $_totalUnits Units',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PosCard(
                gradient: isDark ? AppColors.darkCardGradient : AppColors.successGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Net Profit',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatService.formatCurrency(_netProfit, symbol: currencySymbol),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profitMargin.toStringAsFixed(1)}% Profit Margin',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PosCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Average Order Value (AOV)', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              Text(
                FormatService.formatCurrency(_avgOrderValue, symbol: currencySymbol),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChart(String currencySymbol, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Methods Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          ..._paymentMethodSplit.entries.map((entry) {
            final percent = _grossSales > 0 ? (entry.value / _grossSales) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '${FormatService.formatCurrency(entry.value, symbol: currencySymbol)} (${(percent * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(isDark ? AppColors.primaryLight : AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(String currencySymbol, bool isDark) {
    final top5 = _topProducts.take(5).toList();

    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...top5.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            final revenue = (item['revenue'] as double);
            final qty = (item['qty'] as int);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 1
                          ? AppColors.warning
                          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: index == 1 ? Colors.white : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('$qty units sold', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    FormatService.formatCurrency(revenue, symbol: currencySymbol),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopCustomersCard(String currencySymbol, bool isDark) {
    final top5 = _topCustomers.take(5).toList();

    return PosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top VIP Clients (This Period)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...top5.map((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.2),
                    child: Text(
                      (c['name'] as String).isNotEmpty ? (c['name'] as String)[0] : 'C',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${c['orders']} orders', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    FormatService.formatCurrency(c['spent'] as double, symbol: currencySymbol),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}