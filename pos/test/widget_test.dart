import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/cart_item.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/viewmodels/pos_view_model.dart';
import 'package:pos/viewmodels/inventory_view_model.dart';
import 'package:pos/viewmodels/product_form_view_model.dart';
import 'package:provider/provider.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/screens/login_screen.dart';
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

    testWidgets('LoginScreen renders Forgot Password button and opens sheet', (tester) async {
      final authProvider = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
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

  group('ProductFormViewModel Tests', () {
    late ProductFormViewModel formVm;

    setUp(() {
      formVm = ProductFormViewModel();
      formVm.initFromProduct(null);
    });

    test('calculates profit and margin percentage correctly', () {
      formVm.setName('Fresh Milk');
      formVm.setCostPrice(60.0);
      formVm.setSellingPrice(100.0);

      // Profit = 100 - 60 = 40
      expect(formVm.profit, 40.0);
      // Margin = ((100 - 60) / 100) * 100 = 40%
      expect(formVm.marginPercentage, 40.0);
      // Margin > 25% -> healthy
      expect(formVm.marginHealth, MarginHealth.healthy);
    });

    test('evaluates thin margin (1% - 25%) as MarginHealth.low', () {
      formVm.setName('Cheap Candy');
      formVm.setCostPrice(85.0);
      formVm.setSellingPrice(100.0);

      // Profit = 15, Margin = 15%
      expect(formVm.profit, 15.0);
      expect(formVm.marginPercentage, 15.0);
      expect(formVm.marginHealth, MarginHealth.low);
    });

    test('evaluates loss or zero profit as MarginHealth.loss', () {
      formVm.setName('Loss Leader Item');
      formVm.setCostPrice(120.0);
      formVm.setSellingPrice(100.0);

      // Selling below cost
      expect(formVm.profit, -20.0);
      expect(formVm.marginPercentage, -20.0);
      expect(formVm.marginHealth, MarginHealth.loss);

      // Selling at cost
      formVm.setCostPrice(100.0);
      expect(formVm.profit, 0.0);
      expect(formVm.marginPercentage, 0.0);
      expect(formVm.marginHealth, MarginHealth.loss);
    });

    test('handles division by zero and zero cost price gracefully without crash', () {
      formVm.setCostPrice(0.0);
      formVm.setSellingPrice(0.0);

      expect(formVm.profit, 0.0);
      expect(formVm.marginPercentage, 0.0);
      expect(formVm.marginHealth, MarginHealth.loss);

      // Selling price positive, zero cost price (100% markup)
      formVm.setSellingPrice(50.0);
      expect(formVm.profit, 50.0);
      expect(formVm.marginPercentage, 100.0);
      expect(formVm.marginHealth, MarginHealth.healthy);
    });

    test('validates form fields correctly', () {
      // Initially empty -> invalid
      expect(formVm.isValid, false);

      formVm.setName('Basmati Rice 5kg');
      expect(formVm.isValid, false); // selling price still 0

      formVm.setSellingPrice(25.0);
      formVm.setStockQuantity(10);
      expect(formVm.isValid, true);

      // Negative stock quantity is guarded
      formVm.setStockQuantity(-5);
      expect(formVm.stockQuantity, 0); // clamped to 0
      expect(formVm.isValid, true);
    });

    test('barcode bridge auto-fills barcode and SKU when SKU is empty', () {
      expect(formVm.barcode, '');
      expect(formVm.sku, '');

      formVm.onBarcodeScanned('8901234567890');
      expect(formVm.barcode, '8901234567890');
      expect(formVm.sku, '8901234567890');

      // If SKU is already populated, scanning a new barcode updates barcode but preserves SKU
      formVm.setSku('CUSTOM-SKU-99');
      formVm.onBarcodeScanned('777888999');
      expect(formVm.barcode, '777888999');
      expect(formVm.sku, 'CUSTOM-SKU-99');
    });

    test('stepper increments and decrements stock correctly', () {
      formVm.setStockQuantity(5);
      formVm.incrementStock();
      expect(formVm.stockQuantity, 6);

      formVm.decrementStock();
      expect(formVm.stockQuantity, 5);

      // Does not decrement below zero
      formVm.setStockQuantity(0);
      formVm.decrementStock();
      expect(formVm.stockQuantity, 0);
    });

    test('category management adds and selects categories', () {
      formVm.addCategory('Organic Spices');
      expect(formVm.availableCategories.contains('Organic Spices'), true);
      expect(formVm.category, 'Organic Spices');

      formVm.setCategory('Bakery');
      expect(formVm.category, 'Bakery');
    });

    test('initializes correctly from existing Product', () {
      final existing = Product(
        id: 'prod_99',
        name: 'Whole Grain Bread',
        description: 'Nutritious brown bread',
        brand: 'HealthyBake',
        sku: 'BRD-01',
        price: 4.50,
        costPrice: 2.50,
        stock: 18,
        minStock: 4,
        maxStock: 50,
        unit: 'box',
        barcode: '99887766',
        qrCode: '',
        category: 'Bakery',
        imageUrl: 'https://example.com/bread.jpg',
        isActive: true,
        isFeatured: false,
        isDigital: false,
        hasVariants: false,
        createdAt: testDate,
        updatedAt: testDate,
      );

      formVm.initFromProduct(existing);
      expect(formVm.name, 'Whole Grain Bread');
      expect(formVm.sku, 'BRD-01');
      expect(formVm.barcode, '99887766');
      expect(formVm.costPrice, 2.50);
      expect(formVm.sellingPrice, 4.50);
      expect(formVm.profit, 2.00);
      expect(formVm.unit, 'box');
      expect(formVm.stockQuantity, 18);
      expect(formVm.minStockAlert, 4);
      expect(formVm.category, 'Bakery');
      expect(formVm.imageUrl, 'https://example.com/bread.jpg');
      expect(formVm.isValid, true);
    });
  });
}

