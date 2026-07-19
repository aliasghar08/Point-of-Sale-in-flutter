import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  // ===== BASIC INFORMATION =====
  final String id;
  final String name;
  final String description;
  final String brand;
  final String sku;
  
  // ===== PRICING =====
  final double price;
  final double costPrice;
  final double? salePrice;
  final double? wholesalePrice;
  
  // ===== STOCK & INVENTORY =====
  final int stock;
  final int minStock;
  final int maxStock;
  final String unit; // 'pcs', 'kg', 'g', 'liters', 'meters', etc.
  final double? weight; // Weight in kg or g
  final String? weightUnit; // 'kg', 'g', 'lbs', 'oz'
  final int? reorderPoint;
  final int? reorderQuantity;
  
  // ===== EXPIRY & DATES =====
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final DateTime? bestBeforeDate;
  
  // ===== IDENTIFICATION =====
  final String barcode;
  final String qrCode;
  
  // ===== CATEGORIZATION =====
  final String category;
  final String? subCategory;
  final String? taxClass;
  
  // ===== SUPPLIER =====
  final String? supplierId;
  final String? supplierName;
  final String? supplierSku;
  
  // ===== MEDIA =====
  final String imageUrl;
  final List<String>? additionalImages;
  
  // ===== STATUS =====
  final bool isActive;
  final bool isFeatured;
  final bool isDigital;
  final bool hasVariants;
  
  // ===== TIMESTAMPS =====
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    this.brand = '',
    this.sku = '',
    required this.price,
    required this.costPrice,
    this.salePrice,
    this.wholesalePrice,
    required this.stock,
    required this.minStock,
    this.maxStock = 0,
    this.unit = 'pcs',
    this.weight,
    this.weightUnit,
    this.reorderPoint,
    this.reorderQuantity,
    this.manufactureDate,
    this.expiryDate,
    this.bestBeforeDate,
    this.barcode = '',
    this.qrCode = '',
    this.category = 'Uncategorized',
    this.subCategory,
    this.taxClass,
    this.supplierId,
    this.supplierName,
    this.supplierSku,
    this.imageUrl = '',
    this.additionalImages,
    this.isActive = true,
    this.isFeatured = false,
    this.isDigital = false,
    this.hasVariants = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===== COMPUTED PROPERTIES =====
  double get profit => price - costPrice;
  double get profitMargin => costPrice > 0 ? ((price - costPrice) / price) * 100 : 0;
  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon => expiryDate != null && expiryDate!.difference(DateTime.now()).inDays <= 30;
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'brand': brand,
      'sku': sku,
      'price': price,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'wholesalePrice': wholesalePrice,
      'stock': stock,
      'minStock': minStock,
      'maxStock': maxStock,
      'unit': unit,
      'weight': weight,
      'weightUnit': weightUnit,
      'reorderPoint': reorderPoint,
      'reorderQuantity': reorderQuantity,
      'manufactureDate': manufactureDate,
      'expiryDate': expiryDate,
      'bestBeforeDate': bestBeforeDate,
      'barcode': barcode,
      'qrCode': qrCode,
      'category': category,
      'subCategory': subCategory,
      'taxClass': taxClass,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierSku': supplierSku,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isDigital': isDigital,
      'hasVariants': hasVariants,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      sku: map['sku'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      salePrice: map['salePrice']?.toDouble(),
      wholesalePrice: map['wholesalePrice']?.toDouble(),
      stock: map['stock']?.toInt() ?? 0,
      minStock: map['minStock']?.toInt() ?? 0,
      maxStock: map['maxStock']?.toInt() ?? 0,
      unit: map['unit'] ?? 'pcs',
      weight: map['weight']?.toDouble(),
      weightUnit: map['weightUnit'],
      reorderPoint: map['reorderPoint']?.toInt(),
      reorderQuantity: map['reorderQuantity']?.toInt(),
      manufactureDate: (map['manufactureDate'] as Timestamp?)?.toDate(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      bestBeforeDate: (map['bestBeforeDate'] as Timestamp?)?.toDate(),
      barcode: map['barcode'] ?? '',
      qrCode: map['qrCode'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      subCategory: map['subCategory'],
      taxClass: map['taxClass'],
      supplierId: map['supplierId'],
      supplierName: map['supplierName'],
      supplierSku: map['supplierSku'],
      imageUrl: map['imageUrl'] ?? '',
      additionalImages: map['additionalImages'] != null 
          ? List<String>.from(map['additionalImages']) 
          : null,
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isDigital: map['isDigital'] ?? false,
      hasVariants: map['hasVariants'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? brand,
    String? sku,
    double? price,
    double? costPrice,
    double? salePrice,
    double? wholesalePrice,
    int? stock,
    int? minStock,
    int? maxStock,
    String? unit,
    double? weight,
    String? weightUnit,
    int? reorderPoint,
    int? reorderQuantity,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    DateTime? bestBeforeDate,
    String? barcode,
    String? qrCode,
    String? category,
    String? subCategory,
    String? taxClass,
    String? supplierId,
    String? supplierName,
    String? supplierSku,
    String? imageUrl,
    List<String>? additionalImages,
    bool? isActive,
    bool? isFeatured,
    bool? isDigital,
    bool? hasVariants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      bestBeforeDate: bestBeforeDate ?? this.bestBeforeDate,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      taxClass: taxClass ?? this.taxClass,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierSku: supplierSku ?? this.supplierSku,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isDigital: isDigital ?? this.isDigital,
      hasVariants: hasVariants ?? this.hasVariants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}