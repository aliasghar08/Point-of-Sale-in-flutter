import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final double totalSpent;
  final int totalOrders;
  final double averageOrderValue;
  final DateTime? lastPurchaseDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.totalSpent = 0.0,
    this.totalOrders = 0,
    this.averageOrderValue = 0.0,
    this.lastPurchaseDate,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Helper getters
  String get displayName => name.isNotEmpty ? name : 'Unknown Customer';
  
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String get customerValueCategory {
    if (totalSpent >= 10000) return '🏆 High Value';
    if (totalSpent >= 5000) return '⭐ Medium Value';
    if (totalSpent >= 1000) return '💫 Low Value';
    return '🆕 New Customer';
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    double? totalSpent,
    int? totalOrders,
    double? averageOrderValue,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Convert to Map (if you want to save to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'lastPurchaseDate': lastPurchaseDate != null ? Timestamp.fromDate(lastPurchaseDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  // Factory to create from Map
  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      averageOrderValue: (map['averageOrderValue'] ?? 0.0).toDouble(),
      lastPurchaseDate: (map['lastPurchaseDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}