import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/services/firebase_service.dart';

class CustomerService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get all unique customers from sales
  Future<List<Customer>> getAllCustomers() async {
    try {
      final businessId = await _firebaseService.getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      // Get all sales
      final salesSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .get();

      // Extract unique customers from sales
      final Map<String, Customer> customerMap = {};

      for (var doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final customerId = data['customerId'] ?? 'guest';
        final isGuest = data['isGuestCustomer'] ?? true;

        // Skip guest customers if we want only registered
        if (isGuest) continue;

        // Skip if customerId is empty or 'guest'
        if (customerId == 'guest' || customerId.isEmpty) continue;

        // If customer already exists, update their data
        if (customerMap.containsKey(customerId)) {
          final existing = customerMap[customerId]!;
          final totalSpent = existing.totalSpent + (data['total'] ?? 0.0).toDouble();
          final totalOrders = existing.totalOrders + 1;
          
          customerMap[customerId] = existing.copyWith(
            totalSpent: totalSpent,
            totalOrders: totalOrders,
            averageOrderValue: totalSpent / totalOrders,
            lastPurchaseDate: (data['saleDate'] as Timestamp?)?.toDate() ?? existing.lastPurchaseDate,
            updatedAt: DateTime.now(),
          );
        } else {
          // Create new customer from sale data
          customerMap[customerId] = Customer(
            id: customerId,
            name: data['customerName'] ?? 'Unknown Customer',
            email: data['customerEmail'] ?? '',
            phone: data['customerPhone'] ?? '',
            address: data['customerAddress'] ?? '',
            totalSpent: (data['total'] ?? 0.0).toDouble(),
            totalOrders: 1,
            averageOrderValue: (data['total'] ?? 0.0).toDouble(),
            lastPurchaseDate: (data['saleDate'] as Timestamp?)?.toDate(),
            createdAt: (data['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );
        }
      }

      return customerMap.values.toList();
    } catch (e) {
      throw Exception('Failed to get customers: $e');
    }
  }

  // ✅ Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream() {
    return _firebaseService.getCurrentBusinessId().asStream().asyncExpand((businessId) {
      if (businessId == null) {
        return Stream.fromFuture(Future.value([]));
      }

      return _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .snapshots()
          .map((snapshot) {
            final Map<String, Customer> customerMap = {};

            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final customerId = data['customerId'] ?? 'guest';
              final isGuest = data['isGuestCustomer'] ?? true;

              if (isGuest || customerId == 'guest' || customerId.isEmpty) continue;

              if (customerMap.containsKey(customerId)) {
                final existing = customerMap[customerId]!;
                final totalSpent = existing.totalSpent + (data['total'] ?? 0.0).toDouble();
                final totalOrders = existing.totalOrders + 1;
                
                customerMap[customerId] = existing.copyWith(
                  totalSpent: totalSpent,
                  totalOrders: totalOrders,
                  averageOrderValue: totalSpent / totalOrders,
                  lastPurchaseDate: (data['saleDate'] as Timestamp?)?.toDate() ?? existing.lastPurchaseDate,
                  updatedAt: DateTime.now(),
                );
              } else {
                customerMap[customerId] = Customer(
                  id: customerId,
                  name: data['customerName'] ?? 'Unknown Customer',
                  email: data['customerEmail'] ?? '',
                  phone: data['customerPhone'] ?? '',
                  address: data['customerAddress'] ?? '',
                  totalSpent: (data['total'] ?? 0.0).toDouble(),
                  totalOrders: 1,
                  averageOrderValue: (data['total'] ?? 0.0).toDouble(),
                  lastPurchaseDate: (data['saleDate'] as Timestamp?)?.toDate(),
                  createdAt: (data['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: true,
                );
              }
            }

            return customerMap.values.toList();
          });
    });
  }

  // ✅ Search customers from sales
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final allCustomers = await getAllCustomers();
      final searchTerm = query.toLowerCase().trim();
      
      return allCustomers.where((customer) {
        return customer.name.toLowerCase().contains(searchTerm) ||
            customer.phone.contains(searchTerm) ||
            customer.email.toLowerCase().contains(searchTerm);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  // ✅ Get customer by ID from sales
  Future<Customer?> getCustomerById(String id) async {
    try {
      final businessId = await _firebaseService.getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      // Get all sales for this customer
      final salesSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('customerId', isEqualTo: id)
          .orderBy('saleDate', descending: true)
          .get();

      if (salesSnapshot.docs.isEmpty) return null;

      final firstSale = salesSnapshot.docs.first.data() as Map<String, dynamic>;
      double totalSpent = 0;
      int totalOrders = salesSnapshot.docs.length;

      for (var doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalSpent += (data['total'] ?? 0.0).toDouble();
      }

      return Customer(
        id: id,
        name: firstSale['customerName'] ?? 'Unknown Customer',
        email: firstSale['customerEmail'] ?? '',
        phone: firstSale['customerPhone'] ?? '',
        address: firstSale['customerAddress'] ?? '',
        totalSpent: totalSpent,
        totalOrders: totalOrders,
        averageOrderValue: totalSpent / totalOrders,
        lastPurchaseDate: (firstSale['saleDate'] as Timestamp?)?.toDate(),
        createdAt: (firstSale['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  // ✅ Get customer's sales history
  Future<List<QueryDocumentSnapshot>> getCustomerSales(String customerId) async {
    try {
      final businessId = await _firebaseService.getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('customerId', isEqualTo: customerId)
          .orderBy('saleDate', descending: true)
          .get();

      return snapshot.docs;
    } catch (e) {
      throw Exception('Failed to get customer sales: $e');
    }
  }

  // ✅ Update customer info in all their sales
  Future<void> updateCustomerInfo({
    required String customerId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      final businessId = await _firebaseService.getCurrentBusinessId();
      if (businessId == null) throw Exception('Business not found');

      // Get all sales for this customer
      final salesSnapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .where('customerId', isEqualTo: customerId)
          .get();

      if (salesSnapshot.docs.isEmpty) {
        throw Exception('Customer not found');
      }

      // Update all sales with new customer info
      final batch = _firestore.batch();
      for (var doc in salesSnapshot.docs) {
        batch.update(doc.reference, {
          'customerName': name,
          'customerPhone': phone,
          'customerEmail': email,
          'customerAddress': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update customer info: $e');
    }
  }
}