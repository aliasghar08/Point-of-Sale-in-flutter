import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pos/screens/inventory_screen.dart';
import 'package:pos/screens/user_management_screen.dart';
import 'package:pos/widgets/barcode_scanner.dart';
import 'package:pos/widgets/drawer.dart';
import 'package:pos/widgets/qr_scanner.dart';
import 'package:pos/widgets/voice_input.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/settings_provider.dart';
import 'package:intl/intl.dart';

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
  bool _isSearching = false;

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

    return Scaffold(
      // home.dart
      drawer: AppDrawer(
        currentIndex: 0,
        onItemSelected: (index) {
          // Close the drawer first
          Navigator.pop(context);

          // Navigate based on the selected index
          switch (index) {
            case 0:
              // Already on Home (POS) - do nothing
              break;

            case 1:
              // Navigate to Inventory
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(),
                ),
              );
              break;

            case 2:
              // Navigate to User Management
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
              break;

            default:
              break;
          }
        },
      ),
      appBar: AppBar(
        title: const Text('Point of Sale'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showSalesHistory();
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              if (_cartItems.isNotEmpty) {
                _showReceiptDialog();
              } else {
                _showSnackBar('Cart is empty');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Input Section
          _buildSearchSection(),

          // Cart Items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(currencySymbol),
          ),

          // Summary and Checkout
          _buildCheckoutSection(currencySymbol, showProfit),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search product by name, barcode, or QR',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade50
                        : Colors.grey.shade800,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _searchProduct(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.qr_code_scanner,
                color: Colors.blue,
                onPressed: _showQRScanner,
              ),
              _buildActionButton(
                icon: Icons.barcode_reader,
                color: Colors.green,
                onPressed: _showBarcodeScanner,
              ),
              _buildActionButton(
                icon: Icons.mic,
                color: Colors.orange,
                onPressed: _showVoiceInput,
              ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        iconSize: 28,
        tooltip: _getTooltip(icon),
      ),
    );
  }

  String _getTooltip(IconData icon) {
    switch (icon) {
      case Icons.qr_code_scanner:
        return 'Scan QR Code';
      case Icons.barcode_reader:
        return 'Scan Barcode';
      case Icons.mic:
        return 'Voice Input';
      default:
        return '';
    }
  }

  Widget _buildCartList(String currencySymbol) {
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
              color: Colors.red,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  product.stock.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$currencySymbol${product.price.toStringAsFixed(2)} × ${product.stock}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$currencySymbol${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
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
                        color: Colors.red.shade300,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            _updateCartQuantity(product, 1);
                          });
                        },
                        iconSize: 20,
                        color: Colors.green.shade300,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Cart is Empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Add products using barcode, QR, voice, or search',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchFocusNode.requestFocus();
              },
              icon: const Icon(Icons.search),
              label: const Text('Start Searching'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
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

  Widget _buildCheckoutSection(String currencySymbol, bool showProfit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (showProfit) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Profit:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
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
                    fillColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade50
                        : Colors.grey.shade800,
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem(value: method, child: Text(method));
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
                    backgroundColor: Colors.green.shade700,
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

  // Helper Methods
  void _searchProduct(String query) async {
    if (query.isEmpty) {
      _showSnackBar('Please enter a search term');
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // Search by barcode or QR code first
      QuerySnapshot barcodeResult = await _firebaseService.getProductByBarcode(
        query,
      );

      if (barcodeResult.docs.isNotEmpty) {
        _addProductToCart(barcodeResult.docs.first);
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        QuerySnapshot qrResult = await _firebaseService.getProductByQRCode(
          query,
        );

        if (qrResult.docs.isNotEmpty) {
          _addProductToCart(qrResult.docs.first);
          _searchController.clear();
          _searchFocusNode.unfocus();
        } else {
          // Search by name
          QuerySnapshot nameResult = await _firebaseService.products
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: query + '\uf8ff')
              .limit(20)
              .get();

          if (nameResult.docs.isNotEmpty) {
            _showProductSelection(nameResult);
          } else {
            _showSnackBar('No product found');
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      print('Search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  void _addProductToCart(QueryDocumentSnapshot doc) {
    try {
      var data = doc.data() as Map<String, dynamic>;
      Product product = Product.fromMap(data, doc.id);

      // Check if product already in cart
      var existingIndex = _cartItems.indexWhere(
        (item) => item.id == product.id,
      );

      setState(() {
        if (existingIndex != -1) {
          // Update quantity
          var existing = _cartItems[existingIndex];
          _cartItems[existingIndex] = existing.copyWith(
            stock: existing.stock + 1,
          );
        } else {
          // Add new item with quantity 1
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

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _updateTotals();
    });
  }

  void _updateTotals() {
    _totalAmount = 0;
    _totalProfit = 0;

    for (var item in _cartItems) {
      _totalAmount += item.price * item.stock;
      _totalProfit += (item.price - item.costPrice) * item.stock;
    }
  }

  void _processCheckout() async {
    if (_cartItems.isEmpty) return;

    // Check stock availability
    for (var item in _cartItems) {
      try {
        // Check current stock from database
        DocumentSnapshot doc = await _firebaseService.products
            .doc(item.id)
            .get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          int availableStock = (data['stock'] ?? 0).toInt();

          if (availableStock < item.stock) {
            _showSnackBar(
              'Insufficient stock for ${item.name}. Available: $availableStock',
            );
            return;
          }
        }
      } catch (e) {
        _showSnackBar('Error checking stock: $e');
        return;
      }
    }

    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      String receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
      String receiptDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      for (var item in _cartItems) {
        Sale sale = Sale(
          id: '',
          productId: item.id,
          productName: item.name,
          quantity: item.stock,
          price: item.price,
          costPrice: item.costPrice,
          total: item.price * item.stock,
          profit: (item.price - item.costPrice) * item.stock,
          saleDate: DateTime.now(),
          paymentMethod: _selectedPaymentMethod,
          receiptNumber: receiptNumber,
        );

        await _firebaseService.addSale(sale.toMap());
      }

      // Clear cart
      setState(() {
        _cartItems.clear();
        _updateTotals();
      });

      _showSnackBar('✅ Sale completed! Receipt #$receiptNumber');
      _showReceiptDialog(receiptNumber: receiptNumber);
    } catch (e) {
      _showSnackBar('❌ Checkout failed: $e');
      print('Checkout error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showProductSelection(QuerySnapshot snapshot) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final currencySymbol = settingsProvider.currencySymbol;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Product'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (data['stock'] ?? 0).toString(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(data['name'] ?? ''),
                subtitle: Text(
                  'Price: $currencySymbol${data['price']} | Stock: ${data['stock']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _addProductToCart(snapshot.docs[index]);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addProductToCart(snapshot.docs[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          onScan: (qrCode) {
            _searchProduct(qrCode);
          },
        ),
      ),
    );
  }

  void _showBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanner(
          onScan: (barcode) {
            _searchProduct(barcode);
          },
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
        onVoiceRecognized: (text) {
          _searchController.text = text;
          _searchProduct(text);
        },
      ),
    );
  }

  void _showReceiptDialog({String? receiptNumber}) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final currencySymbol = settingsProvider.currencySymbol;
    final showProfit = settingsProvider.showProfitInPOS;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Receipt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt #: ${receiptNumber ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ..._cartItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} × ${item.stock}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '$currencySymbol${(item.price * item.stock).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (showProfit) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profit:',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (_selectedPaymentMethod.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment:',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    _selectedPaymentMethod,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement print functionality
              _showSnackBar('Printing feature coming soon!');
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalesHistory() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final currencySymbol = settingsProvider.currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Text(
              'Sales History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.sales
                    .orderBy('saleDate', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No sales yet'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              (data['quantity'] ?? 0).toString(),
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(data['productName'] ?? ''),
                          subtitle: Text(
                            'Receipt: ${data['receiptNumber']}\n'
                            'Payment: ${data['paymentMethod']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$currencySymbol${(data['total'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Profit: $currencySymbol${(data['profit'] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final currencySymbol = settingsProvider.currencySymbol;
    final showProfit = settingsProvider.showProfitInPOS;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Checkout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total items: ${_cartItems.length}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total amount: $currencySymbol${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (showProfit) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total profit: $currencySymbol${_totalProfit.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Proceed with checkout?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
