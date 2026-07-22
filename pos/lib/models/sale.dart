import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double costPrice;
  final double total;
  final double profit;
  final DateTime saleDate;
  final String paymentMethod;
  final String receiptNumber;
  
  // ✅ Customer Info (Embedded)
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final bool isGuestCustomer;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.costPrice,
    required this.total,
    required this.profit,
    required this.saleDate,
    required this.paymentMethod,
    required this.receiptNumber,
    this.customerId = 'guest',
    this.customerName = 'Guest Customer',
    this.customerPhone = '',
    this.customerEmail,
    this.customerAddress,
    this.isGuestCustomer = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'costPrice': costPrice,
      'total': total,
      'profit': profit,
      'saleDate': saleDate,
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      // ✅ Customer Fields
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
      'isGuestCustomer': isGuestCustomer,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    return Sale(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      profit: map['profit']?.toDouble() ?? 0.0,
      saleDate: (map['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      receiptNumber: map['receiptNumber'] ?? '',
      // ✅ Customer Fields
      customerId: map['customerId'] ?? 'guest',
      customerName: map['customerName'] ?? 'Guest Customer',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'],
      customerAddress: map['customerAddress'],
      isGuestCustomer: map['isGuestCustomer'] ?? true,
    );
  }

  // ========== COPY WITH ==========
  Sale copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? costPrice,
    double? total,
    double? profit,
    DateTime? saleDate,
    String? paymentMethod,
    String? receiptNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    bool? isGuestCustomer,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      total: total ?? this.total,
      profit: profit ?? this.profit,
      saleDate: saleDate ?? this.saleDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAddress: customerAddress ?? this.customerAddress,
      isGuestCustomer: isGuestCustomer ?? this.isGuestCustomer,
    );
  }

  // ========== HELPER GETTERS ==========
  
  // Get customer display name
  String get customerDisplayName {
    if (customerName.isNotEmpty && customerName != 'Guest Customer') {
      return customerName;
    }
    if (customerPhone.isNotEmpty) {
      return customerPhone;
    }
    return 'Guest Customer';
  }

  // Check if sale has valid customer
  bool get hasValidCustomer => customerId != 'guest' && customerId.isNotEmpty;
  
  // Get customer contact info
  String get customerContact {
    if (customerPhone.isNotEmpty) return customerPhone;
    if (customerEmail != null && customerEmail!.isNotEmpty) return customerEmail!;
    return 'No contact info';
  }

  // Get formatted customer info for receipt
  String get customerInfoForReceipt {
    if (isGuestCustomer) return 'Guest Customer';
    String info = customerName;
    if (customerPhone.isNotEmpty) info += ' | $customerPhone';
    if (customerEmail != null && customerEmail!.isNotEmpty) info += ' | ${customerEmail!}';
    return info;
  }
}