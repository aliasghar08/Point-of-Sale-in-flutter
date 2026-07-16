import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Products Collection
  CollectionReference get products => firestore.collection('products');
  
  // Sales Collection
  CollectionReference get sales => firestore.collection('sales');

  // Add Product
  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      DocumentReference docRef = await products.add(productData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update Product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await products.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete Product
  Future<void> deleteProduct(String id) async {
    try {
      await products.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get Product by Barcode
  Future<QuerySnapshot> getProductByBarcode(String barcode) async {
    try {
      return await products.where('barcode', isEqualTo: barcode).get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Get Product by QR Code
  Future<QuerySnapshot> getProductByQRCode(String qrCode) async {
    try {
      return await products.where('qrCode', isEqualTo: qrCode).get();
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Add Sale
  Future<String> addSale(Map<String, dynamic> saleData) async {
    try {
      DocumentReference docRef = await sales.add(saleData);
      
      // Update product stock
      await updateProductStock(
        saleData['productId'], 
        -saleData['quantity']
      );
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add sale: $e');
    }
  }

  // Update Product Stock
  Future<void> updateProductStock(String productId, int quantityChange) async {
    try {
      await products.doc(productId).update({
        'stock': FieldValue.increment(quantityChange),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Get Daily Sales
  Future<QuerySnapshot> getDailySales(DateTime date) async {
    try {
      DateTime start = DateTime(date.year, date.month, date.day);
      DateTime end = start.add(Duration(days: 1));
      
      return await sales
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .get();
    } catch (e) {
      throw Exception('Failed to get daily sales: $e');
    }
  }

  // Get Monthly Sales
  Future<QuerySnapshot> getMonthlySales(DateTime date) async {
    try {
      DateTime start = DateTime(date.year, date.month, 1);
      DateTime end = DateTime(date.year, date.month + 1, 1);
      
      return await sales
          .where('saleDate', isGreaterThanOrEqualTo: start)
          .where('saleDate', isLessThan: end)
          .get();
    } catch (e) {
      throw Exception('Failed to get monthly sales: $e');
    }
  }

  // Get Sales Summary
  Future<Map<String, dynamic>> getSalesSummary(DateTime date) async {
    try {
      QuerySnapshot dailySales = await getDailySales(date);
      
      double totalSales = 0;
      double totalProfit = 0;
      int totalItems = 0;
      
      for (var doc in dailySales.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalSales += (data['total'] ?? 0).toDouble();
        totalProfit += (data['profit'] ?? 0).toDouble();
        totalItems += (data['quantity'] ?? 0).toInt() as int;
      }
      
      return {
        'totalSales': totalSales,
        'totalProfit': totalProfit,
        'totalItems': totalItems,
        'transactionCount': dailySales.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get sales summary: $e');
    }
  }

  // Get Low Stock Products
  Future<QuerySnapshot> getLowStockProducts(int threshold) async {
    try {
      return await products
          .where('stock', isLessThanOrEqualTo: threshold)
          .get();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }
}