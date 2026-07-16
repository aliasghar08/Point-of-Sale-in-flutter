import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String barcode;
  final String qrCode;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String category;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.barcode = '',
    this.qrCode = '',
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    this.category = 'Uncategorized',
    this.imageUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  double get profit => price - costPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'qrCode': qrCode,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'minStock': minStock,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      qrCode: map['qrCode'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      stock: map['stock']?.toInt() ?? 0,
      minStock: map['minStock']?.toInt() ?? 0,
      category: map['category'] ?? 'Uncategorized',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    String? qrCode,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}