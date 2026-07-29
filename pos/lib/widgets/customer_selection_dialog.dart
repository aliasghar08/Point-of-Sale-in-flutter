import 'package:flutter/material.dart';
import 'package:pos/services/firebase_service.dart';

class CustomerDetails {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final bool isGuest;

  CustomerDetails({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.isGuest,
  });
}

class CustomerSelectionDialog extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialEmail;
  final String? initialAddress;

  const CustomerSelectionDialog({
    super.key,
    this.initialName = '',
    this.initialPhone = '',
    this.initialEmail,
    this.initialAddress,
  });

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  String? _selectedCustomerId;
  String? _selectedCustomerName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName == 'Guest Customer' ? '' : widget.initialName,
    );
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _addressController = TextEditingController(text: widget.initialAddress ?? '');

    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _firebaseService.getCustomers();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _suggestions = _allCustomers.where((customer) {
        final name = (customer['name'] ?? customer['customerName'] ?? '').toString().toLowerCase();
        final phone = (customer['phone'] ?? customer['customerPhone'] ?? '').toString().toLowerCase();
        final email = (customer['email'] ?? customer['customerEmail'] ?? '').toString().toLowerCase();
        return name.contains(cleanQuery) || phone.contains(cleanQuery) || email.contains(cleanQuery);
      }).take(5).toList();
    });
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _selectedCustomerId = customer['id'] as String?;
      _selectedCustomerName = (customer['name'] ?? customer['customerName'] ?? 'Customer').toString();
      
      _nameController.text = (customer['name'] ?? customer['customerName'] ?? '').toString();
      _phoneController.text = (customer['phone'] ?? customer['customerPhone'] ?? '').toString();
      _emailController.text = (customer['email'] ?? customer['customerEmail'] ?? '').toString();
      _addressController.text = (customer['address'] ?? customer['customerAddress'] ?? '').toString();
      
      _searchController.clear();
      _suggestions = [];
    });
  }

  void _clearSelectedCustomer() {
    setState(() {
      _selectedCustomerId = null;
      _selectedCustomerName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.person_pin, color: primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Customer Info',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Search Bar for Existing Customers
              TextField(
                controller: _searchController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search Existing Customers',
                  hintText: 'Type name, phone, or email...',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),

              // Suggestions Dropdown List
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(0.5)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    itemBuilder: (context, index) {
                      final customer = _suggestions[index];
                      final name = (customer['name'] ?? customer['customerName'] ?? 'Unknown').toString();
                      final phone = (customer['phone'] ?? customer['customerPhone'] ?? '').toString();
                      final email = (customer['email'] ?? customer['customerEmail'] ?? '').toString();

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (phone.isNotEmpty) phone,
                            if (email.isNotEmpty) email,
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: primaryColor),
                        onTap: () => _selectCustomer(customer),
                      );
                    },
                  ),
                ),
              ],

              // Active Selection Badge
              if (_selectedCustomerId != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Existing Customer Selected: $_selectedCustomerName',
                          style: TextStyle(
                            color: isDarkMode ? Colors.green.shade300 : Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        onPressed: _clearSelectedCustomer,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Name Field
                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Customer Name',
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone Field
                      TextField(
                        controller: _phoneController,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Email (optional)',
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      // Address Field
                      TextField(
                        controller: _addressController,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Address (optional)',
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.home),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // Skip Guest button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        CustomerDetails(
                          id: 'guest',
                          name: 'Guest Customer',
                          phone: '',
                          email: null,
                          address: null,
                          isGuest: true,
                        ),
                      );
                    },
                    child: Text(
                      'Skip (Guest)',
                      style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                  ),
                  const Spacer(),
                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final phone = _phoneController.text.trim();
                      final email = _emailController.text.trim();
                      final address = _addressController.text.trim();

                      final isGuest = name.isEmpty || name == 'Guest Customer';
                      final customerId = isGuest
                          ? 'guest'
                          : (_selectedCustomerId ?? 'customer_${DateTime.now().millisecondsSinceEpoch}');

                      Navigator.pop(
                        context,
                        CustomerDetails(
                          id: customerId,
                          name: isGuest ? 'Guest Customer' : name,
                          phone: phone,
                          email: email.isNotEmpty ? email : null,
                          address: address.isNotEmpty ? address : null,
                          isGuest: isGuest,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Save Customer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
