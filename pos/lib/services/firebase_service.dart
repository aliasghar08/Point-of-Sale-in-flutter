import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  bool get isAuthenticated => _currentUserId != null;

  Future<String?> getCurrentBusinessId() async {
    try {
      if (!isAuthenticated) return null;

      final userDoc = await _firestore
          .collection('userBusinessLookup')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['businessId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting business ID: $e');
      return null;
    }
  }

  Future<DocumentReference?> getBusinessRef() async {
    final businessId = await getCurrentBusinessId();
    if (businessId == null) return null;
    return _firestore.collection('businesses').doc(businessId);
  }

  // ==================== PRODUCTS ====================

  CollectionReference<Map<String, dynamic>> get products {
    return _firestore.collection('products');
  }

  // ✅ Simple working solution - no custom classes needed
  Stream<QuerySnapshot> productsStream() {
    return getCurrentBusinessId().asStream().asyncExpand((businessId) {
      if (businessId == null) {
        debugPrint('⚠️ No business found');
        // Return empty stream with real snapshot
        return Stream.fromFuture(
          _firestore.collection('_empty').limit(0).get()
        );
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      return productsRef.snapshots();
    });
  }

  Future<CollectionReference<Map<String, dynamic>>> getProductsCollection() async {
    final businessId = await getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Business not found');
    }
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products');
  }

  Future<QuerySnapshot> getProducts({
    String? category,
    bool? isActive,
    int? limit,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      Query query = productsRef;

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

  Future<DocumentReference> addProduct(Map<String, dynamic> productData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      productData['createdBy'] = _currentUserId;
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef = await productsRef.add(productData);
      return docRef;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      data['updatedAt'] = FieldValue.serverTimestamp();
      await productsRef.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      await productsRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<QuerySnapshot> getProductByBarcode(String barcode) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      return await productsRef
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<QuerySnapshot> getProductByQRCode(String qrCode) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      return await productsRef
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<DocumentSnapshot> getProductById(String productId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      return await productsRef.doc(productId).get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<QuerySnapshot> searchProductsByName(String query) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      if (query.isEmpty) {
        return await productsRef.limit(20).get();
      }

      return await productsRef
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<QuerySnapshot> getLowStockProducts(int threshold) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      return await productsRef
          .where('stock', isLessThanOrEqualTo: threshold)
          .where('isActive', isEqualTo: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  Future<void> updateProductStock(String productId, int quantityChange) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      await productsRef.doc(productId).update({
        'stock': FieldValue.increment(quantityChange),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // ==================== SALES ====================

  CollectionReference<Map<String, dynamic>> get sales {
    return _firestore.collection('sales');
  }

  Stream<QuerySnapshot> salesStream() {
    return getCurrentBusinessId().asStream().asyncExpand((businessId) {
      if (businessId == null) {
        debugPrint('⚠️ No business found');
        return Stream.fromFuture(
          _firestore.collection('_empty').limit(0).get()
        );
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      return salesRef.snapshots();
    });
  }

  Future<QuerySnapshot> getSales({
    DateTime? fromDate,
    DateTime? toDate,
    String? productId,
    int? limit,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      Query query = salesRef;

      if (fromDate != null) {
        query = query.where('saleDate', isGreaterThanOrEqualTo: fromDate);
      }

      if (toDate != null) {
        query = query.where('saleDate', isLessThanOrEqualTo: toDate);
      }

      if (productId != null && productId.isNotEmpty) {
        query = query.where('productId', isEqualTo: productId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.orderBy('saleDate', descending: true);

      return await query.get();
    } catch (e) {
      throw Exception('Failed to get sales: $e');
    }
  }

  Future<DocumentReference> addSale(Map<String, dynamic> saleData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      saleData['createdBy'] = _currentUserId;
      saleData['createdAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef = await salesRef.add(saleData);

      if (saleData.containsKey('productId') && saleData.containsKey('quantity')) {
        await updateProductStock(
          saleData['productId'],
          -(saleData['quantity'] as int),
        );
      }

      return docRef;
    } catch (e) {
      throw Exception('Failed to add sale: $e');
    }
  }

  Future<QuerySnapshot> getDailySales(DateTime date) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      DateTime start = DateTime(date.year, date.month, date.day);
      DateTime end = start.add(const Duration(days: 1));

      return await salesRef
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get daily sales: $e');
    }
  }

  Future<QuerySnapshot> getMonthlySales(DateTime date) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      DateTime start = DateTime(date.year, date.month, 1);
      DateTime end = (date.month < 12)
          ? DateTime(date.year, date.month + 1, 1)
          : DateTime(date.year + 1, 1, 1);

      return await salesRef
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get monthly sales: $e');
    }
  }

  Future<Map<String, dynamic>> getSalesSummary(DateTime date) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      DateTime start = DateTime(date.year, date.month, date.day);
      DateTime end = start.add(const Duration(days: 1));

      final dailySales = await salesRef
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .get();

      double totalSales = 0;
      double totalProfit = 0;
      int totalItems = 0;

      for (var doc in dailySales.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalSales += (data['total'] ?? 0).toDouble();
        totalProfit += (data['profit'] ?? 0).toDouble();

        final quantity = data['quantity'];
        if (quantity is int) {
          totalItems += quantity;
        } else if (quantity is double) {
          totalItems += quantity.toInt();
        } else {
          totalItems += (quantity ?? 0) as int;
        }
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

  // ==================== BUSINESS METHODS ====================

  Future<DocumentSnapshot> getStoreSettings() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      return await _firestore.collection('businesses').doc(businessId).get();
    } catch (e) {
      throw Exception('Failed to get store settings: $e');
    }
  }

  Future<void> saveStoreSettings(Map<String, dynamic> settings) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      settings['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save store settings: $e');
    }
  }

  Future<QuerySnapshot> getBusinessUsers() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      return await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .get();
    } catch (e) {
      throw Exception('Failed to get business users: $e');
    }
  }

  Future<void> addUserToBusiness({
    required String userId,
    required String name,
    required String email,
    required String role,
    required String phone,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final businessRef = _firestore.collection('businesses').doc(businessId);

      if (role == 'manager') {
        final existingManager = await businessRef
            .collection('users')
            .where('role', isEqualTo: 'manager')
            .limit(1)
            .get();

        if (existingManager.docs.isNotEmpty) {
          throw Exception(
            'This business already has a manager. Only one manager is allowed.',
          );
        }
      }

      await businessRef.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('userBusinessLookup').doc(userId).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
      });
    } catch (e) {
      throw Exception('Failed to add user to business: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final businessRef = _firestore.collection('businesses').doc(businessId);

      if (newRole == 'manager') {
        final existingManager = await businessRef
            .collection('users')
            .where('role', isEqualTo: 'manager')
            .limit(1)
            .get();

        if (existingManager.docs.isNotEmpty && existingManager.docs.first.id != userId) {
          throw Exception(
            'This business already has a manager. Only one manager is allowed.',
          );
        }
      }

      await businessRef.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('userBusinessLookup').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final businessRef = _firestore.collection('businesses').doc(businessId);

      await businessRef.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
  }

  Future<Map<String, dynamic>?> getBusinessInfo() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) return null;

      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting business info: $e');
      return null;
    }
  }

  Future<void> removeUserFromBusiness(String userId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      final businessRef = _firestore.collection('businesses').doc(businessId);

      await businessRef.collection('users').doc(userId).delete();

      await _firestore.collection('userBusinessLookup').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to remove user: $e');
    }
  }

  FirebaseFirestore get firestore => _firestore;
}