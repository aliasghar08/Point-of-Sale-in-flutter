import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  // ==================== HASHING UTILITY ====================
  
  /// ✅ Generates a deterministic 20-character ID based on input details
  String _generateHashId(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    // Return first 20 chars of the hex hash to match standard Firestore ID length
    return digest.toString().substring(0, 20);
  }

  // =========================================================

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

      // Also check if user exists in any business's members sub-collection
      final allBusinesses = await _firestore.collection('businesses').get();
      
      for (var businessDoc in allBusinesses.docs) {
        final userInBusiness = await businessDoc.reference
            .collection('members')
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

  // ==================== BUSINESS LOOKUP ====================

  /// ✅ Search for businesses by name (case insensitive)
  Future<List<Map<String, dynamic>>> searchBusinesses(String query) async {
    try {
      if (query.isEmpty) return [];

      final searchTerm = query.toLowerCase().trim();
      
      // Get all businesses
      final snapshot = await _firestore.collection('businesses').get();
      
      // Filter by name (case insensitive)
      final results = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(searchTerm);
      }).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Business',
          'ownerId': data['ownerId'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      return results;
    } catch (e) {
      debugPrint('Error searching businesses: $e');
      return [];
    }
  }

  /// ✅ Get business by exact name (case insensitive)
  Future<Map<String, dynamic>?> getBusinessByName(String name) async {
    try {
      if (name.isEmpty) return null;

      final searchTerm = name.toLowerCase().trim();
      
      // Get all businesses
      final snapshot = await _firestore.collection('businesses').get();
      
      // Find exact match (case insensitive)
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final businessName = (data['name'] ?? '').toString().toLowerCase();
        if (businessName == searchTerm) {
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Business',
            'ownerId': data['ownerId'] ?? '',
            'isActive': data['isActive'] ?? true,
          };
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting business by name: $e');
      return null;
    }
  }

  /// ✅ Check if a business exists
  Future<bool> businessExists(String businessName) async {
    try {
      final business = await getBusinessByName(businessName);
      return business != null;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Get all businesses with their names for autocomplete
  Future<List<String>> getBusinessNames() async {
    try {
      final snapshot = await _firestore.collection('businesses').get();
      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] ?? '')
          .where((name) => name.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('Error getting business names: $e');
      return [];
    }
  }

  // ==================== MEMBERS (Business Users) ====================

  /// ✅ Get members sub-collection reference for a business
  CollectionReference getBusinessMembersCollection(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('members');
  }

  /// ✅ Get all users from a business (now from members sub-collection)
  Future<List<Map<String, dynamic>>> getBusinessUsers(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'worker',
          'phone': data['phone'] ?? '',
          'isActive': data['isActive'] ?? true,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting business users: $e');
      return [];
    }
  }

  /// ✅ Get a specific user from a business (now from members sub-collection)
  Future<Map<String, dynamic>?> getBusinessUser(String businessId, String userId) async {
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'worker',
          'phone': data['phone'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting business user: $e');
      return null;
    }
  }

  /// ✅ Add user to an existing business
  Future<void> addUserToBusiness({
    required String userId,
    required String email,
    required String name,
    required String role,
    required String phone,
    required String businessId,
  }) async {
    try {
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (!businessDoc.exists) {
        throw Exception('Business not found');
      }

      final existingUser = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .get();

      if (existingUser.exists) {
        throw Exception('User already exists in this business');
      }

      if (role == 'manager') {
        final managerSnapshot = await _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('members')
            .where('role', isEqualTo: 'manager')
            .limit(1)
            .get();

        if (managerSnapshot.docs.isNotEmpty) {
          throw Exception('This business already has a manager. Only one manager is allowed.');
        }
      }

      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .set({
            'id': userId,
            'email': email,
            'name': name,
            'role': role,
            'phone': phone,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('users').doc(userId).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('userBusinessLookup').doc(userId).set({
        'businessId': businessId,
        'role': role,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ User $name added to business $businessId as $role');
    } catch (e) {
      throw Exception('Failed to add user to business: $e');
    }
  }

  /// ✅ Update user role in business
  Future<void> updateUserRoleInBusiness({
    required String businessId,
    required String userId,
    required String newRole,
  }) async {
    try {
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (!businessDoc.exists) {
        throw Exception('Business not found');
      }

      final userDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found in this business');
      }

      if (newRole == 'manager') {
        final managerSnapshot = await _firestore
            .collection('businesses')
            .doc(businessId)
            .collection('members')
            .where('role', isEqualTo: 'manager')
            .limit(1)
            .get();

        if (managerSnapshot.docs.isNotEmpty && managerSnapshot.docs.first.id != userId) {
          throw Exception('This business already has a manager. Only one manager is allowed.');
        }
      }

      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .update({
            'role': newRole,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('userBusinessLookup').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User role updated to $newRole in business $businessId');
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// ✅ Toggle user active status in business
  Future<void> toggleUserActiveInBusiness({
    required String businessId,
    required String userId,
    required bool isActive,
  }) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .update({
            'isActive': isActive,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User active status updated to $isActive in business $businessId');
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
  }

  /// ✅ Remove user from business
  Future<void> removeUserFromBusiness({
    required String businessId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(userId)
          .delete();

      await _firestore.collection('users').doc(userId).update({
        'businessId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('userBusinessLookup').doc(userId).delete();

      debugPrint('✅ User removed from business $businessId');
    } catch (e) {
      throw Exception('Failed to remove user from business: $e');
    }
  }

  // ==================== PRODUCTS ====================

  CollectionReference<Map<String, dynamic>> get products {
    return _firestore.collection('products');
  }

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

  // ✅ addProduct - Hashed ID based on BusinessID, Product Name, and Barcode
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

      // Create a deterministic hash for the product
      final name = (productData['name'] ?? '').toString().trim().toLowerCase();
      final barcode = (productData['barcode'] ?? productData['qrCode'] ?? '').toString().trim();
      
      final uniqueString = '${businessId}_${name}_$barcode';
      final productId = _generateHashId(uniqueString);

      DocumentReference docRef = productsRef.doc(productId);
      await docRef.set(productData);
      
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

  Future<Map<String, DocumentSnapshot>> getProductsByIds(List<String> productIds) async {
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

      final Map<String, DocumentSnapshot> result = {};
      
      for (var id in productIds) {
        final doc = await productsRef.doc(id).get();
        if (doc.exists) {
          result[id] = doc;
        }
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to get products: $e');
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

  Future<void> updateMultipleProductsStock(Map<String, int> productStockChanges) async {
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

      final batch = _firestore.batch();
      
      for (var entry in productStockChanges.entries) {
        final productRef = productsRef.doc(entry.key);
        batch.update(productRef, {
          'stock': FieldValue.increment(entry.value),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update products stock: $e');
    }
  }

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

  // ==================== SALES (NOW USES BATCH WRITES) ====================

  CollectionReference<Map<String, dynamic>> get sales {
    return _firestore.collection('sales');
  }

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

  Stream<QuerySnapshot> getSalesStreamForBusiness() {
    return getCurrentBusinessId().asStream().asyncExpand((businessId) {
      if (businessId == null) {
        debugPrint('⚠️ No business found');
        return Stream.fromFuture(
          _firestore.collection('_empty').limit(1).get()
        );
      }

      return _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .orderBy('saleDate', descending: true)
          .limit(50)
          .snapshots();
    });
  }

  // ✅ addSale - UPDATED TO BATCH WRITE (Signatures maintained)
  Future<DocumentReference> addSale(Map<String, dynamic> saleData) async {
    try {
      if (!isAuthenticated) throw Exception('User not authenticated');
      final businessId = await getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      final batch = _firestore.batch();
      final businessRef = _firestore.collection('businesses').doc(businessId);

      // 1. Prepare Sale Document
      saleData['createdBy'] = _currentUserId;
      saleData['createdAt'] = FieldValue.serverTimestamp();

      final receipt = (saleData['receiptNumber'] ?? '').toString().trim();
      final timeSuffix = receipt.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : '';
      final saleId = _generateHashId('${businessId}_${receipt}_$timeSuffix');
      
      final saleRef = businessRef.collection('sales').doc(saleId);
      batch.set(saleRef, saleData);

      // 2. Prepare Product Stock Deduction
      if (saleData.containsKey('productId') && saleData.containsKey('quantity')) {
        final productRef = businessRef.collection('products').doc(saleData['productId']);
        batch.update(productRef, {
          'stock': FieldValue.increment(-(saleData['quantity'] as int)),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Prepare Customer CRM Stat Update
      final customerId = saleData['customerId'] as String?;
      final isGuest = saleData['isGuestCustomer'] as bool? ?? false;
      
      if (customerId != null && customerId.isNotEmpty && customerId != 'guest' && !isGuest) {
        final customerRef = businessRef.collection('customers').doc(customerId);
        batch.set(customerRef, {
          'totalSpent': FieldValue.increment((saleData['total'] ?? 0.0).toDouble()),
          'totalOrders': FieldValue.increment(1),
          'lastPurchaseDate': saleData['saleDate'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 4. Commit all three operations at once
      await batch.commit();

      return saleRef;
    } catch (e) {
      throw Exception('Failed to add sale: $e');
    }
  }

  // ✅ addMultipleSales - UPDATED TO BATCH WRITE (Signatures maintained)
  Future<void> addMultipleSales(List<Map<String, dynamic>> salesData) async {
    try {
      if (!isAuthenticated) throw Exception('User not authenticated');
      final businessId = await getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      final batch = _firestore.batch();
      final businessRef = _firestore.collection('businesses').doc(businessId);
      
      for (var sale in salesData) {
        sale['createdBy'] = _currentUserId;
        sale['createdAt'] = FieldValue.serverTimestamp();
        
        final receipt = (sale['receiptNumber'] ?? '').toString().trim();
        final timeSuffix = receipt.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : '';
        final saleId = _generateHashId('${businessId}_${receipt}_$timeSuffix');
        
        final saleRef = businessRef.collection('sales').doc(saleId);
        batch.set(saleRef, sale);

        if (sale.containsKey('productId') && sale.containsKey('quantity')) {
          final productRef = businessRef.collection('products').doc(sale['productId']);
          batch.update(productRef, {
            'stock': FieldValue.increment(-(sale['quantity'] as int)),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final customerId = sale['customerId'] as String?;
        final isGuest = sale['isGuestCustomer'] as bool? ?? false;
        
        if (customerId != null && customerId.isNotEmpty && customerId != 'guest' && !isGuest) {
          final customerRef = businessRef.collection('customers').doc(customerId);
          batch.set(customerRef, {
            'totalSpent': FieldValue.increment((sale['total'] ?? 0.0).toDouble()),
            'totalOrders': FieldValue.increment(1),
            'lastPurchaseDate': sale['saleDate'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add sales: $e');
    }
  }

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

  Future<QuerySnapshot> getAllSales() async {
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
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get sales: $e');
    }
  }

  Future<QuerySnapshot> getSalesWithFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int limit = 100,
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

      if (startDate != null) {
        query = query.where('saleDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('saleDate', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('saleDate', descending: true);

      if (limit > 0) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      throw Exception('Failed to get filtered sales: $e');
    }
  }

  Future<QuerySnapshot> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
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

      return await salesRef
          .where('saleDate', isGreaterThanOrEqualTo: startDate)
          .where('saleDate', isLessThanOrEqualTo: endDate)
          .orderBy('saleDate', descending: true)
          .limit(limit)
          .get();
    } catch (e) {
      throw Exception('Failed to get sales by date range: $e');
    }
  }

  Future<QuerySnapshot> getTodaySales() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return await getSalesByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
        limit: 500,
      );
    } catch (e) {
      throw Exception('Failed to get today\'s sales: $e');
    }
  }

  Future<QuerySnapshot> getWeekSales() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final weekEnd = today.add(Duration(days: 7 - now.weekday));
      final endOfDay = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
      
      return await getSalesByDateRange(
        startDate: weekStart,
        endDate: endOfDay,
        limit: 500,
      );
    } catch (e) {
      throw Exception('Failed to get week sales: $e');
    }
  }

  Future<QuerySnapshot> getMonthSales() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      return await getSalesByDateRange(
        startDate: monthStart,
        endDate: monthEnd,
        limit: 500,
      );
    } catch (e) {
      throw Exception('Failed to get month sales: $e');
    }
  }

  // ==================== CUSTOMERS (CRM) ====================
  // All signatures match your old code exactly, but now use the real Customers collection!

  // 🚀 NEW: Add a customer to the CRM
  Future<DocumentReference> addCustomer(Map<String, dynamic> customerData) async {
    try {
      if (!isAuthenticated) throw Exception('User not authenticated');
      final businessId = await getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      final customersRef = _firestore.collection('businesses').doc(businessId).collection('customers');

      customerData['createdBy'] = _currentUserId;
      customerData['createdAt'] = FieldValue.serverTimestamp();
      customerData['updatedAt'] = FieldValue.serverTimestamp();
      
      customerData['totalSpent'] ??= 0.0;
      customerData['totalOrders'] ??= 0;
      customerData['isActive'] ??= true;

      final phone = (customerData['phone'] ?? '').toString().trim();
      final email = (customerData['email'] ?? '').toString().trim();
      final uniqueIdentifier = phone.isNotEmpty ? phone : (email.isNotEmpty ? email : DateTime.now().millisecondsSinceEpoch.toString());
      
      final customerId = _generateHashId('${businessId}_$uniqueIdentifier');

      final docRef = customersRef.doc(customerId);
      await docRef.set(customerData);
      
      return docRef;
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  // 🚀 NEW: Update existing customer
  Future<void> updateCustomer(String customerId, Map<String, dynamic> data) async {
    try {
      final businessId = await getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('businesses').doc(businessId).collection('customers').doc(customerId).update(data);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  // ✅ getCustomers - Signature maintained, internal logic upgraded
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      // Now pulling from the dedicated customers collection
      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('customers')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Inject ID to perfectly match the old map structure
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get customers: $e');
    }
  }

  // ✅ getCustomerById - Signature maintained, internal logic upgraded
  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final businessId = await getCurrentBusinessId();
      if (businessId == null) {
        throw Exception('Business not found');
      }

      // Now pulling direct document read instead of querying thousands of sales
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('customers')
          .doc(customerId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Inject ID to perfectly match old structure
      return data;
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  // ✅ searchCustomers - Signature maintained, runs instantly now
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final allCustomers = await getCustomers();
      final searchTerm = query.toLowerCase().trim();
      
      return allCustomers.where((customer) {
        return (customer['name'] ?? '').toString().toLowerCase().contains(searchTerm) ||
            (customer['phone'] ?? '').toString().contains(searchTerm) ||
            (customer['email'] ?? '').toString().toLowerCase().contains(searchTerm);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  // ✅ getCustomerSales - Unchanged, this was already correct (queries sales)
  Future<QuerySnapshot> getCustomerSales(String customerId) async {
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
          .collection('sales')
          .where('customerId', isEqualTo: customerId)
          .orderBy('saleDate', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to get customer sales: $e');
    }
  }

  // ==================== BUSINESS METHODS ====================

  // ✅ createBusiness - Hashed ID based on Business Name and User ID
  Future<String> createBusiness(String businessName) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Create a deterministic hash for the business
      final nameStr = businessName.trim().toLowerCase();
      final uniqueString = '${nameStr}_$_currentUserId';
      final businessId = _generateHashId(uniqueString);

      // 1. Create the business document using the hashed ID
      final businessData = {
        'name': businessName,
        'ownerId': _currentUserId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final businessRef = _firestore.collection('businesses').doc(businessId);
      await businessRef.set(businessData);

      // 2. Add user to business's members sub-collection
      await businessRef.collection('members').doc(_currentUserId).set({
        'id': _currentUserId,
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

      // 4. Add to lookup collection
      await _firestore.collection('userBusinessLookup').doc(_currentUserId).set({
        'businessId': businessId,
        'role': 'owner',
        'email': _auth.currentUser?.email ?? '',
        'name': _auth.currentUser?.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return businessId;
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

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

  FirebaseFirestore get firestore => _firestore;
}