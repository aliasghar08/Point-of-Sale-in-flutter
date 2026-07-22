import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/services/firebase_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedPeriod = 'All'; // Default to All
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  
  // Statistics
  double _totalSales = 0;
  double _totalProfit = 0;
  int _totalItems = 0;
  int _totalTransactions = 0;
  double _averageSale = 0;
  
  // ✅ Customer Statistics
  int _totalCustomers = 0;
  int _guestCustomers = 0;
  int _registeredCustomers = 0;
  double _averageCustomerSpend = 0;
  
  // Top products
  List<Map<String, dynamic>> _topProducts = [];
  
  // ✅ Top customers
  List<Map<String, dynamic>> _topCustomers = [];
  
  // Payment method breakdown
  Map<String, double> _paymentBreakdown = {};
  
  // Daily sales data for chart
  List<Map<String, dynamic>> _dailySales = [];

  final List<String> _periodOptions = [
    'All',
    'Today',
    'Week',
    'Month',
    'Year',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot;
      
      // Fetch sales based on selected period
      if (_selectedPeriod == 'All') {
        // Get all sales from business
        snapshot = await _firebaseService.getAllSales();
      } else {
        // Get the date range
        final startDate = _getStartDate();
        final endDate = _getEndDate();

        // Fetch sales in date range using FirebaseService
        snapshot = await _firebaseService.getSalesByDateRange(
          startDate: startDate,
          endDate: endDate,
          limit: 1000,
        );
      }

      // Process the data
      _processSalesData(snapshot.docs);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading reports: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
      print('❌ Reports error: $e');
    }
  }

  void _processSalesData(List<QueryDocumentSnapshot> docs) {
    // Reset stats
    _totalSales = 0;
    _totalProfit = 0;
    _totalItems = 0;
    _totalTransactions = docs.length;
    
    // ✅ Reset customer stats
    _totalCustomers = 0;
    _guestCustomers = 0;
    _registeredCustomers = 0;
    _averageCustomerSpend = 0;
    
    // Maps for processing
    Map<String, Map<String, dynamic>> productMap = {};
    Map<String, double> paymentMap = {};
    Map<String, double> dailyMap = {};
    
    // ✅ Customer tracking
    Map<String, Map<String, dynamic>> customerMap = {};

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      
      // Sales totals
      double total = (data['total'] ?? 0).toDouble();
      double profit = (data['profit'] ?? 0).toDouble();
      int quantity = (data['quantity'] ?? 0).toInt();
      
      _totalSales += total;
      _totalProfit += profit;
      _totalItems += quantity;

      // Payment breakdown
      String method = data['paymentMethod'] ?? 'Cash';
      paymentMap[method] = (paymentMap[method] ?? 0) + total;

      // Top products
      String productId = data['productId'] ?? '';
      String productName = data['productName'] ?? 'Unknown';
      
      if (productMap.containsKey(productId)) {
        productMap[productId]!['quantity'] += quantity;
        productMap[productId]!['total'] += total;
      } else {
        productMap[productId] = {
          'name': productName,
          'quantity': quantity,
          'total': total,
        };
      }

      // Daily sales
      DateTime date = (data['saleDate'] as Timestamp).toDate();
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyMap[dateKey] = (dailyMap[dateKey] ?? 0) + total;

      // ✅ Customer tracking
      String customerId = data['customerId'] ?? 'guest';
      String customerName = data['customerName'] ?? 'Guest Customer';
      bool isGuest = data['isGuestCustomer'] ?? true;
      
      if (isGuest) {
        _guestCustomers++;
      } else {
        _registeredCustomers++;
      }
      
      if (customerMap.containsKey(customerId)) {
        customerMap[customerId]!['totalSpent'] += total;
        customerMap[customerId]!['orders'] += 1;
      } else {
        _totalCustomers++;
        customerMap[customerId] = {
          'name': customerName,
          'id': customerId,
          'totalSpent': total,
          'orders': 1,
          'isGuest': isGuest,
        };
      }
    }

    // Calculate average
    _averageSale = _totalTransactions > 0 ? _totalSales / _totalTransactions : 0;
    _averageCustomerSpend = _totalCustomers > 0 ? _totalSales / _totalCustomers : 0;

    // Process top products
    _topProducts = productMap.values.toList();
    _topProducts.sort((a, b) => b['quantity'].compareTo(a['quantity']));
    _topProducts = _topProducts.take(10).toList();

    // ✅ Process top customers
    _topCustomers = customerMap.values.toList();
    _topCustomers.sort((a, b) => b['totalSpent'].compareTo(a['totalSpent']));
    _topCustomers = _topCustomers.take(10).toList();

    // Process payment breakdown
    _paymentBreakdown = paymentMap;

    // Process daily sales
    _dailySales = dailyMap.entries.map((entry) {
      return {
        'date': entry.key,
        'sales': entry.value,
      };
    }).toList();
    _dailySales.sort((a, b) => a['date'].compareTo(b['date']));
  }

  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'Month':
        return DateTime(now.year, now.month, 1);
      case 'Year':
        return DateTime(now.year, 1, 1);
      case 'Custom':
        return _startDate;
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime _getEndDate() {
    DateTime now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'Week':
        return now;
      case 'Month':
        return now;
      case 'Year':
        return now;
      case 'Custom':
        return _endDate;
      default:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isError
            ? (isDarkMode ? Colors.red.shade400 : Colors.red.shade700)
            : (isDarkMode ? Colors.green.shade400 : Colors.green.shade700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _showSnackBar('Export feature coming soon!');
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPeriodSelector(isDarkMode),
                  const SizedBox(height: 16),
                  _buildSummaryCards(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  _buildCustomerSummary(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  if (_dailySales.isNotEmpty && _selectedPeriod != 'All')
                    _buildSalesChart(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  if (_paymentBreakdown.isNotEmpty)
                    _buildPaymentBreakdown(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  if (_topProducts.isNotEmpty)
                    _buildTopProducts(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  if (_topCustomers.isNotEmpty)
                    _buildTopCustomers(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  if (_totalTransactions > 0)
                    _buildDetailedStats(currencySymbol, isDarkMode),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _periodOptions.map((period) {
              bool isSelected = _selectedPeriod == period;
              return FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedPeriod = period;
                    if (period == 'Custom') {
                      _selectCustomDateRange();
                    } else {
                      _loadReports();
                    }
                  });
                },
                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                selectedColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                labelStyle: TextStyle(
                  color: isSelected
                      ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700)
                      : (isDarkMode ? Colors.white : Colors.black),
                ),
                checkmarkColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              );
            }).toList(),
          ),
          if (_selectedPeriod == 'Custom')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selectCustomDateRange,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  Widget _buildSummaryCards(String currencySymbol, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Sales',
            value: '$currencySymbol${_totalSales.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Profit',
            value: '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Customer Summary Section
  Widget _buildCustomerSummary(String currencySymbol, bool isDarkMode) {
    if (_totalCustomers == 0 && _guestCustomers == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Customer Insights',
                style: TextStyle(
                  fontSize: 16,
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
                child: _buildCustomerStat(
                  label: 'Total Customers',
                  value: _totalCustomers.toString(),
                  icon: Icons.people_outline,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  isDarkMode: isDarkMode,
                ),
              ),
              Expanded(
                child: _buildCustomerStat(
                  label: 'Registered',
                  value: _registeredCustomers.toString(),
                  icon: Icons.person,
                  color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                  isDarkMode: isDarkMode,
                ),
              ),
              Expanded(
                child: _buildCustomerStat(
                  label: 'Guest',
                  value: _guestCustomers.toString(),
                  icon: Icons.person_outline,
                  color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCustomerStat(
                  label: 'Avg. Spend',
                  value: '$currencySymbol${_averageCustomerSpend.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700,
                  isDarkMode: isDarkMode,
                ),
              ),
              Expanded(
                child: _buildCustomerStat(
                  label: 'Avg. Orders',
                  value: _totalTransactions > 0 && _totalCustomers > 0
                      ? (_totalTransactions / _totalCustomers).toStringAsFixed(1)
                      : '0',
                  icon: Icons.shopping_cart_outlined,
                  color: isDarkMode ? Colors.cyan.shade400 : Colors.cyan.shade700,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(String currencySymbol, bool isDarkMode) {
    if (_dailySales.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxSales = _dailySales.fold(0.0, (max, item) {
      return item['sales'] > max ? item['sales'] : max;
    });

    // If max is 0, set to 1 to avoid division by zero
    if (maxSales == 0) maxSales = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Sales Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                // Y-axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currencySymbol${maxSales.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${currencySymbol}0',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Chart bars
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _dailySales.map((item) {
                      double height = (item['sales'] / maxSales) * 100;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    isDarkMode
                                        ? Colors.blue.shade900
                                        : Colors.blue.shade200,
                                    isDarkMode
                                        ? Colors.blue.shade400
                                        : Colors.blue.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd').format(DateTime.parse(item['date'])),
                              style: TextStyle(
                                fontSize: 8,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(String currencySymbol, bool isDarkMode) {
    if (_paymentBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    double total = _paymentBreakdown.values.fold(0.0, (sum, value) => sum + value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentBreakdown.entries.map((entry) {
            double percentage = (entry.value / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '$currencySymbol${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPaymentColor(entry.key, isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getPaymentColor(String method, bool isDarkMode) {
    switch (method) {
      case 'Cash':
        return isDarkMode ? Colors.green.shade400 : Colors.green;
      case 'Card':
        return isDarkMode ? Colors.blue.shade400 : Colors.blue;
      case 'Mobile Payment':
        return isDarkMode ? Colors.orange.shade400 : Colors.orange;
      case 'Credit':
        return isDarkMode ? Colors.purple.shade400 : Colors.purple;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey;
    }
  }

  Widget _buildTopProducts(String currencySymbol, bool isDarkMode) {
    if (_topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: isDarkMode ? Colors.yellow.shade400 : Colors.yellow.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topProducts.length,
            itemBuilder: (context, index) {
              var product = _topProducts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '${product['quantity']} units',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$currencySymbol${product['total'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ Top Customers Section
  Widget _buildTopCustomers(String currencySymbol, bool isDarkMode) {
    if (_topCustomers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Customers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topCustomers.length,
            itemBuilder: (context, index) {
              var customer = _topCustomers[index];
              final isGuest = customer['isGuest'] ?? true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isGuest
                            ? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
                            : (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isGuest
                                ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
                                : (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? 'Guest Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '${customer['orders']} orders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$currencySymbol${customer['totalSpent'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                                ),
                              ),
                              if (isGuest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Guest',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(String currencySymbol, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: isDarkMode ? Colors.cyan.shade400 : Colors.cyan.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Detailed Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Total Transactions', _totalTransactions.toString(), isDarkMode),
          _buildDetailRow('Total Items Sold', _totalItems.toString(), isDarkMode),
          _buildDetailRow('Average Sale Value', '$currencySymbol${_averageSale.toStringAsFixed(2)}', isDarkMode),
          _buildDetailRow('Total Sales', '$currencySymbol${_totalSales.toStringAsFixed(2)}', isDarkMode),
          _buildDetailRow('Total Profit', '$currencySymbol${_totalProfit.toStringAsFixed(2)}', isDarkMode),
          _buildDetailRow(
            'Profit Margin',
            '${_totalSales > 0 ? ((_totalProfit / _totalSales) * 100).toStringAsFixed(1) : 0}%',
            isDarkMode,
          ),
          _buildDetailRow(
            'Period',
            _selectedPeriod == 'Custom'
                ? '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'
                : _selectedPeriod == 'All'
                    ? 'All Time'
                    : _selectedPeriod,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}