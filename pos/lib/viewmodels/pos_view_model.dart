import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/cart_item.dart';
import 'package:pos/models/held_order.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/customer_service.dart';
import 'package:pos/services/feedback_service.dart';

/// Clean, High-Performance ViewModel for Point of Sale Register.
/// Decouples UI rendering from business logic, calculations, and catalog search.
/// Provides smooth 60/120fps experience across iPhone, iPad (ProMotion), and Web.
class PosViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();
  final CustomerService _customerService = CustomerService();

  StreamSubscription<QuerySnapshot>? _productsSubscription;
  String? _currentBusinessId;

  // State
  List<Product> _filteredProducts = [];
  final List<CartItem> _cart = [];
  final List<HeldOrder> _heldOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Order Details
  Customer? _selectedCustomer;
  double _orderDiscountPercent = 0.0;
  double _orderDiscountAmount = 0.0;
  final double _taxRate = 0.0;

  // Getters
  List<Product> get filteredProducts => List.unmodifiable(_filteredProducts);
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<HeldOrder> get heldOrders => List.unmodifiable(_heldOrders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  Customer? get selectedCustomer => _selectedCustomer;

  double get orderDiscountPercent => _orderDiscountPercent;
  double get orderDiscountAmount => _orderDiscountAmount;
  double get taxRate => _taxRate;

  int get totalItemCount => _cart.fold(0, (total, item) => total + item.quantity);
  bool get isCartEmpty => _cart.isEmpty;

  // Financial calculations
  double get subtotal =>
      _cart.fold(0.0, (total, item) => total + (item.unitPrice * item.quantity));

  double get totalDiscount {
    double total = 0.0;
    for (final item in _cart) {
      total += item.discountAmount * item.quantity;
    }
    if (_orderDiscountPercent > 0) {
      total += (subtotal - total) * (_orderDiscountPercent / 100);
    }
    total += _orderDiscountAmount;
    return total.clamp(0.0, subtotal);
  }

  double get taxAmount => (subtotal - totalDiscount) * (_taxRate / 100);

  double get grandTotal => (subtotal - totalDiscount + taxAmount).clamp(0.0, double.infinity);

  double get totalProfit {
    double profit = 0.0;
    for (final item in _cart) {
      final revenue = (item.unitPrice - item.discountAmount) * item.quantity;
      final cost = item.costPrice * item.quantity;
      profit += (revenue - cost);
    }
    profit -= _orderDiscountAmount;
    if (_orderDiscountPercent > 0) {
      profit -= (subtotal * (_orderDiscountPercent / 100));
    }
    return profit;
  }

  List<String> get categories => _cache.allCategories;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }

  // ==================== REACTIVE MULTI-TENANT STORE SCOPING ====================

  /// Binds PosViewModel to the authenticated business session.
  /// Cancels prior subscriptions, attaches real-time Firestore stream,
  /// updates cache and filters reactively on changes.
  void initForStore(String? businessId) {
    if (businessId == null || businessId.isEmpty) {
      if (_currentBusinessId != null) {
        _productsSubscription?.cancel();
        _productsSubscription = null;
        _currentBusinessId = null;
        _filteredProducts = [];
        notifyListeners();
      }
      return;
    }

    if (_currentBusinessId == businessId && _productsSubscription != null) {
      return;
    }

    _productsSubscription?.cancel();
    _currentBusinessId = businessId;
    _isLoading = true;
    notifyListeners();

    try {
      final collection = FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      _productsSubscription = collection.snapshots().listen(
        (snapshot) {
          final items = snapshot.docs.map((doc) {
            return Product.fromMap(
              doc.data(),
              doc.id,
            );
          }).toList();

          _cache.setProducts(items);
          _applyFilters();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ PosViewModel Firestore stream error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error setting up PosViewModel stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void optimisticAddOrUpdate(Product product) {
    _cache.upsertProduct(product);
    _applyFilters();
    notifyListeners();
  }

  // ==================== CATALOG METHODS ====================

  Future<void> loadCatalog({bool force = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!force && _cache.hasValidProductCache) {
        // Fast in-memory cache hit
      } else {
        final products = await _firebaseService.getProducts();
        _cache.setProducts(products);
      }
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading catalog: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredProducts = _cache.searchProducts(
      _searchQuery,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    FeedbackService.selection();
    _applyFilters();
    notifyListeners();
  }

  // ==================== CART ACTIONS ====================

  String? addToCart(Product product) {
    if (product.stock <= 0) {
      FeedbackService.error();
      return '${product.name} is out of stock!';
    }

    FeedbackService.selection();
    final index = _cart.indexWhere((item) => item.productId == product.id);

    if (index >= 0) {
      if (_cart[index].quantity < product.stock) {
        _cart[index].quantity += 1;
      } else {
        FeedbackService.error();
        return 'Cannot add more. Max stock is ${product.stock}.';
      }
    } else {
      _cart.add(CartItem.fromProduct(product, quantity: 1));
    }

    notifyListeners();
    return null;
  }

  void addCustomItem({required String name, required double price}) {
    final item = CartItem.custom(name: name, price: price);
    _cart.add(item);
    FeedbackService.selection();
    notifyListeners();
  }

  void incrementQty(int index) {
    if (index < 0 || index >= _cart.length) return;
    final item = _cart[index];
    if (item.quantity < item.maxStock) {
      FeedbackService.lightTap();
      item.quantity += 1;
      notifyListeners();
    } else {
      FeedbackService.error();
    }
  }

  void decrementQty(int index) {
    if (index < 0 || index >= _cart.length) return;
    FeedbackService.lightTap();
    if (_cart[index].quantity > 1) {
      _cart[index].quantity -= 1;
    } else {
      _cart.removeAt(index);
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= _cart.length) return;
    FeedbackService.lightTap();
    _cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    FeedbackService.lightTap();
    _cart.clear();
    _selectedCustomer = null;
    _orderDiscountPercent = 0.0;
    _orderDiscountAmount = 0.0;
    notifyListeners();
  }

  void applyItemDiscount(int index, {required double discount, required bool isPercent}) {
    if (index < 0 || index >= _cart.length) return;
    final item = _cart[index];
    if (isPercent) {
      item.discountPercent = discount;
      item.discountAmount = item.unitPrice * (discount / 100);
    } else {
      item.discountAmount = discount;
      item.discountPercent = (discount / item.unitPrice) * 100;
    }
    FeedbackService.lightTap();
    notifyListeners();
  }

  void applyOrderDiscount({required double discount, required bool isPercent}) {
    if (isPercent) {
      _orderDiscountPercent = discount;
      _orderDiscountAmount = 0.0;
    } else {
      _orderDiscountAmount = discount;
      _orderDiscountPercent = 0.0;
    }
    FeedbackService.lightTap();
    notifyListeners();
  }

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    FeedbackService.selection();
    notifyListeners();
  }

  // ==================== HELD / PARKED ORDERS ====================

  HeldOrder? parkOrder({String? note}) {
    if (_cart.isEmpty) return null;

    final heldOrder = HeldOrder(
      id: 'HELD-${DateTime.now().millisecondsSinceEpoch}',
      customerId: _selectedCustomer?.id ?? 'guest',
      customerName: _selectedCustomer?.name ?? 'Guest Customer',
      customerPhone: _selectedCustomer?.phone,
      items: List.from(_cart),
      heldAt: DateTime.now(),
      note: note ?? '',
      discountPercent: _orderDiscountPercent,
      discountAmount: _orderDiscountAmount,
    );

    _heldOrders.add(heldOrder);
    _cart.clear();
    _selectedCustomer = null;
    _orderDiscountPercent = 0.0;
    _orderDiscountAmount = 0.0;

    FeedbackService.success();
    notifyListeners();
    return heldOrder;
  }

  bool resumeHeldOrder(HeldOrder order) {
    if (_cart.isNotEmpty) return false;

    _cart.addAll(order.items);
    _orderDiscountPercent = order.discountPercent;
    _orderDiscountAmount = order.discountAmount;
    _heldOrders.remove(order);

    FeedbackService.success();
    notifyListeners();
    return true;
  }

  void discardHeldOrder(HeldOrder order) {
    _heldOrders.remove(order);
    FeedbackService.lightTap();
    notifyListeners();
  }

  // ==================== CHECKOUT ORCHESTRATION ====================

  Future<String> completeCheckout({
    required String paymentMethod,
    required double cashTendered,
    required double changeDue,
  }) async {
    final receiptNumber =
        'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // 1. Process Sale in Firebase
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
      totalAmount: grandTotal,
      totalProfit: totalProfit,
      receiptNumber: receiptNumber,
      customerId: _selectedCustomer?.id ?? 'guest',
      customerName: _selectedCustomer?.name ?? 'Guest Customer',
      customerPhone: _selectedCustomer?.phone ?? '',
      customerEmail: _selectedCustomer?.email,
      customerAddress: _selectedCustomer?.address,
      isGuestCustomer: _selectedCustomer == null,
    );

    // 2. Customer metrics
    if (_selectedCustomer != null) {
      await _customerService.recordSale(
        customerId: _selectedCustomer!.id,
        saleAmount: grandTotal,
      );
    }

    // 3. Update cache stock
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
    return receiptNumber;
  }
}
