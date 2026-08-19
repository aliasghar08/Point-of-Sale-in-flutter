import 'package:pos/models/product.dart';
import 'package:pos/models/sale.dart';
import 'package:pos/models/customer.dart';
import 'package:pos/services/format_service.dart';

/// In-house CSV & report export engine.
class ExportService {
  ExportService._();

  /// Export products catalog to CSV string
  static String exportProductsToCsv(List<Product> products) {
    final StringBuffer csv = StringBuffer();
    // Header
    csv.writeln(
      'ID,Name,Category,SKU,Barcode,Cost Price,Selling Price,Stock,Min Stock,Unit,Status',
    );

    for (final p in products) {
      csv.writeln(
        [
          _escapeCsv(p.id),
          _escapeCsv(p.name),
          _escapeCsv(p.category),
          _escapeCsv(p.sku),
          _escapeCsv(p.barcode),
          p.costPrice.toStringAsFixed(2),
          p.price.toStringAsFixed(2),
          p.stock.toString(),
          p.minStock.toString(),
          _escapeCsv(p.unit),
          p.isActive ? 'Active' : 'Inactive',
        ].join(','),
      );
    }

    return csv.toString();
  }

  /// Export sales history to CSV string
  static String exportSalesToCsv(List<Sale> sales) {
    final StringBuffer csv = StringBuffer();
    // Header
    csv.writeln(
      'Receipt #,Date,Product Name,Quantity,Unit Price,Total,Profit,Payment Method,Customer Name,Customer Phone',
    );

    for (final s in sales) {
      csv.writeln(
        [
          _escapeCsv(s.receiptNumber),
          _escapeCsv(
            FormatService.formatDateTime(
              s.saleDate,
              format: 'yyyy-MM-dd HH:mm:ss',
            ),
          ),
          _escapeCsv(s.productName),
          s.quantity.toString(),
          s.price.toStringAsFixed(2),
          s.total.toStringAsFixed(2),
          s.profit.toStringAsFixed(2),
          _escapeCsv(s.paymentMethod),
          _escapeCsv(s.customerDisplayName),
          _escapeCsv(s.customerPhone),
        ].join(','),
      );
    }

    return csv.toString();
  }

  /// Export customer CRM directory to CSV string
  static String exportCustomersToCsv(List<Customer> customers) {
    final StringBuffer csv = StringBuffer();
    // Header
    csv.writeln(
      'ID,Name,Phone,Email,Address,Total Orders,Total Spent,Average Order,Last Purchase,Tier',
    );

    for (final c in customers) {
      csv.writeln(
        [
          _escapeCsv(c.id),
          _escapeCsv(c.name),
          _escapeCsv(c.phone),
          _escapeCsv(c.email),
          _escapeCsv(c.address),
          c.totalOrders.toString(),
          c.totalSpent.toStringAsFixed(2),
          c.averageOrderValue.toStringAsFixed(2),
          _escapeCsv(
            FormatService.formatDate(c.lastPurchaseDate, format: 'yyyy-MM-dd'),
          ),
          _escapeCsv(c.customerValueCategory),
        ].join(','),
      );
    }

    return csv.toString();
  }

  static String _escapeCsv(String? value) {
    if (value == null || value.isEmpty) return '""';
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
