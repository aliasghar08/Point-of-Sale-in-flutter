import 'package:flutter/foundation.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/customer.dart';

/// In-memory high-speed cache and search index for products, customers, and app data.
/// Vastly improves POS performance, search latency, and eliminates redundant Firestore reads.
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Products Cache
  final Map<String, Product> _productById = {};
  final Map<String, Product> _productByBarcode = {};
  final Map<String, Product> _productBySku = {};
  final Map<String, List<Product>> _productsByCategory = {};
  List<Product> _allProducts = [];
  DateTime? _productsLastFetched;

  // Customers Cache
  final Map<String, Customer> _customerById = {};
  List<Customer> _allCustomers = [];
  DateTime? _customersLastFetched;

  // Categories Cache
  final Set<String> _categories = {};

  // Cache TTL duration
  static const Duration defaultTtl = Duration(minutes: 10);

  // ==================== PRODUCT CACHE METHODS ====================

  bool get hasValidProductCache {
    if (_productsLastFetched == null || _allProducts.isEmpty) return false;
    return DateTime.now().difference(_productsLastFetched!) < defaultTtl;
  }

  List<Product> get allProducts => List.unmodifiable(_allProducts);
  List<String> get allCategories => ['All', ..._categories.toList()..sort()];

  void setProducts(List<Product> products) {
    _productById.clear();
    _productByBarcode.clear();
    _productBySku.clear();
    _productsByCategory.clear();
    _categories.clear();
    _allProducts = List.from(products);

    for (final p in products) {
      _productById[p.id] = p;
      if (p.barcode.isNotEmpty) _productByBarcode[p.barcode.trim()] = p;
      if (p.sku.isNotEmpty) _productBySku[p.sku.trim().toLowerCase()] = p;
      
      final cat = p.category.trim().isEmpty ? 'Uncategorized' : p.category.trim();
      _categories.add(cat);
      _productsByCategory.putIfAbsent(cat, () => []).add(p);
    }

    _productsLastFetched = DateTime.now();
    debugPrint('⚡ CacheService: Cached ${_allProducts.length} products');
  }

  void upsertProduct(Product product) {
    _productById[product.id] = product;
    if (product.barcode.isNotEmpty) _productByBarcode[product.barcode.trim()] = product;
    if (product.sku.isNotEmpty) _productBySku[product.sku.trim().toLowerCase()] = product;

    final index = _allProducts.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _allProducts[index] = product;
    } else {
      _allProducts.add(product);
    }

    final cat = product.category.trim().isEmpty ? 'Uncategorized' : product.category.trim();
    _categories.add(cat);
  }

  void removeProduct(String productId) {
    final p = _productById.remove(productId);
    if (p != null) {
      _productByBarcode.remove(p.barcode);
      _productBySku.remove(p.sku.toLowerCase());
      _allProducts.removeWhere((item) => item.id == productId);
    }
  }

  Product? getProductById(String id) => _productById[id];
  Product? getProductByBarcode(String barcode) => _productByBarcode[barcode.trim()];
  Product? getProductBySku(String sku) => _productBySku[sku.trim().toLowerCase()];

  List<Product> searchProducts(String query, {String? category}) {
    List<Product> baseList = _allProducts;

    if (category != null && category != 'All' && category.isNotEmpty) {
      baseList = _productsByCategory[category] ?? [];
    }

    if (query.trim().isEmpty) return baseList;

    final q = query.trim().toLowerCase();
    return baseList.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q);
    }).toList();
  }

  // ==================== CUSTOMER CACHE METHODS ====================

  bool get hasValidCustomerCache {
    if (_customersLastFetched == null || _allCustomers.isEmpty) return false;
    return DateTime.now().difference(_customersLastFetched!) < defaultTtl;
  }

  List<Customer> get allCustomers => List.unmodifiable(_allCustomers);

  void setCustomers(List<Customer> customers) {
    _customerById.clear();
    _allCustomers = List.from(customers);
    for (final c in customers) {
      _customerById[c.id] = c;
    }
    _customersLastFetched = DateTime.now();
  }

  void upsertCustomer(Customer customer) {
    _customerById[customer.id] = customer;
    final index = _allCustomers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _allCustomers[index] = customer;
    } else {
      _allCustomers.add(customer);
    }
  }

  Customer? getCustomerById(String id) => _customerById[id];

  List<Customer> searchCustomers(String query) {
    if (query.trim().isEmpty) return _allCustomers;
    final q = query.trim().toLowerCase();
    return _allCustomers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();
  }

  void invalidateAll() {
    _productById.clear();
    _productByBarcode.clear();
    _productBySku.clear();
    _productsByCategory.clear();
    _categories.clear();
    _allProducts.clear();
    _productsLastFetched = null;

    _customerById.clear();
    _allCustomers.clear();
    _customersLastFetched = null;
  }
}
