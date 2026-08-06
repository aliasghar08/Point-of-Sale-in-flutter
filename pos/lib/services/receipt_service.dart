import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pos/services/format_service.dart';

/// In-house thermal receipt rendering and printing service.
class ReceiptService {
  ReceiptService._();

  /// Generates a PDF receipt document optimized for 80mm/58mm thermal printers
  static Future<pw.Document> generatePdfReceipt({
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? taxNumber,
    required String receiptNumber,
    required DateTime date,
    required String cashierName,
    required String customerName,
    required List<Map<String, dynamic>> items, // {name, qty, price, total}
    required double subtotal,
    required double tax,
    required double discount,
    required double grandTotal,
    required String paymentMethod,
    double? cashTendered,
    double? changeDue,
    required String currencySymbol,
    String? footerMessage,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Business Header
              pw.Text(
                businessName.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
              if (businessAddress != null && businessAddress.isNotEmpty)
                pw.Text(businessAddress, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
              if (businessPhone != null && businessPhone.isNotEmpty)
                pw.Text('Tel: $businessPhone', style: const pw.TextStyle(fontSize: 8)),
              if (taxNumber != null && taxNumber.isNotEmpty)
                pw.Text('Tax Reg: $taxNumber', style: const pw.TextStyle(fontSize: 8)),
              
              pw.Divider(thickness: 0.5, height: 12),

              // Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #: $receiptNumber', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(FormatService.formatDate(date, format: 'dd/MM/yyyy HH:mm'), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier: $cashierName', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Customer: $customerName', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),

              pw.Divider(thickness: 0.5, height: 10),

              // Items Table Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Divider(thickness: 0.5, height: 6),

              // Item Lines
              ...items.map((item) {
                final qty = item['qty'] ?? 1;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final total = (item['total'] as num?)?.toDouble() ?? (qty * price);
                final name = (item['name'] ?? '').toString();

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 5, child: pw.Text(name, style: const pw.TextStyle(fontSize: 8))),
                      pw.Expanded(flex: 2, child: pw.Text('$qty', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Expanded(flex: 3, child: pw.Text(FormatService.formatCurrency(price, symbol: currencySymbol), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Expanded(flex: 3, child: pw.Text(FormatService.formatCurrency(total, symbol: currencySymbol), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.5, height: 10),

              // Totals Section
              _buildPdfSummaryRow('Subtotal:', FormatService.formatCurrency(subtotal, symbol: currencySymbol)),
              if (discount > 0)
                _buildPdfSummaryRow('Discount:', '-${FormatService.formatCurrency(discount, symbol: currencySymbol)}'),
              if (tax > 0)
                _buildPdfSummaryRow('Tax:', FormatService.formatCurrency(tax, symbol: currencySymbol)),
              
              pw.Divider(thickness: 1, height: 8),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL DUE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    FormatService.formatCurrency(grandTotal, symbol: currencySymbol),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),
              _buildPdfSummaryRow('Payment Method:', paymentMethod),
              if (cashTendered != null && cashTendered > 0) ...[
                _buildPdfSummaryRow('Cash Tendered:', FormatService.formatCurrency(cashTendered, symbol: currencySymbol)),
                _buildPdfSummaryRow('Change Due:', FormatService.formatCurrency(changeDue ?? 0.0, symbol: currencySymbol)),
              ],

              pw.Divider(thickness: 0.5, height: 12),

              // Footer & Barcode
              pw.BarcodeWidget(
                data: receiptNumber,
                barcode: pw.Barcode.code128(),
                width: 140,
                height: 35,
                drawText: true,
              ),

              pw.SizedBox(height: 8),
              pw.Text(
                footerMessage ?? 'Thank you for your business!\nPlease visit again.',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  /// Print or show print dialog directly
  static Future<void> printReceipt(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'POS_Receipt',
    );
  }
}
