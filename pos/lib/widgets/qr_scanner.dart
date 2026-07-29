import 'package:flutter/material.dart';
import 'barcode_scanner.dart';

class QRScanner extends StatelessWidget {
  final Function(String) onScan;

  const QRScanner({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return BarcodeScanner(
      onScan: onScan,
      title: 'Scan QR Code',
      hintText: 'Align QR code inside the frame to scan',
      expectedType: ScannerExpectedType.qrCode,
    );
  }
}