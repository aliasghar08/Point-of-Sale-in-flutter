import 'package:pos/models/cart_item.dart';

/// Represents a parked / suspended order in the POS system.
class HeldOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final List<CartItem> items;
  final DateTime heldAt;
  final String note;
  final double discountPercent;
  final double discountAmount;

  HeldOrder({
    required this.id,
    this.customerId = 'guest',
    this.customerName = 'Guest Customer',
    this.customerPhone,
    required this.items,
    required this.heldAt,
    this.note = '',
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
  });

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.total);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
