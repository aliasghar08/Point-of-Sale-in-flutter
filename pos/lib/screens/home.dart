import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/cart_item.dart';
import 'package:pos/models/held_order.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/format_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/services/receipt_service.dart';
import 'package:pos/services/customer_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/stat_badge.dart';
import 'package:pos/widgets/category_pill.dart';
import 'package:pos/widgets/empty_state_view.dart';
import 'package:pos/widgets/qr_scanner.dart';
import 'package:pos/widgets/barcode_scanner.dart';
import 'package:pos/widgets/voice_input.dart';
import 'package:pos/widgets/customer_selection_dialog.dart';

/// Modern, High-Performance Point of Sale (POS) Cashier Register Screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();
  final CustomerService _customerService = CustomerService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  // POS State
  List<Product> _filteredProducts = [];
  final List<CartItem> _cart = [];
  final List<HeldOrder> _heldOrders = [];
  bool _isLoading = true;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Order Details
  Customer? _selectedCustomer;
  double _orderDiscountPercent = 0.0;
  double _orderDiscountAmount = 0.0;
  final double _taxRate = 0.0; // configurable or 0 by default

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      if (!force && _cache.hasValidProductCache) {
        // Cached products available
      } else {
        final products = await _firebaseService.getProducts();
        _cache.setProducts(products);
      }
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading catalog: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredProducts = _cache.searchProducts(
      _searchQuery,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _searchQuery = query;
      _applyFilters();
    });
  }

  // ==================== CART ACTIONS ====================

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      FeedbackService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is currently out of stock!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FeedbackService.selection();
    final index = _cart.indexWhere((item) => item.productId == product.id);

    setState(() {
      if (index >= 0) {
        if (_cart[index].quantity < product.stock) {
          _cart[index].quantity += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot add more. Max stock is ${product.stock}.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _cart.add(CartItem.fromProduct(product, quantity: 1));
      }
    });
  }

  void _incrementQty(int index) {
    final item = _cart[index];
    if (item.quantity < item.maxStock) {
      FeedbackService.lightTap();
      setState(() => item.quantity += 1);
    } else {
      FeedbackService.error();
    }
  }

  void _decrementQty(int index) {
    FeedbackService.lightTap();
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity -= 1;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _removeFromCart(int index) {
    FeedbackService.lightTap();
    setState(() => _cart.removeAt(index));
  }

  void _clearCart() {
    if (_cart.isEmpty) return;
    setState(() {
      _cart.clear();
      _selectedCustomer = null;
      _orderDiscountPercent = 0.0;
      _orderDiscountAmount = 0.0;
    });
    FeedbackService.selection();
  }

  // ==================== TOTALS CALCULATIONS ====================

  double get _cartSubtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _itemsDiscountTotal =>
      _cart.fold(0.0, (sum, item) => sum + item.calculatedDiscount);
  double get _orderDiscountTotal {
    if (_orderDiscountAmount > 0) return _orderDiscountAmount;
    if (_orderDiscountPercent > 0)
      return (_cartSubtotal - _itemsDiscountTotal) *
          (_orderDiscountPercent / 100);
    return 0.0;
  }

  double get _totalDiscount => _itemsDiscountTotal + _orderDiscountTotal;
  double get _totalTax => (_cartSubtotal - _totalDiscount) * (_taxRate / 100);
  double get _grandTotal =>
      (_cartSubtotal - _totalDiscount + _totalTax).clamp(0.0, double.infinity);
  double get _totalProfit => _cart.fold(0.0, (sum, item) => sum + item.profit);

  // ==================== PARK / HOLD SALE ====================

  void _parkActiveSale() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Nothing to hold.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hold / Park Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hold ${_cart.length} items for customer "${_selectedCustomer?.name ?? 'Guest'}"?',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Order Note / Reference (Optional)',
                hintText: 'e.g., Table 4, Waiting for wallet',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final heldOrder = HeldOrder(
                id: 'HELD-${DateTime.now().millisecondsSinceEpoch}',
                customerId: _selectedCustomer?.id ?? 'guest',
                customerName: _selectedCustomer?.name ?? 'Guest Customer',
                customerPhone: _selectedCustomer?.phone,
                items: List.from(_cart),
                heldAt: DateTime.now(),
                note: noteController.text.trim(),
                discountPercent: _orderDiscountPercent,
                discountAmount: _orderDiscountAmount,
              );

              setState(() {
                _heldOrders.add(heldOrder);
                _cart.clear();
                _selectedCustomer = null;
                _orderDiscountPercent = 0.0;
                _orderDiscountAmount = 0.0;
              });

              Navigator.pop(ctx);
              FeedbackService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order "${heldOrder.id}" parked successfully!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hold Order'),
          ),
        ],
      ),
    );
  }

  void _showHeldOrdersModal() {
    if (_heldOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No held orders found.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Held Orders (${_heldOrders.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _heldOrders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final order = _heldOrders[i];
                    return PosCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                FormatService.formatCurrency(
                                  order.totalAmount,
                                  symbol: currencySymbol,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.totalItems} items • Held ${FormatService.timeAgo(order.heldAt)}${order.note.isNotEmpty ? ' • "${order.note}"' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => _heldOrders.removeAt(i));
                                  setSheetState(() {});
                                  FeedbackService.lightTap();
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                label: const Text(
                                  'Discard',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_cart.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please clear or hold active cart before restoring.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _cart.addAll(order.items);
                                    _orderDiscountPercent =
                                        order.discountPercent;
                                    _orderDiscountAmount = order.discountAmount;
                                    _heldOrders.removeAt(i);
                                  });
                                  Navigator.pop(ctx);
                                  FeedbackService.success();
                                },
                                icon: const Icon(Icons.restore, size: 16),
                                label: const Text('Resume'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== QUICK CUSTOM ITEM ====================

  void _showQuickCustomItemModal() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom / Misc Item'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Item Name / Description',
                  hintText: 'e.g. Custom Repair, Service',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter item name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter price';
                  if (double.tryParse(v.trim()) == null)
                    return 'Enter valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final price = double.parse(priceCtrl.text.trim());
                final item = CartItem.custom(
                  name: nameCtrl.text.trim(),
                  price: price,
                );
                setState(() => _cart.add(item));
                Navigator.pop(ctx);
                FeedbackService.selection();
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  // ==================== CHECKOUT & PAYMENT MODAL ====================

  void _openCheckoutModal() {
    if (_cart.isEmpty) return;

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String selectedMethod = 'Cash';
    final cashController = TextEditingController(
      text: _grandTotal.toStringAsFixed(2),
    );
    double tenderedCash = _grandTotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final changeDue = (tenderedCash - _grandTotal).clamp(
            0.0,
            double.infinity,
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Complete Checkout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PosCard(
                    gradient: isDark
                        ? AppColors.darkCardGradient
                        : AppColors.primaryGradient,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount Due',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FormatService.formatCurrency(
                                _grandTotal,
                                symbol: currencySymbol,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_cart.length} Items',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method Selector
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Cash', 'Card', 'Mobile', 'Credit'].map((
                      method,
                    ) {
                      final isSelected = selectedMethod == method;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? (isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary)
                                  : null,
                              foregroundColor: isSelected ? Colors.white : null,
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary)
                                    : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              setModalState(() => selectedMethod = method);
                              FeedbackService.lightTap();
                            },
                            child: Text(
                              method,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Cash Denomination Helpers (When Cash is selected)
                  if (selectedMethod == 'Cash') ...[
                    const Text(
                      'Cash Tendered & Change',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cashController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Received Amount',
                        prefixText: '$currencySymbol ',
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          tenderedCash = double.tryParse(val) ?? _grandTotal;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTenderChip('Exact', _grandTotal, (amt) {
                          setModalState(() {
                            tenderedCash = amt;
                            cashController.text = amt.toStringAsFixed(2);
                          });
                        }),
                        ...[5, 10, 20, 50, 100, 500]
                            .where((d) => d >= _grandTotal)
                            .take(4)
                            .map(
                              (denom) => _buildTenderChip(
                                '$currencySymbol $denom',
                                denom.toDouble(),
                                (amt) {
                                  setModalState(() {
                                    tenderedCash = amt;
                                    cashController.text = amt.toStringAsFixed(
                                      2,
                                    );
                                  });
                                },
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PosCard(
                      backgroundColor: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change to Return:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            FormatService.formatCurrency(
                              changeDue,
                              symbol: currencySymbol,
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: changeDue > 0
                                  ? AppColors.success
                                  : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Process Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _processCompletedSale(
                        paymentMethod: selectedMethod,
                        cashTendered: selectedMethod == 'Cash'
                            ? tenderedCash
                            : _grandTotal,
                        changeDue: selectedMethod == 'Cash' ? changeDue : 0.0,
                        modalContext: ctx,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirm & Complete Sale',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTenderChip(
    String label,
    double amount,
    Function(double) onSelected,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      onPressed: () => onSelected(amount),
    );
  }

  // ==================== PROCESS SALE & SHOW RECEIPT ====================

  Future<void> _processCompletedSale({
    required String paymentMethod,
    required double cashTendered,
    required double changeDue,
    required BuildContext modalContext,
  }) async {
    Navigator.pop(modalContext);
    setState(() => _isLoading = true);

    try {
      final receiptNumber =
          'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final currencySymbol = settingsProvider.currencySymbol;

      // 1. Record Sale in Firebase
      await _firebaseService.processSale(
        cartItems: _cart
            .map(
              (c) => Product(
                id: c.productId,
                name: c.name,
                price: c.unitPrice,
                costPrice: c.costPrice,
                stock: c.quantity,
                minStock: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList(),
        paymentMethod: paymentMethod,
        totalAmount: _grandTotal,
        totalProfit: _totalProfit,
        receiptNumber: receiptNumber,
        customerId: _selectedCustomer?.id ?? 'guest',
        customerName: _selectedCustomer?.name ?? 'Guest Customer',
        customerPhone: _selectedCustomer?.phone ?? '',
        customerEmail: _selectedCustomer?.email,
        customerAddress: _selectedCustomer?.address,
        isGuestCustomer: _selectedCustomer == null,
      );

      // 2. Update Customer Lifetime Metrics
      if (_selectedCustomer != null) {
        await _customerService.recordSale(
          customerId: _selectedCustomer!.id,
          saleAmount: _grandTotal,
        );
      }

      // 3. Update Local Product Cache stock
      for (final cartItem in _cart) {
        final cached = _cache.getProductById(cartItem.productId);
        if (cached != null) {
          final updated = cached.copyWith(
            stock: (cached.stock - cartItem.quantity).clamp(0, 99999),
          );
          _cache.upsertProduct(updated);
        }
      }

      FeedbackService.success();
      final capturedCart = List<CartItem>.from(_cart);
      final customerName = _selectedCustomer?.name ?? 'Guest Customer';

      if (mounted) {
        setState(() {
          _cart.clear();
          _selectedCustomer = null;
          _orderDiscountPercent = 0.0;
          _orderDiscountAmount = 0.0;
          _isLoading = false;
          _applyFilters();
        });

        // Show Receipt Success Dialog
        _showReceiptSuccessDialog(
          receiptNumber: receiptNumber,
          items: capturedCart,
          subtotal: _cartSubtotal,
          discount: _totalDiscount,
          tax: _totalTax,
          grandTotal: _grandTotal,
          paymentMethod: paymentMethod,
          cashTendered: cashTendered,
          changeDue: changeDue,
          cashierName: authProvider.currentUser?.name ?? 'Cashier',
          customerName: customerName,
          currencySymbol: currencySymbol,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        FeedbackService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process sale: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showReceiptSuccessDialog({
    required String receiptNumber,
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required String paymentMethod,
    required double cashTendered,
    required double changeDue,
    required String cashierName,
    required String customerName,
    required String currencySymbol,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Sale Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt #: $receiptNumber',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Total Paid: ${FormatService.formatCurrency(grandTotal, symbol: currencySymbol)} ($paymentMethod)',
            ),
            if (changeDue > 0)
              Text(
                'Change Given: ${FormatService.formatCurrency(changeDue, symbol: currencySymbol)}',
              ),
            const SizedBox(height: 12),
            const Text(
              'Customer receipt is ready for thermal printing or digital delivery.',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final pdf = await ReceiptService.generatePdfReceipt(
                businessName: 'Point of Sale Retail',
                receiptNumber: receiptNumber,
                date: DateTime.now(),
                cashierName: cashierName,
                customerName: customerName,
                items: items
                    .map(
                      (i) => {
                        'name': i.name,
                        'qty': i.quantity,
                        'price': i.unitPrice,
                        'total': i.total,
                      },
                    )
                    .toList(),
                subtotal: subtotal,
                tax: tax,
                discount: discount,
                grandTotal: grandTotal,
                paymentMethod: paymentMethod,
                cashTendered: cashTendered,
                changeDue: changeDue,
                currencySymbol: currencySymbol,
              );
              await ReceiptService.printReceipt(pdf);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Receipt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Next Sale'),
          ),
        ],
      ),
    );
  }

  // ==================== SCANNER & VOICE SHORTCUTS ====================

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScanner(
          onScan: (code) {
            final p = _cache.getProductByBarcode(code);
            if (p != null) {
              _addToCart(p);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${p.name} to cart!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              _searchController.text = code;
              _onSearchChanged(code);
            }
          },
        ),
      ),
    );
  }

  void _showBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScanner(
          onScan: (code) {
            final p = _cache.getProductByBarcode(code);
            if (p != null) {
              _addToCart(p);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${p.name} to cart!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              _searchController.text = code;
              _onSearchChanged(code);
            }
          },
        ),
      ),
    );
  }

  void _showVoiceInput() {
    showModalBottomSheet(
      context: context,
      builder: (_) => VoiceInput(
        onVoiceRecognized: (text) {
          _searchController.text = text;
          _onSearchChanged(text);
        },
      ),
    );
  }

  void _selectCustomer() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CustomerSelectionDialog(),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = Customer(
          id: selected['id'] ?? 'guest',
          name: selected['name'] ?? selected['customerName'] ?? 'Customer',
          phone: selected['phone'] ?? selected['customerPhone'] ?? '',
          email: selected['email'] ?? selected['customerEmail'] ?? '',
          address: selected['address'] ?? selected['customerAddress'] ?? '',
          createdAt: DateTime.now(),
        );
      });
      FeedbackService.selection();
    }
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: isTablet
          ? Row(
              children: [
                // Left catalog pane (60% width)
                Expanded(
                  flex: 6,
                  child: _buildCatalogPane(currencySymbol, isDark),
                ),
                // Vertical divider
                VerticalDivider(
                  width: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                // Right cart pane (40% width)
                Expanded(
                  flex: 4,
                  child: _buildCartPane(currencySymbol, isDark),
                ),
              ],
            )
          : Column(
              children: [
                // Mobile Top Bar
                _buildSearchBar(isDark),
                _buildCategoryFilter(isDark),
                Expanded(child: _buildCatalogGrid(currencySymbol, isDark)),
                _buildMobileCartBottomBar(currencySymbol, isDark),
              ],
            ),
    );
  }

  // ==================== CATALOG PANE ====================

  Widget _buildCatalogPane(String currencySymbol, bool isDark) {
    return Column(
      children: [
        _buildSearchBar(isDark),
        _buildCategoryFilter(isDark),
        Expanded(child: _buildCatalogGrid(currencySymbol, isDark)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products by name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.barcode_reader),
            tooltip: 'Barcode Scanner',
            onPressed: _showBarcodeScanner,
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR Scanner',
            onPressed: _showQRScanner,
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Search',
            onPressed: _showVoiceInput,
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Custom Item',
            onPressed: _showQuickCustomItemModal,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    final categories = _cache.allCategories;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;
          return CategoryPill(
            title: cat,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategory = cat;
                _applyFilters();
              });
              FeedbackService.lightTap();
            },
          );
        },
      ),
    );
  }

  Widget _buildCatalogGrid(String currencySymbol, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: 'No products found',
        description: 'Try adjusting your search or category filter.',
        actionLabel: 'Add Custom Item',
        onAction: _showQuickCustomItemModal,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, i) {
        final product = _filteredProducts[i];
        final inStock = product.stock > 0;

        return PosCard(
          padding: const EdgeInsets.all(12),
          onTap: inStock ? () => _addToCart(product) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category & Stock Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatBadge.stock(
                    stock: product.stock,
                    minStock: product.minStock,
                  ),
                ],
              ),
              const Spacer(),
              // Icon Placeholder / Thumbnail
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryLight.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const Spacer(),
              // Product Name & Price
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    FormatService.formatCurrency(
                      product.salePrice ?? product.price,
                      symbol: currencySymbol,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.success : AppColors.primaryDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== CART PANE ====================

  Widget _buildCartPane(String currencySymbol, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          // Cart Header & Customer selector
          _buildCartHeader(isDark),
          const Divider(height: 1),

          // Items List
          Expanded(
            child: _cart.isEmpty
                ? const EmptyStateView(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart is Empty',
                    description:
                        'Select products from the catalog or scan a barcode to begin checkout.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _buildCartItemTile(_cart[i], i, currencySymbol, isDark),
                  ),
          ),

          // Order Totals & Pay Section
          if (_cart.isNotEmpty) _buildCartSummary(currencySymbol, isDark),
        ],
      ),
    );
  }

  Widget _buildCartHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Order Cart (${_cart.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_heldOrders.isNotEmpty)
                    Badge(
                      label: Text('${_heldOrders.length}'),
                      child: IconButton(
                        icon: const Icon(Icons.history_toggle_off),
                        tooltip: 'Held Orders',
                        onPressed: _showHeldOrdersModal,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.pause_circle_outline),
                    tooltip: 'Hold / Park Sale',
                    onPressed: _parkActiveSale,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.error,
                    ),
                    tooltip: 'Clear Cart',
                    onPressed: _clearCart,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer Selector Bar
          InkWell(
            onTap: _selectCustomer,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCustomer != null
                          ? '${_selectedCustomer!.name} (${_selectedCustomer!.phone.isNotEmpty ? _selectedCustomer!.phone : 'Customer'})'
                          : 'Guest Customer (Tap to attach customer)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedCustomer != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedCustomer != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _selectedCustomer = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(
    CartItem item,
    int index,
    String currencySymbol,
    bool isDark,
  ) {
    return PosCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  FormatService.formatCurrency(
                    item.unitPrice,
                    symbol: currencySymbol,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => _decrementQty(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => _incrementQty(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Item Total
          Text(
            FormatService.formatCurrency(item.total, symbol: currencySymbol),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.error),
            tooltip: 'Remove',
            onPressed: () => _removeFromCart(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(String currencySymbol, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                FormatService.formatCurrency(
                  _cartSubtotal,
                  symbol: currencySymbol,
                ),
              ),
            ],
          ),
          if (_totalDiscount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discounts',
                  style: TextStyle(color: AppColors.error),
                ),
                Text(
                  '-${FormatService.formatCurrency(_totalDiscount, symbol: currencySymbol)}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                FormatService.formatCurrency(
                  _grandTotal,
                  symbol: currencySymbol,
                ),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openCheckoutModal,
              icon: const Icon(Icons.payment, size: 20),
              label: const Text(
                'Charge & Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartBottomBar(String currencySymbol, bool isDark) {
    if (_cart.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_cart.length} items in cart',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  FormatService.formatCurrency(
                    _grandTotal,
                    symbol: currencySymbol,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: _buildCartPane(currencySymbol, isDark),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('View Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
