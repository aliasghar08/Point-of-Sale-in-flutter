import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/storage_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/viewmodels/inventory_view_model.dart';
import 'package:pos/viewmodels/pos_view_model.dart';

/// Health status of the calculated profit margin.
enum MarginHealth {
  healthy, // > 25%
  low, // 1% - 25%
  loss, // <= 0%
}

/// Dedicated, Reactive ViewModel for Adding & Editing Products in the Catalog.
/// Provides live financial margin calculations, validation, haptic barcode integration,
/// and optimistic multi-ViewModel state broadcasts.
class ProductFormViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();
  final StorageService _storageService = StorageService();

  // Basic Details
  String _name = '';
  String _sku = '';
  String _barcode = '';
  String _category = 'Groceries';
  String _unit = 'pcs';
  String _description = '';
  String _brand = '';

  // Pricing & Financials
  double _costPrice = 0.0;
  double _sellingPrice = 0.0;
  double? _wholesalePrice;
  double? _salePrice;

  // Inventory & Stock
  int _stockQuantity = 0;
  int _minStockAlert = 5;

  // Dates
  DateTime? _manufactureDate;
  DateTime? _expiryDate;

  // Media
  File? _imageFile;
  String? _imageUrl;

  // State
  bool _isSaving = false;
  String? _errorMessage;

  // Available Units
  static const List<Map<String, String>> unitPresets = [
    {'label': 'Piece (pcs)', 'value': 'pcs'},
    {'label': 'Kilogram (kg)', 'value': 'kg'},
    {'label': 'Liter (L)', 'value': 'liters'},
    {'label': 'Box (bx)', 'value': 'box'},
    {'label': 'Pack (pk)', 'value': 'pack'},
    {'label': 'Gram (g)', 'value': 'g'},
  ];

  // Default Categories
  List<String> _availableCategories = [
    'Groceries',
    'Bakery',
    'Beverages',
    'Snacks',
    'Personal Care',
    'Electronics',
    'General',
  ];

  // ===== GETTERS =====
  String get name => _name;
  String get sku => _sku;
  String get barcode => _barcode;
  String get category => _category;
  String get unit => _unit;
  String get description => _description;
  String get brand => _brand;

  double get costPrice => _costPrice;
  double get sellingPrice => _sellingPrice;
  double? get wholesalePrice => _wholesalePrice;
  double? get salePrice => _salePrice;

  int get stockQuantity => _stockQuantity;
  int get minStockAlert => _minStockAlert;

  DateTime? get manufactureDate => _manufactureDate;
  DateTime? get expiryDate => _expiryDate;

  File? get imageFile => _imageFile;
  String? get imageUrl => _imageUrl;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<String> get availableCategories => List.unmodifiable(_availableCategories);

  // ===== LIVE FINANCIAL MARGIN CALCULATOR =====

  /// Net gross profit per unit: Selling Price - Cost Price
  double get profit => _sellingPrice - _costPrice;

  /// Markup margin percentage on selling price.
  /// Guarded against zero cost price, negative selling price, or division-by-zero.
  double get marginPercentage {
    if (_sellingPrice <= 0 || _costPrice < 0) return 0.0;
    final margin = ((_sellingPrice - _costPrice) / _sellingPrice) * 100;
    if (margin.isNaN || margin.isInfinite) return 0.0;
    return margin;
  }

  /// Evaluates margin health status for dynamic UI feedback:
  /// - `healthy`: > 25% profit margin
  /// - `low`: 1% to 25% profit margin
  /// - `loss`: <= 0% margin (selling at cost or below cost)
  MarginHealth get marginHealth {
    if (profit <= 0 || marginPercentage <= 0) {
      return MarginHealth.loss;
    }
    if (marginPercentage > 25) {
      return MarginHealth.healthy;
    }
    return MarginHealth.low;
  }

  // ===== REACTIVE FORM VALIDATION =====

  /// Form is valid if product has a name, selling price > 0, and non-negative stock.
  bool get isValid =>
      _name.trim().isNotEmpty && _sellingPrice > 0 && _stockQuantity >= 0;

  // ===== INITIALIZATION & POPULATION =====

  /// Initialize state from an existing product when editing, or reset for new product.
  void initFromProduct(Product? product, {List<String>? initialCategories}) {
    if (initialCategories != null && initialCategories.isNotEmpty) {
      final merged = Set<String>.from(_availableCategories)..addAll(initialCategories);
      _availableCategories = merged.toList();
    }

    if (product != null) {
      _name = product.name;
      _sku = product.sku;
      _barcode = product.barcode;
      _category = product.category.isNotEmpty ? product.category : 'General';
      _unit = product.unit.isNotEmpty ? product.unit : 'pcs';
      _description = product.description;
      _brand = product.brand;
      _costPrice = product.costPrice;
      _sellingPrice = product.price;
      _wholesalePrice = product.wholesalePrice;
      _salePrice = product.salePrice;
      _stockQuantity = product.stock;
      _minStockAlert = product.minStock;
      _manufactureDate = product.manufactureDate;
      _expiryDate = product.expiryDate;
      _imageUrl = product.imageUrl;
      _imageFile = null;

      if (!_availableCategories.contains(_category)) {
        _availableCategories.add(_category);
      }
    } else {
      _name = '';
      _sku = '';
      _barcode = '';
      _category = _availableCategories.isNotEmpty ? _availableCategories.first : 'General';
      _unit = 'pcs';
      _description = '';
      _brand = '';
      _costPrice = 0.0;
      _sellingPrice = 0.0;
      _wholesalePrice = null;
      _salePrice = null;
      _stockQuantity = 0;
      _minStockAlert = 5;
      _manufactureDate = null;
      _expiryDate = null;
      _imageFile = null;
      _imageUrl = null;
    }
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ===== SETTERS / EVENT HANDLERS =====

  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  void setSku(String val) {
    _sku = val;
    notifyListeners();
  }

  void setBarcode(String val) {
    _barcode = val;
    notifyListeners();
  }

  void setCategory(String val) {
    if (_category == val) return;
    _category = val;
    FeedbackService.selection();
    notifyListeners();
  }

  void addCategory(String newCat) {
    final trimmed = newCat.trim();
    if (trimmed.isEmpty) return;
    if (!_availableCategories.contains(trimmed)) {
      _availableCategories.add(trimmed);
    }
    _category = trimmed;
    FeedbackService.success();
    notifyListeners();
  }

  void setUnit(String val) {
    if (_unit == val) return;
    _unit = val;
    FeedbackService.selection();
    notifyListeners();
  }

  void setDescription(String val) {
    _description = val;
    notifyListeners();
  }

  void setBrand(String val) {
    _brand = val;
    notifyListeners();
  }

  void setCostPrice(double val) {
    _costPrice = val < 0 ? 0 : val;
    notifyListeners();
  }

  void setSellingPrice(double val) {
    _sellingPrice = val < 0 ? 0 : val;
    notifyListeners();
  }

  void setWholesalePrice(double? val) {
    _wholesalePrice = val != null && val < 0 ? 0 : val;
    notifyListeners();
  }

  void setSalePrice(double? val) {
    _salePrice = val != null && val < 0 ? 0 : val;
    notifyListeners();
  }

  void setStockQuantity(int val) {
    _stockQuantity = val < 0 ? 0 : val;
    notifyListeners();
  }

  void incrementStock() {
    _stockQuantity += 1;
    FeedbackService.lightTap();
    notifyListeners();
  }

  void decrementStock() {
    if (_stockQuantity > 0) {
      _stockQuantity -= 1;
      FeedbackService.lightTap();
      notifyListeners();
    }
  }

  void setMinStockAlert(int val) {
    _minStockAlert = val < 0 ? 0 : val;
    notifyListeners();
  }

  void setManufactureDate(DateTime? dt) {
    _manufactureDate = dt;
    notifyListeners();
  }

  void setExpiryDate(DateTime? dt) {
    _expiryDate = dt;
    notifyListeners();
  }

  void setImageFile(File? file) {
    _imageFile = file;
    notifyListeners();
  }

  void clearImage() {
    _imageFile = null;
    _imageUrl = null;
    FeedbackService.lightTap();
    notifyListeners();
  }

  // ===== BARCODE SCANNER BRIDGE =====

  /// Auto-fills barcode and SKU (if SKU is empty) with haptic feedback.
  void onBarcodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    _barcode = trimmed;
    if (_sku.trim().isEmpty) {
      _sku = trimmed;
    }
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  // ===== PERSISTENCE PIPELINE =====

  /// Commits product to Firestore and optimistically broadcasts state to
  /// CacheService, InventoryViewModel, and PosViewModel without requiring manual pull.
  Future<bool> saveProduct({
    Product? existingProduct,
    required String businessId,
    InventoryViewModel? inventoryViewModel,
    PosViewModel? posViewModel,
  }) async {
    if (!isValid) {
      _errorMessage = 'Please provide product name and a valid selling price.';
      FeedbackService.error();
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final isEditing = existingProduct != null;

      // Deterministic or existing ID
      final productId = isEditing && existingProduct.id.isNotEmpty
          ? existingProduct.id
          : FirebaseFirestore.instance
              .collection('businesses')
              .doc(businessId)
              .collection('products')
              .doc()
              .id;

      // Handle image: upload to Firebase Cloud Storage under Blaze plan if new local image was selected
      String finalImageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        try {
          final uploadedUrl = await _storageService.uploadProductImage(
            businessId: businessId,
            productId: productId,
            file: _imageFile!,
          );
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            finalImageUrl = uploadedUrl;
          } else {
            finalImageUrl = _imageFile!.path;
          }
        } catch (e) {
          debugPrint('⚠️ Storage upload failed, falling back to local path: $e');
          finalImageUrl = _imageFile!.path;
        }
      }

      final product = Product(
        id: productId,
        name: _name.trim(),
        description: _description.trim(),
        brand: _brand.trim(),
        sku: _sku.trim().isNotEmpty ? _sku.trim() : productId.substring(0, 8).toUpperCase(),
        price: _sellingPrice,
        costPrice: _costPrice,
        salePrice: _salePrice,
        wholesalePrice: _wholesalePrice,
        stock: _stockQuantity,
        minStock: _minStockAlert,
        unit: _unit,
        barcode: _barcode.trim(),
        qrCode: _barcode.trim(),
        category: _category,
        imageUrl: finalImageUrl,
        manufactureDate: _manufactureDate,
        expiryDate: _expiryDate,
        createdAt: isEditing ? existingProduct.createdAt : now,
        updatedAt: now,
        isActive: true,
      );

      // 1. Optimistic Local Cache Update
      _cache.upsertProduct(product);

      // 2. Broadcast immediately to ViewModels
      inventoryViewModel?.optimisticAddOrUpdate(product);
      posViewModel?.optimisticAddOrUpdate(product);

      // 3. Commit to Firestore
      final productMap = product.toMap();
      if (isEditing) {
        await _firebaseService.updateProduct(product.id, productMap);
      } else {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .doc(productId)
            .set(productMap);
      }

      FeedbackService.success();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      FeedbackService.error();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
