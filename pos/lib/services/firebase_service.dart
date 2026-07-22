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

  // ✅ Get the current user's business ID
  Future<String?> getCurrentBusinessId() async {
    try {
      if (!isAuthenticated) return null;

      final userDoc = await _firestore
          .collection('users')
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

  // ==================== PRODUCTS ====================

  // ✅ products getter - Returns top-level products collection
  CollectionReference<Map<String, dynamic>> get products {
    return _firestore.collection('products');
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

  // ==================== SALES ====================

  // ✅ sales getter - Returns top-level sales collection
  CollectionReference<Map<String, dynamic>> get sales {
    return _firestore.collection('sales');
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final businessRef = await _firestore.collection('businesses').add(businessData);
      final businessId = businessRef.id;

      // 2. Add the user to the users collection with businessId
      await _firestore.collection('users').doc(_currentUserId).set({
        'businessId': businessId,
        'role': 'owner',
        'email': _auth.currentUser?.email ?? '',
        'name': _auth.currentUser?.displayName ?? 'User',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Add user to business's users sub-collection
      await businessRef.collection('users').doc(_currentUserId).set({
        'name': _auth.currentUser?.displayName ?? 'User',
        'email': _auth.currentUser?.email ?? '',
        'role': 'owner',
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

  // ✅ Get all users from business
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

  // ✅ Add user to business
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

      // Check if manager already exists
      if (role == 'manager') {
        final existingManager = await businessRef
            .collection('users')
            .where('role', isEqualTo: 'manager')
            .limit(1)
            .get();

        if (existingManager.docs.isNotEmpty) {
          throw Exception('This business already has a manager. Only one manager is allowed.');
        }
      }

      // Add user to business users sub-collection
      await businessRef.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's document with businessId
      await _firestore.collection('users').doc(userId).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add user to business: $e');
    }
  }

  // ✅ Update user role
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
          throw Exception('This business already has a manager. Only one manager is allowed.');
        }
      }

      // Update in business users sub-collection
      await businessRef.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update in users collection
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // ✅ Toggle user active status
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

      // Update in business users sub-collection
      await businessRef.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update in users collection
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
  }

  // ✅ Remove user from business
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

      // Remove from business users sub-collection
      await businessRef.collection('users').doc(userId).delete();

      // Remove businessId from users collection
      await _firestore.collection('users').doc(userId).update({
        'businessId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove user: $e');
    }
  }

  // ✅ Get Firestore instance for batch operations
  FirebaseFirestore get firestore => _firestore;
}