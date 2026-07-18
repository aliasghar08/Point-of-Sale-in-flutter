import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedPeriod = 'Today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  
  // Statistics
  double _totalSales = 0;
  double _totalProfit = 0;
  int _totalItems = 0;
  int _totalTransactions = 0;
  double _averageSale = 0;
  
  // Top products
  List<Map<String, dynamic>> _topProducts = [];
  
  // Payment method breakdown
  Map<String, double> _paymentBreakdown = {};
  
  // Daily sales data for chart
  List<Map<String, dynamic>> _dailySales = [];

  final List<String> _periodOptions = [
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
      await _fetchSalesData();
      await _fetchTopProducts();
      await _fetchPaymentBreakdown();
      await _fetchDailySales();
      _calculateStatistics();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading reports: $e', isError: true);
    }
  }

  Future<void> _fetchSalesData() async {
    DateTime startDate = _getStartDate();
    DateTime endDate = _getEndDate();

    QuerySnapshot snapshot = await _firebaseService.sales
        .where('saleDate', isGreaterThanOrEqualTo: startDate)
        .where('saleDate', isLessThanOrEqualTo: endDate)
        .get();

    _totalSales = 0;
    _totalProfit = 0;
    _totalItems = 0;
    _totalTransactions = snapshot.docs.length;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      _totalSales += (data['total'] ?? 0).toDouble();
      _totalProfit += (data['profit'] ?? 0).toDouble();
      _totalItems += (data['quantity'] ?? 0).toInt() as int;
    }

    _averageSale = _totalTransactions > 0 ? _totalSales / _totalTransactions : 0;
  }

  Future<void> _fetchTopProducts() async {
    DateTime startDate = _getStartDate();
    DateTime endDate = _getEndDate();

    QuerySnapshot snapshot = await _firebaseService.sales
        .where('saleDate', isGreaterThanOrEqualTo: startDate)
        .where('saleDate', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, Map<String, dynamic>> productMap = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String productId = data['productId'] ?? '';
      String productName = data['productName'] ?? 'Unknown';
      int quantity = (data['quantity'] ?? 0).toInt();
      double total = (data['total'] ?? 0).toDouble();

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
    }

    _topProducts = productMap.values.toList();
    _topProducts.sort((a, b) => b['quantity'].compareTo(a['quantity']));
    _topProducts = _topProducts.take(10).toList();
  }

  Future<void> _fetchPaymentBreakdown() async {
    DateTime startDate = _getStartDate();
    DateTime endDate = _getEndDate();

    QuerySnapshot snapshot = await _firebaseService.sales
        .where('saleDate', isGreaterThanOrEqualTo: startDate)
        .where('saleDate', isLessThanOrEqualTo: endDate)
        .get();

    _paymentBreakdown = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String method = data['paymentMethod'] ?? 'Cash';
      double total = (data['total'] ?? 0).toDouble();

      _paymentBreakdown[method] = (_paymentBreakdown[method] ?? 0) + total;
    }
  }

  Future<void> _fetchDailySales() async {
    DateTime startDate = _getStartDate();
    DateTime endDate = _getEndDate();

    QuerySnapshot snapshot = await _firebaseService.sales
        .where('saleDate', isGreaterThanOrEqualTo: startDate)
        .where('saleDate', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, double> dailyMap = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime date = (data['saleDate'] as Timestamp).toDate();
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      double total = (data['total'] ?? 0).toDouble();

      dailyMap[dateKey] = (dailyMap[dateKey] ?? 0) + total;
    }

    _dailySales = dailyMap.entries.map((entry) {
      return {
        'date': entry.key,
        'sales': entry.value,
      };
    }).toList();
    _dailySales.sort((a, b) => a['date'].compareTo(b['date']));
  }

  void _calculateStatistics() {
    // Already calculated in fetchSalesData
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
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
                  _buildSalesChart(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  _buildPaymentBreakdown(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
                  _buildTopProducts(currencySymbol, isDarkMode),
                  const SizedBox(height: 16),
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
              brightness: Theme.of(context).brightness,
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

  Widget _buildSalesChart(String currencySymbol, bool isDarkMode) {
    if (_dailySales.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxSales = _dailySales.fold(0.0, (max, item) {
      return item['sales'] > max ? item['sales'] : max;
    });

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
                      double height = maxSales > 0 ? (item['sales'] / maxSales) * 100 : 0;
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