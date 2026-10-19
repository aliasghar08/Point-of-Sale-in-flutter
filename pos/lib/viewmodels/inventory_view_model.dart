import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/sample_data_service.dart';
import 'package:pos/services/feedback_service.dart';

/// Clean, High-Performance ViewModel for Inventory Management.
/// Features reactive multi-tenant store scoping, real-time Firestore catalog streaming,
/// instant category and metric calculation, and optimistic UI updates.
class InventoryViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();

  StreamSubscription<QuerySnapshot>? _productsSubscription;
  String? _currentBusinessId;

  List<Product> _products = [];
  List<String> _categories = ['All'];
  bool _isLoading = false;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _stockFilter = 'all'; // 'all', 'low', 'out'
  bool _isGridView = false;
  bool _isSeeding = false;
  Timer? _debounceTimer;

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<Product> get filteredProducts => filterProducts(_products);
  List<String> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get currentBusinessId => _currentBusinessId;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get stockFilter => _stockFilter;
  bool get isGridView => _isGridView;
  bool get isSeeding => _isSeeding;

  // Computed Metrics
  int get totalSkus => _products.length;
  int get lowStockCount =>
      _products.where((p) => p.stock <= p.minStock && p.stock > 0).length;
  int get outOfStockCount => _products.where((p) => p.stock <= 0).length;
  double get stockValue =>
      _products.fold(0.0, (total, p) => total + (p.price * p.stock));

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }

  // ==================== REACTIVE MULTI-TENANT STORE SCOPING ====================

  /// Binds InventoryViewModel to the authenticated business session.
  /// Cancels prior subscriptions, attaches real-time Firestore stream,
  /// and reactively recalculates metrics on catalog changes.
  void initForStore(String? businessId) {
    if (businessId == null || businessId.isEmpty) {
      if (_currentBusinessId != null) {
        _productsSubscription?.cancel();
        _productsSubscription = null;
        _currentBusinessId = null;
        _products = [];
        _categories = ['All'];
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

          _products = items;
          _cache.setProducts(items);
          _recomputeCategories();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ InventoryViewModel Firestore stream error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error setting up inventory stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _recomputeCategories() {
    final catSet = <String>{'All'};
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) {
        catSet.add(p.category.trim());
      }
    }
    _categories = catSet.toList();
  }

  // ==================== OPTIMISTIC BROADCASTS ====================

  void optimisticAddOrUpdate(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
    _cache.upsertProduct(product);
    _recomputeCategories();
    notifyListeners();
  }

  void optimisticDelete(String productId) {
    _products.removeWhere((p) => p.id == productId);
    _cache.removeProduct(productId);
    _recomputeCategories();
    notifyListeners();
  }

  // ==================== UI ACTIONS ====================

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    FeedbackService.selection();
    notifyListeners();
  }

  void setStockFilter(String filter) {
    if (_stockFilter == filter) return;
    _stockFilter = filter;
    FeedbackService.selection();
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    FeedbackService.lightTap();
    notifyListeners();
  }

  Future<int> seedDemoProducts() async {
    _isSeeding = true;
    notifyListeners();
    try {
      final count = await SampleDataService.seedSampleProducts();
      FeedbackService.success();
      return count;
    } catch (e) {
      FeedbackService.error();
      rethrow;
    } finally {
      _isSeeding = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _firebaseService.deleteProduct(productId);
    optimisticDelete(productId);
    FeedbackService.lightTap();
  }

  List<Product> filterProducts(List<Product> items) {
    return items.where((p) {
      // 1. Category Filter
      if (_selectedCategory != 'All' && p.category != _selectedCategory) {
        return false;
      }

      // 2. Stock Filter
      if (_stockFilter == 'low' && (p.stock > p.minStock || p.stock == 0)) {
        return false;
      }
      if (_stockFilter == 'out' && p.stock > 0) {
        return false;
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesSku = p.sku.toLowerCase().contains(q);
        final matchesBarcode = p.barcode.toLowerCase().contains(q);
        return matchesName || matchesSku || matchesBarcode;
      }

      return true;
    }).toList();
  }
}
