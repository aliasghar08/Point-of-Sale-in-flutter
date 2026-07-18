import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/widgets/qr_scanner.dart';
import 'package:pos/widgets/barcode_scanner.dart';
import 'package:pos/widgets/voice_input.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasLoaded = false;
  bool _isScanning = false;
  
  // Stream subscription for real-time updates
  Stream<QuerySnapshot>? _productsStream;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    _productsStream = _firebaseService.products.snapshots();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasLoaded = false;
    });
    try {
      await _firebaseService.products.get();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoaded = true;
        });
        _showSnackBar('Error loading products: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
     
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          _buildStatsSummary(isDarkMode),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _productsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        final errorMessage = snapshot.error?.toString() ?? 'Unknown error';
                        return _buildErrorState(errorMessage, isDarkMode);
                      }

                      if (snapshot.connectionState == ConnectionState.waiting && !_hasLoaded) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data == null) {
                        return _buildEmptyState(isDarkMode);
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(isDarkMode);
                      }

                      List<Product> products = snapshot.data!.docs.map((doc) {
                        return Product.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      }).toList();

                      List<Product> filteredProducts = _filterProducts(products);

                      if (filteredProducts.isEmpty) {
                        return _buildNoResultsState(isDarkMode);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(product, currencySymbol, isDarkMode);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: isDarkMode ? Colors.blue.shade500 : Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ==================== SEARCH BAR WITH QR, BARCODE & VOICE ====================
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
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
                              setState(() => _searchQuery = '');
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase().trim();
                    });
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _searchQuery = value.toLowerCase().trim();
                      });
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
                    color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  ),
                  onPressed: _scanQRCode,
                  tooltip: 'Scan QR Code',
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
                    color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                  ),
                  onPressed: _scanBarcode,
                  tooltip: 'Scan Barcode',
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
                    color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
                  ),
                  onPressed: _showVoiceInput,
                  tooltip: 'Voice Input',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== VOICE INPUT FUNCTIONALITY ====================
  
  void _showVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VoiceInput(
        onVoiceRecognized: (text) {
          setState(() {
            _searchQuery = text.toLowerCase().trim();
          });
          // If the voice input is a QR or barcode, try to find the product
          if (text.isNotEmpty) {
            _handleScanResult(text, 'Voice Input');
          }
        },
      ),
    );
  }

  // ==================== QR SCANNER FUNCTIONALITY ====================
  
  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanner(
          onScan: (qrCode) {
            _handleScanResult(qrCode, 'QR Code');
          },
        ),
      ),
    );
  }

  // ==================== BARCODE SCANNER FUNCTIONALITY ====================
  
  void _scanBarcode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanner(
          onScan: (barcode) {
            _handleScanResult(barcode, 'Barcode');
          },
        ),
      ),
    );
  }

  // ==================== HANDLE SCAN RESULTS ====================
  
  Future<void> _handleScanResult(String code, String scanType) async {
    if (_isScanning) return;
    
    setState(() => _isScanning = true);
    
    try {
      _showSnackBar('🔍 Searching for product...');
      
      // Search by QR code first
      QuerySnapshot qrResult = await _firebaseService
          .getProductByQRCode(code);
      
      if (qrResult.docs.isNotEmpty) {
        final data = qrResult.docs.first.data() as Map<String, dynamic>;
        final product = Product.fromMap(data, qrResult.docs.first.id);
        _showProductFoundDialog(product, scanType);
        return;
      }
      
      // If not found, search by barcode
      QuerySnapshot barcodeResult = await _firebaseService
          .getProductByBarcode(code);
      
      if (barcodeResult.docs.isNotEmpty) {
        final data = barcodeResult.docs.first.data() as Map<String, dynamic>;
        final product = Product.fromMap(data, barcodeResult.docs.first.id);
        _showProductFoundDialog(product, 'Barcode');
        return;
      }
      
      // If not found by barcode, search by name (for voice input)
      QuerySnapshot nameResult = await _firebaseService.products
          .where('name', isGreaterThanOrEqualTo: code)
          .where('name', isLessThanOrEqualTo: code + '\uf8ff')
          .limit(10)
          .get();
      
      if (nameResult.docs.isNotEmpty) {
        _showProductSelectionDialog(nameResult, scanType);
        return;
      }
      
      // Product not found
      _showProductNotFoundDialog(code);
      
    } catch (e) {
      _showSnackBar('❌ Error: $e', isError: true);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ==================== PRODUCT SELECTION DIALOG (For Voice Search) ====================
  
  void _showProductSelectionDialog(QuerySnapshot snapshot, String scanType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currencySymbol;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Product',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.docs[index].data() as Map<String, dynamic>;
              final product = Product.fromMap(data, snapshot.docs[index].id);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDarkMode
                      ? Colors.blue.shade900
                      : Colors.blue.shade100,
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
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Price: $currencySymbol${data['price']} | Stock: ${data['stock']}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.visibility,
                    color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showProductDetails(product, currencySymbol, isDarkMode);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showProductDetails(product, currencySymbol, isDarkMode);
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
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SCAN RESULT DIALOGS ====================
  
  void _showProductFoundDialog(Product product, String scanType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currencySymbol;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Product Found!',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanned via: $scanType',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const Divider(),
            _buildDetailRow('Name', product.name, isDarkMode),
            _buildDetailRow('Price', '$currencySymbol${product.price.toStringAsFixed(2)}', isDarkMode),
            _buildDetailRow('Stock', product.stock.toString(), isDarkMode),
            _buildDetailRow('Category', product.category, isDarkMode),
            if (product.barcode.isNotEmpty)
              _buildDetailRow('Barcode', product.barcode, isDarkMode),
            if (product.qrCode.isNotEmpty)
              _buildDetailRow('QR Code', product.qrCode, isDarkMode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditProductDialog(product);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductNotFoundDialog(String code) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Product Not Found',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No product found with this search:',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Would you like to add this product?',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddProductDialogWithCode(code);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialogWithCode(String code) {
    // Create a product with the code pre-filled (detect if it's QR or Barcode)
    final product = Product(
      id: '',
      name: '',
      price: 0,
      costPrice: 0,
      stock: 0,
      minStock: 0,
      category: 'Uncategorized',
      qrCode: code, // Pre-fill QR code
      barcode: '',  // Will be determined by the user
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _showProductDialog(
      title: 'Add Product',
      product: product,
      isEdit: false,
    );
  }

  // ==================== STATS SUMMARY ====================
  Widget _buildStatsSummary(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        int totalProducts = snapshot.data!.docs.length;
        int lowStockCount = 0;
        int totalStock = 0;

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          int stock = (data['stock'] ?? 0).toInt();
          int minStock = (data['minStock'] ?? 0).toInt();
          totalStock += stock;
          if (stock <= minStock) {
            lowStockCount++;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDarkMode
              ? Colors.grey.shade900
              : Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.inventory_2,
                label: 'Products',
                value: totalProducts.toString(),
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue,
                isDarkMode: isDarkMode,
              ),
              _buildStatItem(
                icon: Icons.shopping_bag,
                label: 'Total Stock',
                value: totalStock.toString(),
                color: isDarkMode ? Colors.green.shade400 : Colors.green,
                isDarkMode: isDarkMode,
              ),
              _buildStatItem(
                icon: Icons.warning_amber,
                label: 'Low Stock',
                value: lowStockCount.toString(),
                color: lowStockCount > 0
                    ? (isDarkMode ? Colors.red.shade400 : Colors.red)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== PRODUCT CARD ====================
  Widget _buildProductCard(Product product, String currencySymbol, bool isDarkMode) {
    bool isLowStock = product.stock <= product.minStock;
    bool isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOutOfStock
            ? BorderSide(color: isDarkMode ? Colors.red.shade400 : Colors.red.shade300, width: 1)
            : isLowStock
                ? BorderSide(color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade300, width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product, currencySymbol, isDarkMode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? (isDarkMode ? Colors.red.shade900 : Colors.red.shade100)
                      : isLowStock
                          ? (isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100)
                          : (isDarkMode ? Colors.green.shade900 : Colors.green.shade100),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    product.stock.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isOutOfStock
                          ? (isDarkMode ? Colors.red.shade400 : Colors.red)
                          : isLowStock
                              ? (isDarkMode ? Colors.orange.shade400 : Colors.orange)
                              : (isDarkMode ? Colors.green.shade400 : Colors.green),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$currencySymbol${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cost: $currencySymbol${product.costPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (product.barcode.isNotEmpty)
                      Text(
                        'Barcode: ${product.barcode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isOutOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.red.shade900 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: isDarkMode ? Colors.red.shade400 : Colors.red.shade900,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Low Stock',
                        style: TextStyle(
                          color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade900,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 20,
                          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                        ),
                        onPressed: () => _showEditProductDialog(product),
                        tooltip: 'Edit Product',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
                        ),
                        onPressed: () => _deleteProduct(product),
                        tooltip: 'Delete Product',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first product',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NO RESULTS STATE ====================
  Widget _buildNoResultsState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
            },
            child: Text(
              'Clear Search',
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(String errorMessage, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: isDarkMode ? Colors.red.shade400 : Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading products',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==================== FILTER PRODUCTS ====================
  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    
    return products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery) ||
          product.barcode.toLowerCase().contains(_searchQuery) ||
          product.qrCode.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery) ||
          product.price.toString().contains(_searchQuery);
    }).toList();
  }

  // ==================== FILTER OPTIONS ====================
  void _showFilterOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.inventory,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'All Products',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _searchQuery = '');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.warning,
                color: isDarkMode ? Colors.orange.shade400 : Colors.orange,
              ),
              title: Text(
                'Low Stock',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Low stock filter coming soon!');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.error,
                color: isDarkMode ? Colors.red.shade400 : Colors.red,
              ),
              title: Text(
                'Out of Stock',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Out of stock filter coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRODUCT DETAILS ====================
  void _showProductDetails(Product product, String currencySymbol, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDarkMode
                      ? Colors.blue.shade900
                      : Colors.blue.shade100,
                  child: Text(
                    product.stock.toString(),
                    style: TextStyle(
                      fontSize: 20,
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
                        product.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Category: ${product.category}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Price', '$currencySymbol${product.price.toStringAsFixed(2)}', isDarkMode),
            _buildDetailRow('Cost Price', '$currencySymbol${product.costPrice.toStringAsFixed(2)}', isDarkMode),
            _buildDetailRow('Profit', '$currencySymbol${(product.price - product.costPrice).toStringAsFixed(2)}', isDarkMode),
            _buildDetailRow('Stock', product.stock.toString(), isDarkMode),
            _buildDetailRow('Minimum Stock', product.minStock.toString(), isDarkMode),
            _buildDetailRow('Barcode', product.barcode.isNotEmpty ? product.barcode : 'N/A', isDarkMode),
            _buildDetailRow('QR Code', product.qrCode.isNotEmpty ? product.qrCode : 'N/A', isDarkMode),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditProductDialog(product);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteProduct(product);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
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
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ADD/EDIT PRODUCT DIALOG ====================
  void _showAddProductDialog() {
    _showProductDialog(
      title: 'Add Product',
      product: Product(
        id: '',
        name: '',
        price: 0,
        costPrice: 0,
        stock: 0,
        minStock: 0,
        category: 'Uncategorized',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      isEdit: false,
    );
  }

  void _showEditProductDialog(Product product) {
    _showProductDialog(
      title: 'Edit Product',
      product: product,
      isEdit: true,
    );
  }

  void _showProductDialog({
    required String title,
    required Product product,
    required bool isEdit,
  }) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toStringAsFixed(2),
    );
    final costController = TextEditingController(
      text: product.costPrice.toStringAsFixed(2),
    );
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final minStockController = TextEditingController(
      text: product.minStock.toString(),
    );
    final barcodeController = TextEditingController(text: product.barcode);
    final qrCodeController = TextEditingController(text: product.qrCode);
    final categoryController = TextEditingController(text: product.category);

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.add,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Product Name *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.production_quantity_limits,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Price *',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          border: const OutlineInputBorder(),
                          prefixText: '$currencySymbol ',
                          prefixIcon: Icon(
                            Icons.currency_exchange,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: costController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cost Price *',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          border: const OutlineInputBorder(),
                          prefixText: '$currencySymbol ',
                          prefixIcon: Icon(
                            Icons.currency_exchange,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Stock *',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.inventory,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: minStockController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Min Stock *',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.warning,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: barcodeController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.barcode_reader,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qrCodeController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'QR Code',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.category,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newProduct = product.copyWith(
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text),
                  costPrice: double.parse(costController.text),
                  stock: int.parse(stockController.text),
                  minStock: int.parse(minStockController.text),
                  barcode: barcodeController.text.trim(),
                  qrCode: qrCodeController.text.trim(),
                  category: categoryController.text.trim().isNotEmpty
                      ? categoryController.text.trim()
                      : 'Uncategorized',
                  updatedAt: DateTime.now(),
                );

                try {
                  if (isEdit) {
                    await _firebaseService.updateProduct(
                      product.id,
                      newProduct.toMap(),
                    );
                    if (mounted) _showSnackBar('✅ Product updated successfully!');
                  } else {
                    await _firebaseService.addProduct(newProduct.toMap());
                    if (mounted) _showSnackBar('✅ Product added successfully!');
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) _showSnackBar('❌ Error: $e', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  // ==================== DELETE PRODUCT ====================
  void _deleteProduct(Product product) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n\n'
          'This action cannot be undone.',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _firebaseService.deleteProduct(product.id);
        if (mounted) _showSnackBar('✅ Product deleted successfully!');
      } catch (e) {
        if (mounted) _showSnackBar('❌ Error deleting product: $e', isError: true);
      }
    }
  }

  // ==================== SNACKBAR ====================
  void _showSnackBar(String message, {bool isError = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isError
            ? (isDarkMode ? Colors.red.shade400 : Colors.red.shade700)
            : (isDarkMode ? Colors.green.shade400 : Colors.green.shade700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}