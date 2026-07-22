import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/providers/settings_provider.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _filterType = 'All'; // All, Today, Week, Month, Custom
  String _searchQuery = '';
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _allSales = [];
  List<QueryDocumentSnapshot> _filteredSales = [];

  // For custom date range
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _filterOptions = ['All', 'Today', 'Week', 'Month', 'Custom'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Load sales based on filter type
  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot;
      
      switch (_filterType) {
        case 'Today':
          snapshot = await _firebaseService.getTodaySales();
          break;
        case 'Week':
          snapshot = await _firebaseService.getWeekSales();
          break;
        case 'Month':
          snapshot = await _firebaseService.getMonthSales();
          break;
        case 'Custom':
          if (_startDate != null && _endDate != null) {
            snapshot = await _firebaseService.getSalesByDateRange(
              startDate: _startDate!,
              endDate: _endDate!,
              limit: 500, // Optional: limit results
            );
          } else {
            snapshot = await _firebaseService.getAllSales();
          }
          break;
        default:
          snapshot = await _firebaseService.getAllSales();
          break;
      }
      
      setState(() {
        _allSales = snapshot.docs;
        _applySearchFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading sales: $e', isError: true);
    }
  }

  // ✅ Apply search filter only (date filter is now done on server)
  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSales = _allSales;
      return;
    }

    String query = _searchQuery.toLowerCase();
    _filteredSales = _allSales.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String productName = (data['productName'] ?? '').toLowerCase();
      String receiptNumber = (data['receiptNumber'] ?? '').toLowerCase();
      String paymentMethod = (data['paymentMethod'] ?? '').toLowerCase();
      
      return productName.contains(query) ||
          receiptNumber.contains(query) ||
          paymentMethod.contains(query);
    }).toList();
  }

  // ✅ Handle filter change
  void _onFilterChanged(String newFilter) async {
    if (newFilter == 'Custom') {
      // Show date picker for custom range
      final result = await _showDateRangePicker();
      if (result != null) {
        setState(() {
          _startDate = result.$1;
          _endDate = result.$2;
          _filterType = newFilter;
        });
        _loadSales();
      }
    } else if (_filterType != newFilter) {
      setState(() {
        _filterType = newFilter;
      });
      _loadSales();
    }
  }

  // ✅ Show date range picker
  Future<(DateTime, DateTime)?> _showDateRangePicker() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
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
      // Set end date to end of day
      final endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23, 59, 59,
      );
      return (picked.start, endDate);
    }
    return null;
  }

  // ✅ Handle search change
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase().trim();
      _applySearchFilter();
    });
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
        title: const Text('Sales History'),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(isDarkMode),
          if (_filterType == 'Custom' && _startDate != null && _endDate != null)
            _buildCustomDateRangeBadge(isDarkMode),
          _buildSearchBar(isDarkMode),
          _buildSummaryStats(isDarkMode, currencySymbol),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : _buildSalesList(currencySymbol, isDarkMode),
          ),
        ],
      ),
    );
  }

  // ✅ Show selected custom date range
  Widget _buildCustomDateRangeBadge(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 16,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
            style: TextStyle(
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _filterType = 'All';
              });
              _loadSales();
            },
            child: Icon(
              Icons.close,
              size: 16,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      child: Row(
        children: [
          Text(
            'Filter:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  bool isSelected = _filterType == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => _onFilterChanged(filter),
                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      selectedColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                      checkmarkColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700)
                            : (isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search by product, receipt, or payment...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _applySearchFilter();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDarkMode
              ? Colors.grey.shade800
              : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSummaryStats(bool isDarkMode, String currencySymbol) {
    if (_filteredSales.isEmpty) return const SizedBox.shrink();

    double totalSales = 0;
    double totalProfit = 0;
    int totalItems = 0;

    for (var doc in _filteredSales) {
      var data = doc.data() as Map<String, dynamic>;
      totalSales += (data['total'] ?? 0).toDouble();
      totalProfit += (data['profit'] ?? 0).toDouble();
      totalItems += (data['quantity'] ?? 0) as int;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Total Sales',
            value: '$currencySymbol${totalSales.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
            isDarkMode: isDarkMode,
          ),
          _buildStatItem(
            label: 'Total Profit',
            value: '$currencySymbol${totalProfit.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            isDarkMode: isDarkMode,
          ),
          _buildStatItem(
            label: 'Items Sold',
            value: totalItems.toString(),
            icon: Icons.shopping_cart,
            color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
            isDarkMode: isDarkMode,
          ),
          _buildStatItem(
            label: 'Transactions',
            value: _filteredSales.length.toString(),
            icon: Icons.receipt_long,
            color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
    );
  }

  Widget _buildSalesList(String currencySymbol, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSales.length,
      itemBuilder: (context, index) {
        var data = _filteredSales[index].data() as Map<String, dynamic>;
        DateTime saleDate = (data['saleDate'] as Timestamp).toDate();
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['productName'] ?? 'Unknown Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.shade900
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['paymentMethod'] ?? 'Cash',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode
                              ? Colors.blue.shade400
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Receipt: ${data['receiptNumber'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(saleDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity: ${data['quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'Price: $currencySymbol${(data['price'] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currencySymbol${(data['total'] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'Profit: $currencySymbol${(data['profit'] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No matching sales found' : 'No sales yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Start selling to see your sales history here',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _applySearchFilter();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}