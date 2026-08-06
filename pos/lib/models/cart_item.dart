import 'package:pos/models/product.dart';

/// Clean Cart Item model for the POS checkout system.
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final double unitPrice;
  final double costPrice;
  int quantity;
  final int maxStock;
  final String unit;
  double discountPercent;
  double discountAmount;
  String note;
  final bool isCustomItem;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    this.sku = '',
    this.barcode = '',
    this.category = 'General',
    required this.unitPrice,
    required this.costPrice,
    this.quantity = 1,
    this.maxStock = 9999,
    this.unit = 'pcs',
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.note = '',
    this.isCustomItem = false,
  });

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      id: product.id,
      productId: product.id,
      name: product.name,
      sku: product.sku,
      barcode: product.barcode,
      category: product.category,
      unitPrice: product.salePrice ?? product.price,
      costPrice: product.costPrice,
      quantity: quantity,
      maxStock: product.stock,
      unit: product.unit,
    );
  }

  factory CartItem.custom({
    required String name,
    required double price,
    int quantity = 1,
  }) {
    final uid = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    return CartItem(
      id: uid,
      productId: uid,
      name: name,
      unitPrice: price,
      costPrice: 0.0,
      quantity: quantity,
      isCustomItem: true,
    );
  }

  // Calculation getters
  double get subtotal => unitPrice * quantity;

  double get calculatedDiscount {
    if (discountAmount > 0) return discountAmount;
    if (discountPercent > 0) return subtotal * (discountPercent / 100);
    return 0.0;
  }

  double get total => (subtotal - calculatedDiscount).clamp(0.0, double.infinity);

  double get profit => total - (costPrice * quantity);

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    double? unitPrice,
    double? costPrice,
    int? quantity,
    int? maxStock,
    String? unit,
    double? discountPercent,
    double? discountAmount,
    String? note,
    bool? isCustomItem,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
      unit: unit ?? this.unit,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      note: note ?? this.note,
      isCustomItem: isCustomItem ?? this.isCustomItem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
      'quantity': quantity,
      'maxStock': maxStock,
      'unit': unit,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'note': note,
      'isCustomItem': isCustomItem,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'] ?? '',
      category: map['category'] ?? 'General',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      maxStock: (map['maxStock'] as num?)?.toInt() ?? 9999,
      unit: map['unit'] ?? 'pcs',
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] ?? '',
      isCustomItem: map['isCustomItem'] ?? false,
    );
  }
}
