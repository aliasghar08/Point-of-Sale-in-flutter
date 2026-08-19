import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';

/// Service to seed rich sample inventory items into the POS system for demo / testing.
class SampleDataService {
  SampleDataService._();

  static List<Map<String, dynamic>> get sampleProducts => [
    // Groceries & Beverages
    {
      'name': 'Organic Whole Milk 1L',
      'category': 'Groceries',
      'price': 3.50,
      'costPrice': 2.20,
      'stock': 45,
      'minStock': 10,
      'unit': 'liters',
      'sku': 'GROC-MILK-01',
      'barcode': '1000000000018',
      'description': 'Farm fresh organic whole pasteurized milk',
    },
    {
      'name': 'Artisan Sourdough Bread',
      'category': 'Bakery',
      'price': 4.75,
      'costPrice': 2.00,
      'stock': 20,
      'minStock': 5,
      'unit': 'pcs',
      'sku': 'BAK-SOUR-02',
      'barcode': '1000000000025',
      'description': 'Crispy crust artisan baked sourdough',
    },
    {
      'name': 'Single Origin Arabica Coffee Beans (250g)',
      'category': 'Beverages',
      'price': 12.50,
      'costPrice': 7.00,
      'stock': 30,
      'minStock': 8,
      'unit': 'g',
      'sku': 'BEV-COFF-03',
      'barcode': '1000000000032',
      'description': 'Medium roast specialty Ethiopian beans',
    },
    {
      'name': 'Mineral Sparkling Water 500ml',
      'category': 'Beverages',
      'price': 1.80,
      'costPrice': 0.80,
      'stock': 60,
      'minStock': 15,
      'unit': 'pcs',
      'sku': 'BEV-WTR-04',
      'barcode': '1000000000049',
      'description': 'Natural sparkling mineral water in glass bottle',
    },
    {
      'name': 'Dark Chocolate 85% Cacao',
      'category': 'Snacks',
      'price': 3.99,
      'costPrice': 1.90,
      'stock': 50,
      'minStock': 10,
      'unit': 'pcs',
      'sku': 'SNK-CHOC-05',
      'barcode': '1000000000056',
      'description': 'Swiss crafted rich dark chocolate bar',
    },

    // Electronics & Accessories
    {
      'name': 'USB-C Fast Charging Cable (2m Braided)',
      'category': 'Electronics',
      'price': 14.99,
      'costPrice': 4.50,
      'stock': 35,
      'minStock': 10,
      'unit': 'pcs',
      'sku': 'ELEC-USBC-06',
      'barcode': '1000000000063',
      'description': '60W PD durable nylon braided cable',
    },
    {
      'name': 'Wireless Bluetooth Earbuds Pro',
      'category': 'Electronics',
      'price': 49.99,
      'costPrice': 22.00,
      'stock': 18,
      'minStock': 5,
      'unit': 'pcs',
      'sku': 'ELEC-EARB-07',
      'barcode': '1000000000070',
      'description': 'Noise cancelling earbuds with 24h battery case',
    },
    {
      'name': 'Magnetic Phone Car Mount',
      'category': 'Electronics',
      'price': 16.50,
      'costPrice': 6.00,
      'stock': 25,
      'minStock': 5,
      'unit': 'pcs',
      'sku': 'ELEC-MOUNT-08',
      'barcode': '1000000000087',
      'description': 'Universal 360 degree air vent car mount',
    },

    // Fashion & Apparel
    {
      'name': 'Classic Heavyweight Cotton T-Shirt (M)',
      'category': 'Apparel',
      'price': 22.00,
      'costPrice': 9.00,
      'stock': 40,
      'minStock': 10,
      'unit': 'pcs',
      'sku': 'APP-TSHIRT-09',
      'barcode': '1000000000094',
      'description': '100% combed cotton regular fit unisex tee',
    },
    {
      'name': 'Canvas Daily Tote Bag',
      'category': 'Apparel',
      'price': 15.00,
      'costPrice': 5.00,
      'stock': 30,
      'minStock': 8,
      'unit': 'pcs',
      'sku': 'APP-TOTE-10',
      'barcode': '1000000000100',
      'description': 'Eco-friendly heavy duty cotton canvas tote',
    },

    // Cafe & Ready To Eat
    {
      'name': 'Fresh Butter Croissant',
      'category': 'Bakery',
      'price': 3.25,
      'costPrice': 1.10,
      'stock': 25,
      'minStock': 5,
      'unit': 'pcs',
      'sku': 'BAK-CROIS-11',
      'barcode': '1000000000117',
      'description': 'Flaky golden French butter croissant',
    },
    {
      'name': 'Organic Green Tea (20 bags)',
      'category': 'Beverages',
      'price': 6.50,
      'costPrice': 3.00,
      'stock': 4, // Low stock demo!
      'minStock': 10,
      'unit': 'pcs',
      'sku': 'BEV-TEA-12',
      'barcode': '1000000000124',
      'description': 'Pure Japanese Sencha green tea sachets',
    },
  ];

  /// Seed sample products into the active business Firestore collection
  static Future<int> seedSampleProducts() async {
    final firebaseService = FirebaseService();
    final businessId = await firebaseService.getCurrentBusinessId();
    if (businessId == null)
      throw Exception(
        'No business active. Please create or join a business first.',
      );

    int count = 0;
    final batch = FirebaseFirestore.instance.batch();
    final productsCollection = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('products');

    final now = DateTime.now();

    for (final item in sampleProducts) {
      final docRef = productsCollection.doc();
      final product = Product(
        id: docRef.id,
        name: item['name'],
        category: item['category'],
        price: (item['price'] as num).toDouble(),
        costPrice: (item['costPrice'] as num).toDouble(),
        stock: (item['stock'] as num).toInt(),
        minStock: (item['minStock'] as num).toInt(),
        unit: item['unit'],
        sku: item['sku'],
        barcode: item['barcode'],
        description: item['description'],
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      batch.set(docRef, product.toMap());
      CacheService().upsertProduct(product);
      count++;
    }

    await batch.commit();
    return count;
  }
}
