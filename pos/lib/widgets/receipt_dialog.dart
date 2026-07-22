import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/models/product.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ReceiptDialog extends StatelessWidget {
  final List<Product> cartItems;
  final double totalAmount;
  final double totalProfit;
  final String selectedPaymentMethod;
  final String receiptNumber;
  
  // ✅ Customer Info
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final bool isGuestCustomer;

  const ReceiptDialog({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.totalProfit,
    required this.selectedPaymentMethod,
    required this.receiptNumber,
    this.customerName = 'Guest Customer',
    this.customerPhone = '',
    this.customerEmail,
    this.isGuestCustomer = true,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final currencySymbol = settingsProvider.currencySymbol;
    final showProfit = settingsProvider.showProfitInPOS;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.receipt_long,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            'Receipt',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Header
            Text(
              'Receipt #: $receiptNumber',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            
            // ✅ Customer Info Section
            const SizedBox(height: 4),
            if (!isGuestCustomer) ...[
              Text(
                'Customer: $customerName',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (customerPhone.isNotEmpty)
                Text(
                  'Phone: $customerPhone',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              if (customerEmail != null && customerEmail!.isNotEmpty)
                Text(
                  'Email: $customerEmail',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
            ] else
              Text(
                'Customer: Guest',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Items List
            if (cartItems.isEmpty)
              Center(
                child: Text(
                  'No items in receipt',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              )
            else
              ...cartItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} × ${item.stock}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        '$currencySymbol${(item.price * item.stock).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '$currencySymbol${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.green.shade400 : Colors.green,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            
            // Profit (if enabled)
            if (showProfit) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profit:',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$currencySymbol${totalProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            
            // Payment Method
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment:',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  selectedPaymentMethod,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Printing feature coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.print),
          label: const Text('Print'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}