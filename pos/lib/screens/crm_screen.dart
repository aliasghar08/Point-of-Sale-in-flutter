import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/screens/customer_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/providers/settings_provider.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, High Value, Medium Value, Low Value, New
  
  final List<String> _filterOptions = [
    'All',
    'High Value',
    'Medium Value',
    'Low Value',
    'New Customers',
  ];

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

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _firebaseService.getCustomers();
      setState(() {
        _customers = customers..sort((a, b) => b['totalSpent'].compareTo(a['totalSpent']));
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading customers: $e', isError: true);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_customers);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((customer) {
        return customer['name'].toLowerCase().contains(query) ||
            customer['phone'].contains(query) ||
            customer['email'].toLowerCase().contains(query);
      }).toList();
    }

    // Apply value filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((customer) {
        final spent = customer['totalSpent'] ?? 0.0;
        switch (_selectedFilter) {
          case 'High Value':
            return spent >= 10000;
          case 'Medium Value':
            return spent >= 5000 && spent < 10000;
          case 'Low Value':
            return spent >= 1000 && spent < 5000;
          case 'New Customers':
            return spent < 1000;
          default:
            return true;
        }
      }).toList();
    }

    setState(() {
      _filteredCustomers = filtered;
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
        title: const Text(
          'Customer Relationship Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              _showSnackBar('Export feature coming soon!');
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(isDarkMode),
          _buildSummaryStats(currencySymbol, isDarkMode),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : _buildCustomerList(currencySymbol, isDarkMode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCustomerDialog(context);
        },
        backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Customer',
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDarkMode) {
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
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Search customers by name, phone, or email...',
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
                          _applyFilters();
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700)
                            : (isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilters();
                      });
                    },
                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    selectedColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(String currencySymbol, bool isDarkMode) {
    if (_filteredCustomers.isEmpty) return const SizedBox.shrink();

    int totalCustomers = _filteredCustomers.length;
    double totalRevenue = 0;
    int totalOrders = 0;

    for (var customer in _filteredCustomers) {
      totalRevenue += customer['totalSpent'] ?? 0.0;
      totalOrders += (customer['totalOrders'] ?? 0) as int;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Customers',
            value: totalCustomers.toString(),
            icon: Icons.people,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            isDarkMode: isDarkMode,
          ),
          _buildStatItem(
            label: 'Revenue',
            value: '$currencySymbol${totalRevenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
            isDarkMode: isDarkMode,
          ),
          _buildStatItem(
            label: 'Avg per Customer',
            value: totalCustomers > 0 
                ? '$currencySymbol${(totalRevenue / totalCustomers).toStringAsFixed(0)}'
                : '0',
            icon: Icons.trending_up,
            color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
            isDarkMode: isDarkMode,
          ),
          _buildStatItem(
            label: 'Total Orders',
            value: totalOrders.toString(),
            icon: Icons.shopping_cart,
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

  Widget _buildCustomerList(String currencySymbol, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return _buildCustomerCard(customer, currencySymbol, isDarkMode);
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, String currencySymbol, bool isDarkMode) {
    final name = customer['name'] ?? 'Unknown Customer';
    final phone = customer['phone'] ?? '';
    final email = customer['email'] ?? '';
    final totalSpent = customer['totalSpent'] ?? 0.0;
    final totalOrders = customer['totalOrders'] ?? 0;
    final lastPurchase = customer['lastPurchaseDate'] != null
        ? (customer['lastPurchaseDate'] as Timestamp).toDate()
        : null;
    final createdAt = customer['createdAt'] != null
        ? (customer['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    final initials = name.isNotEmpty 
        ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    // Determine customer value category
    String valueBadge;
    Color badgeColor;
    if (totalSpent >= 10000) {
      valueBadge = '🏆 High Value';
      badgeColor = isDarkMode ? Colors.green.shade400 : Colors.green.shade700;
    } else if (totalSpent >= 5000) {
      valueBadge = '⭐ Medium Value';
      badgeColor = isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;
    } else if (totalSpent >= 1000) {
      valueBadge = '💫 Low Value';
      badgeColor = isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700;
    } else {
      valueBadge = '🆕 New Customer';
      badgeColor = isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(
                customerId: customer['id'],
                customerName: name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            '📱 $phone',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        if (email.isNotEmpty)
                          Text(
                            '✉️ $email',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currencySymbol${totalSpent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        '$totalOrders orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      valueBadge,
                      style: TextStyle(
                        fontSize: 11,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (lastPurchase != null)
                    Text(
                      'Last: ${DateFormat('dd MMM yyyy').format(lastPurchase)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'No matching customers found'
                : 'No customers yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'Try adjusting your search or filters'
                : 'Customers will appear here after their first purchase',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedFilter = 'All';
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear All Filters'),
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

  // ========== ADD CUSTOMER DIALOG ==========
  void _showAddCustomerDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _emailController = TextEditingController();
    final _addressController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Customer',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.dispose();
              _phoneController.dispose();
              _emailController.dispose();
              _addressController.dispose();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                // We can't directly add a customer without a sale
                // So we'll show a message
                Navigator.pop(context);
                _showSnackBar(
                  '💡 Customers are automatically added when they make a purchase. '
                  'Please process a sale for this customer to save their info.',
                  isError: false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }
}