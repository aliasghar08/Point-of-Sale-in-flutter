import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/cart_item.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/viewmodels/pos_view_model.dart';
import 'package:pos/viewmodels/inventory_view_model.dart';
import 'package:pos/widgets/stat_badge.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/staggered_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final testDate = DateTime(2025, 1, 1);

  group('CartItem Model Tests', () {
    test('calculates correct fields from custom item', () {
      final item = CartItem.custom(
        name: 'Custom Service',
        price: 50.0,
        quantity: 2,
      );

      expect(item.name, 'Custom Service');
      expect(item.unitPrice, 50.0);
      expect(item.costPrice, 0.0);
      expect(item.quantity, 2);
      expect(item.isCustomItem, true);
    });

    test('creates CartItem from Product correctly', () {
      final product = Product(
        id: 'prod_1',
        name: 'Wireless Mouse',
        description: 'Ergonomic optical mouse',
        brand: 'Logi',
        sku: 'MS-100',
        price: 25.0,
        costPrice: 15.0,
        stock: 50,
        minStock: 5,
        maxStock: 100,
        unit: 'pcs',
        barcode: '1234567890',
        qrCode: '',
        category: 'Electronics',
        imageUrl: '',
        isActive: true,
        isFeatured: false,
        isDigital: false,
        hasVariants: false,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final cartItem = CartItem.fromProduct(product, quantity: 3);
      expect(cartItem.id, 'prod_1');
      expect(cartItem.name, 'Wireless Mouse');
      expect(cartItem.unitPrice, 25.0);
      expect(cartItem.costPrice, 15.0);
      expect(cartItem.quantity, 3);
      expect(cartItem.maxStock, 50);
    });
  });

  group('PosViewModel Calculations', () {
    late PosViewModel vm;
    late Product sampleProduct1;
    late Product sampleProduct2;

    setUp(() {
      vm = PosViewModel();
      sampleProduct1 = Product(
        id: 'p1',
        name: 'Coffee Mug',
        description: 'Ceramic mug',
        brand: 'Home',
        sku: 'MUG-1',
        price: 10.0,
        costPrice: 4.0,
        stock: 20,
        minStock: 2,
        maxStock: 100,
        unit: 'pcs',
        barcode: '111111',
        qrCode: '',
        category: 'Kitchen',
        imageUrl: '',
        isActive: true,
        isFeatured: false,
        isDigital: false,
        hasVariants: false,
        createdAt: testDate,
        updatedAt: testDate,
      );
      sampleProduct2 = Product(
        id: 'p2',
        name: 'Tea Bag Box',
        description: 'Black tea',
        brand: 'Twinings',
        sku: 'TEA-1',
        price: 5.0,
        costPrice: 2.0,
        stock: 30,
        minStock: 5,
        maxStock: 100,
        unit: 'pcs',
        barcode: '222222',
        qrCode: '',
        category: 'Groceries',
        imageUrl: '',
        isActive: true,
        isFeatured: false,
        isDigital: false,
        hasVariants: false,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    test('adds items and calculates subtotal accurately', () {
      vm.addToCart(sampleProduct1); // 1 x $10
      vm.addToCart(sampleProduct1); // 2 x $10 = $20
      vm.addToCart(sampleProduct2); // 1 x $5 = $5

      expect(vm.totalItemCount, 3);
      expect(vm.subtotal, 25.0);
      expect(vm.grandTotal, 25.0);
      expect(vm.totalDiscount, 0.0);
      // Profit: (20 - 8) + (5 - 2) = 12 + 3 = 15.0
      expect(vm.totalProfit, 15.0);
    });

    test('applies percentage and fixed order discounts correctly', () {
      vm.addToCart(sampleProduct1); // 1 x 10 = 10
      vm.addToCart(sampleProduct1); // 2 x 10 = 20

      // 10% order discount
      vm.applyOrderDiscount(discount: 10.0, isPercent: true);
      expect(vm.totalDiscount, 2.0);
      expect(vm.grandTotal, 18.0);

      // Fixed order discount ($5)
      vm.applyOrderDiscount(discount: 5.0, isPercent: false);
      expect(vm.totalDiscount, 5.0);
      expect(vm.grandTotal, 15.0);
    });

    test('applies line-item discount correctly', () {
      vm.addToCart(sampleProduct1); // Item 0: qty 1, price 10
      vm.applyItemDiscount(0, discount: 20.0, isPercent: true); // 20% of 10 = 2.0
      expect(vm.totalDiscount, 2.0);
      expect(vm.grandTotal, 8.0);
    });

    test('increments, decrements, and clears cart', () {
      vm.addToCart(sampleProduct1);
      expect(vm.cart.length, 1);
      expect(vm.cart[0].quantity, 1);

      vm.incrementQty(0);
      expect(vm.cart[0].quantity, 2);

      vm.decrementQty(0);
      expect(vm.cart[0].quantity, 1);

      vm.decrementQty(0);
      expect(vm.isCartEmpty, true);

      vm.addToCart(sampleProduct2);
      expect(vm.isCartEmpty, false);
      vm.clearCart();
      expect(vm.isCartEmpty, true);
    });
  });

  group('InventoryViewModel Filtering Tests', () {
    late InventoryViewModel invVm;
    late List<Product> catalog;

    setUp(() {
      invVm = InventoryViewModel();
      catalog = [
        Product(
          id: 'p1',
          name: 'Organic Apples',
          description: '',
          brand: 'FreshFarm',
          sku: 'APL-01',
          price: 3.5,
          costPrice: 2.0,
          stock: 25,
          minStock: 10,
          maxStock: 100,
          unit: 'kg',
          barcode: '990001',
          qrCode: '',
          category: 'Fruits',
          imageUrl: '',
          isActive: true,
          isFeatured: false,
          isDigital: false,
          hasVariants: false,
          createdAt: testDate,
          updatedAt: testDate,
        ),
        Product(
          id: 'p2',
          name: 'Dark Chocolate Bar',
          description: '',
          brand: 'Lindt',
          sku: 'CHO-99',
          price: 4.0,
          costPrice: 2.5,
          stock: 3,
          minStock: 5, // Low stock
          maxStock: 50,
          unit: 'pcs',
          barcode: '990002',
          qrCode: '',
          category: 'Snacks',
          imageUrl: '',
          isActive: true,
          isFeatured: false,
          isDigital: false,
          hasVariants: false,
          createdAt: testDate,
          updatedAt: testDate,
        ),
        Product(
          id: 'p3',
          name: 'Espresso Beans',
          description: '',
          brand: 'Lavazza',
          sku: 'COF-10',
          price: 15.0,
          costPrice: 9.0,
          stock: 0, // Out of stock
          minStock: 5,
          maxStock: 50,
          unit: 'pack',
          barcode: '990003',
          qrCode: '',
          category: 'Beverages',
          imageUrl: '',
          isActive: true,
          isFeatured: false,
          isDigital: false,
          hasVariants: false,
          createdAt: testDate,
          updatedAt: testDate,
        ),
      ];
    });

    test('filters products by category', () {
      invVm.setCategory('Fruits');
      final filtered = invVm.filterProducts(catalog);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Organic Apples');
    });

    test('filters products by low stock', () {
      invVm.setStockFilter('low');
      final filtered = invVm.filterProducts(catalog);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Dark Chocolate Bar');
    });

    test('filters products by out of stock', () {
      invVm.setStockFilter('out');
      final filtered = invVm.filterProducts(catalog);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Espresso Beans');
    });
  });

  group('UI Widget Smoke Tests', () {
    testWidgets('StatBadge renders stock states correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatBadge.stock(stock: 15, minStock: 5),
                StatBadge.stock(stock: 3, minStock: 5),
                StatBadge.stock(stock: 0, minStock: 5),
              ],
            ),
          ),
        ),
      );

      expect(find.text('In Stock (15)'), findsOneWidget);
      expect(find.text('Low Stock (3)'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('PosCard renders child and responds to interactions', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosCard(
              onTap: () => tapped = true,
              child: const Text('Register Item'),
            ),
          ),
        ),
      );

      expect(find.text('Register Item'), findsOneWidget);
      await tester.tap(find.text('Register Item'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('StaggeredSlideFade renders child correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredSlideFade(
              index: 0,
              child: Text('Animated Card'),
            ),
          ),
        ),
      );

      expect(find.text('Animated Card'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('Customer Model Tests', () {
    test('calculates initials, value category, and loyalty points correctly', () {
      final customer = Customer(
        id: 'cust_101',
        name: 'Sarah Connor',
        email: 'sarah@example.com',
        phone: '+123456789',
        address: '100 Main St',
        totalSpent: 12500.0,
        totalOrders: 25,
        averageOrderValue: 500.0,
        createdAt: DateTime.now(),
      );

      expect(customer.initials, 'SC');
      expect(customer.customerValueCategory, '🏆 High Value');
      expect(customer.loyaltyPoints, 1250);
      expect(customer.displayName, 'Sarah Connor');
    });
  });
}
