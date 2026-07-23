import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pos/widgets/barcode_scanner.dart';
import 'package:pos/widgets/qr_scanner.dart';
import 'package:pos/widgets/voice_input.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/product_reference.dart';
import 'package:pos/widgets/product_autocomplete.dart';
import 'package:pos/widgets/receipt_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Product> _cartItems = [];
  double _totalAmount = 0.0;
  double _totalProfit = 0.0;
  bool _isLoading = false;
  String _selectedPaymentMethod = 'Cash';

  // Customer Info for checkout
  String _customerId = 'guest';
  String _customerName = 'Guest Customer';
  String _customerPhone = '';
  String? _customerEmail;
  String? _customerAddress;
  bool _isGuestCustomer = true;

  final List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Mobile Payment',
    'Credit',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final showProfit = settingsProvider.showProfitInPOS;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ✅ RESPONSIVE LAYOUT BUILDER
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // If screen is wide (PC/Web/Tablet Landscape)
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(currencySymbol, showProfit, isDarkMode);
          }
          // If screen is narrow (Mobile)
          return _buildMobileLayout(currencySymbol, showProfit, isDarkMode);
        },
      ),
    );
  }

  // ==================== LAYOUT: MOBILE ====================
  Widget _buildMobileLayout(String currencySymbol, bool showProfit, bool isDarkMode) {
    return Column(
      children: [
        _buildSearchSection(isDarkMode),
        Expanded(
          flex: 1,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
                  ? _buildEmptyCartPrompt(isDarkMode)
                  : _buildCartList(currencySymbol, isDarkMode),
        ),
        _buildCheckoutSection(currencySymbol, showProfit, isDarkMode),
      ],
    );
  }

  // ==================== LAYOUT: DESKTOP / WEB ====================
  Widget _buildDesktopLayout(String currencySymbol, bool showProfit, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT PANE: Search & Prompt
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSearchSection(isDarkMode),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildEmptyCartPrompt(isDarkMode), // Show big search prompt on left
              ),
            ],
          ),
        ),
        
        // DIVIDER
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        
        // RIGHT PANE: Cart & Checkout (Fixed Width to prevent stretching)
        Container(
          width: 400,
          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
          child: Column(
            children: [
              // Cart Header
              Container(
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? Colors.black26 : Colors.white,
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Current Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Cart Items
              Expanded(
                child: _cartItems.isEmpty
                    ? _buildSmallEmptyCartHint(isDarkMode) // Small hint instead of giant button
                    : _buildCartList(currencySymbol, isDarkMode),
              ),
              // Checkout
              _buildCheckoutSection(currencySymbol, showProfit, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SEARCH SECTION ====================
  Widget _buildSearchSection(bool isDarkMode) {
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
          // Search Input
          Row(
            children: [
              Expanded(
                child: ProductAutocomplete(
                  focusNode: _searchFocusNode, // ✅ PASSED FOCUS NODE HERE
                  onProductSelected: (productName) {
                    _searchProduct(productName);
                  },
                  hintText: 'Search product by name...',
                ),
              ),
              const SizedBox(width: 8),
              // QR Scanner Button
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade900
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: isDarkMode
                        ? Colors.blue.shade400
                        : Colors.blue.shade700,
                  ),
                  onPressed: _showQRScanner,
                  tooltip: 'Scan QR Code',
                  iconSize: 24,
                ),
              ),
              const SizedBox(width: 4),
              // Barcode Scanner Button
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.green.shade900
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.barcode_reader,
                    color: isDarkMode
                        ? Colors.green.shade400
                        : Colors.green.shade700,
                  ),
                  onPressed: _showBarcodeScanner,
                  tooltip: 'Scan Barcode',
                  iconSize: 24,
                ),
              ),
              const SizedBox(width: 4),
              // Voice Input Button
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.orange.shade900
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: isDarkMode
                        ? Colors.orange.shade400
                        : Colors.orange.shade700,
                  ),
                  onPressed: _showVoiceInput,
                  tooltip: 'Voice Input',
                  iconSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category Quick Filters
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', null, isDarkMode),
                ...ProductReference.getCategories().map(
                  (category) =>
                      _buildCategoryChip(category, category, isDarkMode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        selected: false,
        onSelected: (selected) {
          // Category filtering can be implemented here
        },
        backgroundColor: isDarkMode
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        selectedColor: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  // ==================== CART LIST ====================
  Widget _buildCartList(String currencySymbol, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final product = _cartItems[index];
        final itemTotal = product.price * product.stock;

        return Dismissible(
          key: Key(product.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            setState(() {
              _cartItems.removeAt(index);
              _updateTotals();
            });
            _showSnackBar('${product.name} removed from cart');
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.red.shade400 : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: isDarkMode
                      ? Colors.blue.shade900
                      : Colors.blue.shade100,
                  child: Text(
                    product.stock.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.blue.shade400 : Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$currencySymbol${product.price.toStringAsFixed(2)} × ${product.stock}',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$currencySymbol${itemTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.green.shade400 : Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: isDarkMode
                                ? Colors.red.shade400
                                : Colors.red.shade300,
                          ),
                          onPressed: () {
                            setState(() {
                              if (product.stock > 1) {
                                _updateCartQuantity(product, -1);
                              } else {
                                _cartItems.removeAt(index);
                                _updateTotals();
                              }
                            });
                          },
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: isDarkMode
                                ? Colors.green.shade400
                                : Colors.green.shade300,
                          ),
                          onPressed: () {
                            setState(() {
                              _updateCartQuantity(product, 1);
                            });
                          },
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== EMPTY STATES ====================
  
  // Big prompt (Used on Mobile when empty, and Desktop Left Panel)
  Widget _buildEmptyCartPrompt(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Add Items to Order',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Add products using barcode, QR, voice, or search',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchFocusNode.requestFocus(); // ✅ Now this actually works!
              },
              icon: const Icon(Icons.search),
              label: const Text('Start Searching'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? Colors.blue.shade400
                    : Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small hint (Used on Desktop Right Panel when cart is empty)
  Widget _buildSmallEmptyCartHint(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 48, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CHECKOUT SECTION ====================
  Widget _buildCheckoutSection(
    String currencySymbol,
    bool showProfit,
    bool isDarkMode,
  ) {
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
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.green.shade400
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (showProfit) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Profit:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.blue.shade400
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade50,
                  ),
                  dropdownColor: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(
                        method,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _cartItems.isEmpty || _isLoading
                      ? null
                      : _processCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.green.shade400
                        : Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH LOGIC ====================
  void _searchProduct(String query) async {
    if (query.isEmpty) {
      _showSnackBar('Please enter a search term');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _firebaseService.getProductByBarcode(query),
        _firebaseService.getProductByQRCode(query),
      ]);

      if (results[0].docs.isNotEmpty) {
        _addProductToCart(results[0].docs.first);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (results[1].docs.isNotEmpty) {
        _addProductToCart(results[1].docs.first);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Search by name using FirebaseService
      try {
        final nameResult = await _firebaseService.getProductByName(query);
        if (nameResult.docs.isNotEmpty) {
          _showProductSelection(nameResult);
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        debugPrint('Name search failed: $e');
      }

      final suggestions = ProductReference.searchProducts(
        query: query,
        limit: 10,
      );

      if (suggestions.isNotEmpty) {
        _showSuggestionDialog(suggestions, query);
      } else {
        _showSnackBar('No product found. Try adding it to inventory first.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      debugPrint('Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuggestionDialog(List<String> suggestions, String query) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Product Suggestions',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No product found in inventory for "$query".',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Would you like to add one of these?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final productName = suggestions[index];
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDarkMode
                              ? Colors.blue.shade900
                              : Colors.blue.shade100,
                          child: Text(
                            productName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.blue.shade400
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          productName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: isDarkMode
                                ? Colors.green.shade400
                                : Colors.green,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddProductDialog(productName);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddProductDialog(productName);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(String productName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Product',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                productName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Cost Price',
                  prefixIcon: Icon(Icons.money_off),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (optional)',
                  prefixIcon: Icon(Icons.barcode_reader),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              priceController.dispose();
              costController.dispose();
              stockController.dispose();
              barcodeController.dispose();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              final cost = double.tryParse(costController.text);
              final stock = int.tryParse(stockController.text);

              if (price == null || cost == null || stock == null || stock < 0) {
                _showSnackBar('Please enter valid values');
                return;
              }

              priceController.dispose();
              costController.dispose();
              stockController.dispose();
              barcodeController.dispose();
              Navigator.pop(context);
              _createAndAddProduct(
                productName,
                price,
                cost,
                stock,
                barcodeController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? Colors.green.shade400
                  : Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _createAndAddProduct(
    String name,
    double price,
    double cost,
    int stock,
    String barcode,
  ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final product = Product(
        id: '',
        name: name,
        price: price,
        costPrice: cost,
        stock: stock,
        minStock: 0,
        createdAt: now,
        updatedAt: now,
        barcode: barcode.isNotEmpty ? barcode : '',
      );

      final docRef = await _firebaseService.addProduct(product.toMap());
      final newProduct = product.copyWith(id: docRef.id);

      if (mounted) {
        setState(() {
          _cartItems.add(newProduct.copyWith(stock: 1));
          _updateTotals();
        });
      }

      _showSnackBar('✅ ${newProduct.name} added to inventory and cart');
    } catch (e) {
      _showSnackBar('Error adding product: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addProductToCart(QueryDocumentSnapshot doc) {
    try {
      var data = doc.data() as Map<String, dynamic>;
      Product product = Product.fromMap(data, doc.id);

      var existingIndex = _cartItems.indexWhere(
        (item) => item.id == product.id,
      );

      setState(() {
        if (existingIndex != -1) {
          var existing = _cartItems[existingIndex];
          _cartItems[existingIndex] = existing.copyWith(
            stock: existing.stock + 1,
          );
        } else {
          _cartItems.add(product.copyWith(stock: 1));
        }
        _updateTotals();
      });

      _showSnackBar('${product.name} added to cart');
    } catch (e) {
      _showSnackBar('Error adding product: $e');
    }
  }

  void _updateCartQuantity(Product product, int change) {
    int index = _cartItems.indexOf(product);
    if (index != -1) {
      int newQuantity = product.stock + change;
      if (newQuantity > 0) {
        _cartItems[index] = product.copyWith(stock: newQuantity);
      } else {
        _cartItems.removeAt(index);
      }
      _updateTotals();
    }
  }

  void _updateTotals() {
    _totalAmount = _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.stock));
    _totalProfit = _cartItems.fold(0.0, (sum, item) => sum + ((item.price - item.costPrice) * item.stock));
  }

  Future<void> _showCustomerDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final nameController = TextEditingController(text: _customerName == 'Guest Customer' ? '' : _customerName);
    final phoneController = TextEditingController(text: _customerPhone);
    final emailController = TextEditingController(text: _customerEmail ?? '');
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Customer Info',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Customer Name',
                labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
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
            TextField(
              controller: emailController,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Email (optional)',
                labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _customerId = 'guest';
                _customerName = 'Guest Customer';
                _customerPhone = '';
                _customerEmail = null;
                _isGuestCustomer = true;
              });
              Navigator.pop(context);
              _showSnackBar('Set as Guest Customer');
            },
            child: Text(
              'Skip (Guest)',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customerId = 'customer_${DateTime.now().millisecondsSinceEpoch}';
                _customerName = nameController.text.trim().isNotEmpty 
                    ? nameController.text.trim() 
                    : 'Guest Customer';
                _customerPhone = phoneController.text.trim();
                _customerEmail = emailController.text.trim().isNotEmpty 
                    ? emailController.text.trim() 
                    : null;
                _isGuestCustomer = _customerName == 'Guest Customer';
              });
              Navigator.pop(context);
              _showSnackBar('Customer set: $_customerName');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  void _processCheckout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _showCustomerDialog();
      
      final productIds = _cartItems.map((item) => item.id).toList();
      final productDocs = await _firebaseService.getProductsByIds(productIds);
      
      for (var item in _cartItems) {
        final doc = productDocs[item.id];
        if (doc == null || !doc.exists) {
          _showSnackBar('❌ Product "${item.name}" not found in inventory');
          setState(() => _isLoading = false);
          return;
        }
        
        final data = doc.data() as Map<String, dynamic>;
        final availableStock = ((data['stock'] ?? 0) as num).toInt(); // ✅ Safe parsing
        
        if (availableStock < item.stock) {
          _showSnackBar(
            '❌ Insufficient stock for ${item.name}. Available: $availableStock'
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final confirm = await _showConfirmationDialog();
      if (!confirm) {
        setState(() => _isLoading = false);
        return;
      }

      final receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
      final receiptCartItems = List<Product>.from(_cartItems);
      final receiptTotalAmount = _totalAmount;
      final receiptTotalProfit = _totalProfit;
      final receiptPaymentMethod = _selectedPaymentMethod;

      final salesData = _cartItems.map((item) {
        return {
          'productId': item.id,
          'productName': item.name,
          'quantity': item.stock,
          'price': item.price,
          'costPrice': item.costPrice,
          'total': item.price * item.stock,
          'profit': (item.price - item.costPrice) * item.stock,
          'saleDate': DateTime.now(),
          'paymentMethod': _selectedPaymentMethod,
          'receiptNumber': receiptNumber,
          'customerId': _customerId,
          'customerName': _customerName,
          'customerPhone': _customerPhone,
          'customerEmail': _customerEmail,
          'customerAddress': _customerAddress,
          'isGuestCustomer': _isGuestCustomer,
        };
      }).toList();

      final stockUpdates = <String, int>{};
      for (var item in _cartItems) {
        stockUpdates[item.id] = -item.stock;
      }

      await Future.wait([
        _firebaseService.addMultipleSales(salesData),
        _firebaseService.updateMultipleProductsStock(stockUpdates),
      ]);

      setState(() {
        _cartItems.clear();
        _updateTotals();
        _isLoading = false;
        
        // Reset customer for next order
        _customerId = 'guest';
        _customerName = 'Guest Customer';
        _customerPhone = '';
        _customerEmail = null;
        _isGuestCustomer = true;
      });

      _showSnackBar('✅ Sale completed! Receipt #$receiptNumber');

      _showReceiptDialog(
        cartItems: receiptCartItems,
        totalAmount: receiptTotalAmount,
        totalProfit: receiptTotalProfit,
        paymentMethod: receiptPaymentMethod,
        receiptNumber: receiptNumber,
        customerName: _customerName,
        customerPhone: _customerPhone,
        customerEmail: _customerEmail,
        isGuestCustomer: _isGuestCustomer,
      );
      
    } catch (e) {
      _showSnackBar('❌ Checkout failed: $e');
      debugPrint('Checkout error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showReceiptDialog({
    required List<Product> cartItems,
    required double totalAmount,
    required double totalProfit,
    required String paymentMethod,
    required String receiptNumber,
    String customerName = 'Guest Customer',
    String customerPhone = '',
    String? customerEmail,
    bool isGuestCustomer = true,
  }) {
    showDialog(
      context: context,
      builder: (context) => ReceiptDialog(
        cartItems: cartItems,
        totalAmount: totalAmount,
        totalProfit: totalProfit,
        selectedPaymentMethod: paymentMethod,
        receiptNumber: receiptNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        isGuestCustomer: isGuestCustomer,
      ),
    );
  }

  void _showProductSelection(QuerySnapshot snapshot) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (snapshot.docs.isEmpty) {
      _showSnackBar('No products found in inventory');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Product',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.docs[index].data() as Map<String, dynamic>;
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
                    child: Text(
                      (data['stock'] ?? 0).toString(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    'Price: $currencySymbol${data['price']} | Stock: ${data['stock']}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: isDarkMode ? Colors.green.shade400 : Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _addProductToCart(snapshot.docs[index]);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addProductToCart(snapshot.docs[index]);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanner(
          onScan: (qrCode) => _searchProduct(qrCode),
        ),
      ),
    );
  }

  void _showBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanner(
          onScan: (barcode) => _searchProduct(barcode),
        ),
      ),
    );
  }

  void _showVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VoiceInput(
        onVoiceRecognized: (text) => _searchProduct(text),
      ),
    );
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cartItems.clear();
                _updateTotals();
              });
              _showSnackBar('Cart cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currencySymbol;
    final showProfit = settingsProvider.showProfitInPOS;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Checkout',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total items: ${_cartItems.length}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total amount: $currencySymbol${_totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.green.shade400 : Colors.green,
              ),
            ),
            if (showProfit) ...[
              const SizedBox(height: 4),
              Text(
                'Total profit: $currencySymbol${_totalProfit.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Divider(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Proceed with checkout?',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}