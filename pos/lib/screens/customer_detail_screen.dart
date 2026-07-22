import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/providers/settings_provider.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _customer;
  List<QueryDocumentSnapshot> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadCustomerDetails();
  }

  Future<void> _loadCustomerDetails() async {
    setState(() => _isLoading = true);
    try {
      final customer = await _firebaseService.getCustomerById(widget.customerId);
      if (customer != null) {
        final sales = await _firebaseService.getCustomerSales(widget.customerId);
        setState(() {
          _customer = customer;
          _sales = sales.docs;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading customer details: $e', isError: true);
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
        title: Text(
          widget.customerName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCustomerDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Customer not found',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCustomerInfo(isDarkMode),
                      const SizedBox(height: 16),
                      _buildStats(currencySymbol, isDarkMode),
                      const SizedBox(height: 16),
                      _buildSalesHistory(currencySymbol, isDarkMode),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCustomerInfo(bool isDarkMode) {
    final name = _customer?['name'] ?? 'Unknown';
    final phone = _customer?['phone'] ?? '';
    final email = _customer?['email'] ?? '';
    final address = _customer?['address'] ?? '';
    final createdAt = _customer?['createdAt'] != null
        ? (_customer!['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      '📱 $phone',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  if (email.isNotEmpty)
                    Text(
                      '✉️ $email',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  if (address.isNotEmpty)
                    Text(
                      '📍 $address',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    'Customer since: ${DateFormat('dd MMM yyyy').format(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(String currencySymbol, bool isDarkMode) {
    final totalSpent = _customer?['totalSpent'] ?? 0.0;
    final totalOrders = _customer?['totalOrders'] ?? 0;
    final avgOrder = totalOrders > 0 ? totalSpent / totalOrders : 0;
    final lastPurchase = _customer?['lastPurchaseDate'] != null
        ? (_customer!['lastPurchaseDate'] as Timestamp).toDate()
        : null;

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Orders', totalOrders.toString(), isDarkMode),
            _buildStatRow('Total Spent', '$currencySymbol${totalSpent.toStringAsFixed(2)}', isDarkMode),
            _buildStatRow('Average Order', '$currencySymbol${avgOrder.toStringAsFixed(2)}', isDarkMode),
            if (lastPurchase != null)
              _buildStatRow(
                'Last Purchase',
                DateFormat('dd MMM yyyy, hh:mm a').format(lastPurchase),
                isDarkMode,
              ),
            _buildStatRow(
              'Customer Value',
              _getCustomerValue(totalSpent),
              isDarkMode,
              valueColor: _getValueColor(totalSpent, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDarkMode, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _getCustomerValue(double totalSpent) {
    if (totalSpent >= 10000) return '🏆 High Value';
    if (totalSpent >= 5000) return '⭐ Medium Value';
    if (totalSpent >= 1000) return '💫 Low Value';
    return '🆕 New Customer';
  }

  Color _getValueColor(double totalSpent, bool isDarkMode) {
    if (totalSpent >= 10000) return isDarkMode ? Colors.green.shade400 : Colors.green.shade700;
    if (totalSpent >= 5000) return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;
    if (totalSpent >= 1000) return isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700;
    return isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700;
  }

  Widget _buildSalesHistory(String currencySymbol, bool isDarkMode) {
    return Card(
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
                Text(
                  'Sales History (${_sales.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Total: $currencySymbol${_sales.fold(0.0, (sum, doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return sum + (data['total'] ?? 0.0);
                  }).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_sales.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No sales yet',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              ..._sales.take(20).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['saleDate'] as Timestamp?)?.toDate();
                final productName = data['productName'] ?? 'Unknown Product';
                final quantity = data['quantity'] ?? 0;
                final total = data['total'] ?? 0.0;
                final receiptNumber = data['receiptNumber'] ?? 'N/A';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Qty: $quantity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Receipt: $receiptNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currencySymbol${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                            ),
                          ),
                          if (date != null)
                            Text(
                              DateFormat('dd MMM yy').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}