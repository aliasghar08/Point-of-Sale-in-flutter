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

  // ✅ Get the current user's business ID - FIXED
  Future<String?> getCurrentBusinessId() async {
    try {
      if (!isAuthenticated) return null;

      // First, check if user has a businessId in their user document
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final businessId = data['businessId'] as String?;
        if (businessId != null && businessId.isNotEmpty) {
          return businessId;
        }
      }

      // If no businessId, search the businesses collection
      // Look for a business where the user is the owner
      final businessesSnapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      if (businessesSnapshot.docs.isNotEmpty) {
        // The document ID is the businessId
        final businessId = businessesSnapshot.docs.first.id;
        
        // Save the businessId to the user's document for future use
        await _firestore.collection('users').doc(_currentUserId).set({
          'businessId': businessId,
          'role': 'owner',
          'email': _auth.currentUser?.email ?? '',
          'name': _auth.currentUser?.displayName ?? 'User',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        return businessId;
      }

      // Also check if user exists in any business's users sub-collection
      final allBusinesses = await _firestore.collection('businesses').get();
      
      for (var businessDoc in allBusinesses.docs) {
        final userInBusiness = await businessDoc.reference
            .collection('users')
            .doc(_currentUserId)
            .get();
        
        if (userInBusiness.exists) {
          final businessId = businessDoc.id;
          
          await _firestore.collection('users').doc(_currentUserId).set({
            'businessId': businessId,
            'role': 'owner',
            'email': _auth.currentUser?.email ?? '',
            'name': _auth.currentUser?.displayName ?? 'User',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          return businessId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting business ID: $e');
      return null;
    }
  }

  // ==================== PRODUCTS ====================

  // ✅ products getter - Top-level products collection (Legacy/Admin access)
  CollectionReference<Map<String, dynamic>> get products {
    return _firestore.collection('products');
  }

  // ✅ getBusinessProducts - Business-scoped products collection
  Future<CollectionReference<Map<String, dynamic>>> getBusinessProducts() async {
    final businessId = await getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Business not found');
    }
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('products');
  }

  // ✅ productsStream for real-time updates with business scoping
  Stream<QuerySnapshot> productsStream() {
    return getCurrentBusinessId().asStream().asyncExpand((businessId) {
      if (businessId == null) {
        debugPrint('⚠️ No business found');
        return Stream.fromFuture(
          _firestore.collection('_empty').limit(1).get()
        );
      }

      final productsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products');

      return productsRef.snapshots();
    });
  }

  // ✅ addProduct - Add product to business
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

  // ✅ updateProduct - Update product in business
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

  // ✅ deleteProduct - Delete product from business
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

  // ✅ getProductByBarcode - Search by barcode in business
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

  // ✅ getProductByQRCode - Search by QR code in business
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

  // ✅ getProductById - Get product by ID from business
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

  // ✅ updateProductStock - Update stock in business
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

  // ✅ getProductByName - Search products by name in business
  Future<QuerySnapshot> getProductByName(String name) async {
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
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThanOrEqualTo: name + '\uf8ff')
          .limit(20)
          .get();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // ✅ getAllProducts - Get all products from business
  Future<QuerySnapshot> getAllProducts() async {
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

      return await productsRef.get();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // ==================== SALES ====================

  // ✅ sales getter - Top-level sales collection (Legacy/Admin access)
  CollectionReference<Map<String, dynamic>> get sales {
    return _firestore.collection('sales');
  }

  // ✅ getBusinessSales - Business-scoped sales collection
  Future<CollectionReference<Map<String, dynamic>>> getBusinessSales() async {
    final businessId = await getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Business not found');
    }
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('sales');
  }

  // ✅ salesStream for real-time updates
  Stream<QuerySnapshot> salesStream() {
    return getCurrentBusinessId().asStream().asyncExpand((businessId) {
      if (businessId == null) {
        debugPrint('⚠️ No business found');
        return Stream.fromFuture(
          _firestore.collection('_empty').limit(1).get()
        );
      }

      final salesRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales');

      return salesRef.snapshots();
    });
  }

  // ✅ addSale - Add sale to business
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

  // ✅ getSalesByDate - Get sales by date range
  Future<QuerySnapshot> getSalesByDate(DateTime startDate, DateTime endDate) async {
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

      return await salesRef
          .where('saleDate', isGreaterThanOrEqualTo: startDate)
          .where('saleDate', isLessThanOrEqualTo: endDate)
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get sales: $e');
    }
  }

  // ✅ getSalesByReceiptNumber - Get sale by receipt number
  Future<QuerySnapshot> getSalesByReceiptNumber(String receiptNumber) async {
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

      return await salesRef
          .where('receiptNumber', isEqualTo: receiptNumber)
          .limit(1)
          .get();
    } catch (e) {
      throw Exception('Failed to get sale: $e');
    }
  }

  // ✅ getTodaySales - Get today's sales
  Future<QuerySnapshot> getTodaySales() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return await getSalesByDate(startOfDay, endOfDay);
    } catch (e) {
      throw Exception('Failed to get today\'s sales: $e');
    }
  }

  // ==================== BUSINESS METHODS ====================

  // ✅ Create a business and link the current user
  Future<String> createBusiness(String businessName) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // 1. Create the business document
      final businessData = {
        'name': businessName,
        'ownerId': _currentUserId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final businessRef = await _firestore.collection('businesses').add(businessData);
      final businessId = businessRef.id;

      // 2. Add user to business's users sub-collection
      await businessRef.collection('users').doc(_currentUserId).set({
        'name': _auth.currentUser?.displayName ?? 'User',
        'email': _auth.currentUser?.email ?? '',
        'role': 'owner',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update user's document with businessId
      await _firestore.collection('users').doc(_currentUserId).set({
        'businessId': businessId,
        'role': 'owner',
        'email': _auth.currentUser?.email ?? '',
        'name': _auth.currentUser?.displayName ?? 'User',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return businessId;
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  // ✅ Get business info
  Future<Map<String, dynamic>?> getBusinessInfo() async {
    try {
      if (!isAuthenticated) return null;

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

  // ✅ Get Firestore instance for batch operations
  FirebaseFirestore get firestore => _firestore;
}