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
    );
  }
}