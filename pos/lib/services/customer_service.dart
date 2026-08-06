import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';

/// In-house customer CRM and loyalty points management service.
class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();

  Future<String?> get _businessId => _firebaseService.getCurrentBusinessId();

  CollectionReference _customersRef(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('customers');
  }

  /// Get all customers with cache support
  Future<List<Customer>> getAllCustomers({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.hasValidCustomerCache) {
      return _cache.allCustomers;
    }

    final businessId = await _businessId;
    if (businessId == null) return [];

    final snapshot = await _customersRef(businessId)
        .orderBy('totalSpent', descending: true)
        .get();

    final customers = snapshot.docs.map((doc) {
      return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    _cache.setCustomers(customers);
    return customers;
  }

  /// Add new customer
  Future<Customer> addCustomer({
    required String name,
    required String phone,
    String email = '',
    String address = '',
  }) async {
    final businessId = await _businessId;
    if (businessId == null) throw Exception('No active business found');

    final docRef = _customersRef(businessId).doc();
    final now = DateTime.now();
    final customer = Customer(
      id: docRef.id,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      address: address.trim(),
      totalSpent: 0.0,
      totalOrders: 0,
      averageOrderValue: 0.0,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    await docRef.set(customer.toMap());
    _cache.upsertCustomer(customer);
    return customer;
  }

  /// Update customer details
  Future<void> updateCustomer(Customer customer) async {
    final businessId = await _businessId;
    if (businessId == null) throw Exception('No active business found');

    final updated = customer.copyWith(updatedAt: DateTime.now());
    await _customersRef(businessId).doc(customer.id).update(updated.toMap());
    _cache.upsertCustomer(updated);
  }

  /// Record a completed sale on the customer's lifetime stats
  Future<void> recordSale({
    required String customerId,
    required double saleAmount,
  }) async {
    if (customerId == 'guest' || customerId.isEmpty) return;

    final businessId = await _businessId;
    if (businessId == null) return;

    final docRef = _customersRef(businessId).doc(customerId);
    final doc = await docRef.get();

    if (doc.exists) {
      final customer = Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final newSpent = customer.totalSpent + saleAmount;
      final newOrders = customer.totalOrders + 1;
      final updated = customer.copyWith(
        totalSpent: newSpent,
        totalOrders: newOrders,
        averageOrderValue: newSpent / newOrders,
        lastPurchaseDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.update(updated.toMap());
      _cache.upsertCustomer(updated);
    }
  }

  /// Search customers in cache or Firestore
  List<Customer> searchCustomers(String query) {
    return _cache.searchCustomers(query);
  }
}
