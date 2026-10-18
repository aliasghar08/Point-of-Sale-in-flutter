import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/sample_data_service.dart';
import 'package:pos/services/feedback_service.dart';

/// Clean, High-Performance ViewModel for Inventory Management.
/// Optimized for large catalogs, smooth 60/120fps scrolling on iPhone and iPad.
class InventoryViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _stockFilter = 'all'; // 'all', 'low', 'out'
  bool _isGridView = false;
  bool _isSeeding = false;
  Timer? _debounceTimer;

  // Getters
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get stockFilter => _stockFilter;
  bool get isGridView => _isGridView;
  bool get isSeeding => _isSeeding;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

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
    _cache.removeProduct(productId);
    FeedbackService.lightTap();
    notifyListeners();
  }

  List<Product> filterProducts(List<Product> products) {
    return products.where((p) {
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
