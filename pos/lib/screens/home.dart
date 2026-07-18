import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pos/widgets/barcode_scanner.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildSearchSection(isDarkMode),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
                ? _buildEmptyCart(isDarkMode)
                : _buildCartList(currencySymbol, isDarkMode),
          ),
          _buildCheckoutSection(currencySymbol, showProfit, isDarkMode),
        ],
      ),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search product by name, barcode, or QR',
                    hintStyle: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
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
                    fillColor: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade50,
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
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
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
        );
      },
    );
  }

  // ==================== EMPTY CART ====================
  Widget _buildEmptyCart(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
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
              'Cart is Empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                _searchFocusNode.requestFocus();
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

  // ==================== HELPER METHODS ====================
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

    for (var item in _cartItems) {
      try {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDarkMode
                      ? Colors.blue.shade900
                      : Colors.blue.shade100,
                  child: Text(
                    (data['stock'] ?? 0).toString(),
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  data['name'] ?? '',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Price: $currencySymbol${data['price']} | Stock: ${data['stock']}',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              'Receipt',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt #: ${receiptNumber ?? 'N/A'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '$currencySymbol${(item.price * item.stock).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black,
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
                Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.green.shade400 : Colors.green,
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
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
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
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _selectedPaymentMethod,
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _showSnackBar('Printing feature coming soon!');
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? Colors.blue.shade400
                  : Colors.blue.shade700,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Text(
              'Sales History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Divider(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.sales
                    .orderBy('saleDate', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No sales yet',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      return Card(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDarkMode
                                ? Colors.green.shade900
                                : Colors.green.shade100,
                            child: Text(
                              (data['quantity'] ?? 0).toString(),
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.green.shade400
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            data['productName'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            'Receipt: ${data['receiptNumber']}\n'
                            'Payment: ${data['paymentMethod']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                                '$currencySymbol${(data['total'] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.green.shade400
                                      : Colors.green,
                                ),
                              ),
                              Text(
                                'Profit: $currencySymbol${(data['profit'] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.blue.shade400
                                      : Colors.blue.shade700,
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
                      color: isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Divider(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
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
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.green.shade400
                      : Colors.green.shade700,
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