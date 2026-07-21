import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Helper to get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // ✅ Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  // ✅ Products Collection - Under User's Sub-collection
  CollectionReference get products {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated. Please login first.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('products');
  }
  
  // ✅ Sales Collection - Under User's Sub-collection
  CollectionReference get sales {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated. Please login first.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sales');
  }

  // ✅ Add Product - Now stores under user's sub-collection
  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      // ✅ Add user ID and timestamps
      productData['userId'] = _currentUserId;
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();
      
      DocumentReference docRef = await products.add(productData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // ✅ Update Product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      data['updatedAt'] = FieldValue.serverTimestamp();
      await products.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // ✅ Delete Product
  Future<void> deleteProduct(String id) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      await products.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ✅ Get Product by Barcode (within user's products)
  Future<QuerySnapshot> getProductByBarcode(String barcode) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      return await products.where('barcode', isEqualTo: barcode).limit(1).get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // ✅ Get Product by QR Code (within user's products)
  Future<QuerySnapshot> getProductByQRCode(String qrCode) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      return await products.where('qrCode', isEqualTo: qrCode).limit(1).get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // ✅ Get Product by ID
  Future<DocumentSnapshot> getProductById(String productId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      return await products.doc(productId).get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // ✅ Get all products with optional filters
  Future<QuerySnapshot> getProducts({
    String? category,
    bool? isActive,
    int? limit,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      Query query = products;
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query.get();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // ✅ Add Sale
  Future<String> addSale(Map<String, dynamic> saleData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      // ✅ Add user ID and timestamp
      saleData['userId'] = _currentUserId;
      saleData['createdAt'] = FieldValue.serverTimestamp();
      
      DocumentReference docRef = await sales.add(saleData);
      
      // ✅ Update product stock
      await updateProductStock(
        saleData['productId'], 
        -saleData['quantity'],
      );
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add sale: $e');
    }
  }

  // ✅ Update Product Stock
  Future<void> updateProductStock(String productId, int quantityChange) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      await products.doc(productId).update({
        'stock': FieldValue.increment(quantityChange),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // ✅ Get Daily Sales
  Future<QuerySnapshot> getDailySales(DateTime date) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      DateTime start = DateTime(date.year, date.month, date.day);
      DateTime end = start.add(const Duration(days: 1));
      
      return await sales
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get daily sales: $e');
    }
  }

  // ✅ Get Monthly Sales
  Future<QuerySnapshot> getMonthlySales(DateTime date) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      DateTime start = DateTime(date.year, date.month, 1);
      DateTime end = DateTime(date.year, date.month + 1, 1);
      
      return await sales
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get monthly sales: $e');
    }
  }

  // ✅ Get Sales Summary
Future<Map<String, dynamic>> getSalesSummary(DateTime date) async {
  try {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }
    
    QuerySnapshot dailySales = await getDailySales(date);
    
    double totalSales = 0;
    double totalProfit = 0;
    int totalItems = 0;
    
    for (var doc in dailySales.docs) {
      var data = doc.data() as Map<String, dynamic>;
      totalSales += (data['total'] ?? 0).toDouble();
      totalProfit += (data['profit'] ?? 0).toDouble();
      totalItems += (data['quantity'] ?? 0).toInt() as int;
    }
    
    return {
      'totalSales': totalSales,
      'totalProfit': totalProfit,
      'totalItems': totalItems,
      'transactionCount': dailySales.docs.length,
    };
  } catch (e) {
    throw Exception('Failed to get sales summary: $e');
  }
}

  // ✅ Get Low Stock Products
  Future<QuerySnapshot> getLowStockProducts(int threshold) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      return await products
          .where('stock', isLessThanOrEqualTo: threshold)
          .where('isActive', isEqualTo: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  // ✅ Get Store Settings
  DocumentReference get storeSettings {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('store_settings');
  }

  // ✅ Save Store Settings
  Future<void> saveStoreSettings(Map<String, dynamic> settings) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      settings['updatedAt'] = FieldValue.serverTimestamp();
      
      await storeSettings.set(settings, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save store settings: $e');
    }
  }

  // ✅ Get Store Settings
  Future<DocumentSnapshot> getStoreSettings() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      return await storeSettings.get();
    } catch (e) {
      throw Exception('Failed to get store settings: $e');
    }
  }

  // ✅ Search Products by Name
  Future<QuerySnapshot> searchProductsByName(String query) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      if (query.isEmpty) {
        return await products.limit(20).get();
      }
      
      // Note: Firestore doesn't support full-text search natively
      // This is a simple prefix search
      return await products
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
}