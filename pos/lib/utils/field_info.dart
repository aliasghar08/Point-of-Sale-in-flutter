import 'package:flutter/material.dart';

class FieldInfo {
  final String title;
  final String description;
  final String example;
  final String? required;

  const FieldInfo({
    required this.title,
    required this.description,
    required this.example,
    this.required,
  });

  // ===== BASIC INFORMATION FIELDS =====
  static const productName = FieldInfo(
    title: 'Product Name',
    description:
        'The unique name or title of your product. This is how customers and staff will identify the product in searches, receipts, and inventory reports.',
    example: 'iPhone 15 Pro Max, Paracetamol 500mg, Organic Basmati Rice',
    required: '⚠️ Required Field',
  );

  static const descriptionField = FieldInfo(
    title: 'Description',
    description:
        'Detailed information about the product including features, specifications, ingredients, usage instructions, or any other relevant details that help customers make informed decisions.',
    example:
        '5G smartphone with 6.7-inch OLED display, 48MP camera, 256GB storage, and all-day battery life.',
  );

  static const brand = FieldInfo(
    title: 'Brand',
    description:
        'The manufacturer or brand name of the product. Helps with brand-specific searches, categorization, and customer recognition.',
    example: 'Apple, Samsung, Nestlé, Adidas, Sony, Nike',
  );

  static const sku = FieldInfo(
    title: 'SKU (Stock Keeping Unit)',
    description:
        'A unique internal code used to track inventory. SKUs help you manage stock levels, identify products in your system, and streamline order fulfillment.',
    example: 'PHN-IP15-PM-256, MED-PCM-500, FOD-BSM-10',
  );

  // ===== PRICING & STOCK FIELDS =====
  static const sellingPrice = FieldInfo(
    title: 'Selling Price',
    description:
        'The retail price customers pay when purchasing this product. This determines your revenue from each sale and should cover your costs plus desired profit margin.',
    example: '\$999.99, ₹79,999, \$5.99',
    required: '⚠️ Required Field',
  );

  static const costPrice = FieldInfo(
    title: 'Cost Price',
    description:
        'The wholesale or purchase price you paid to acquire the product. This is used to calculate your profit margin (Selling Price - Cost Price).',
    example: '\$750.00, ₹65,000, \$3.50',
    required: '⚠️ Required Field',
  );

  static const salePrice = FieldInfo(
    title: 'Sale Price',
    description:
        'A discounted price for promotions, seasonal sales, clearance events, or special offers. When set, this price overrides the regular selling price.',
    example: '\$899.99 (regular price \$999.99)',
  );

  static const wholesalePrice = FieldInfo(
    title: 'Wholesale Price',
    description:
        'Special pricing for bulk purchases or business customers. Used when selling large quantities at a discounted rate to retailers or bulk buyers.',
    example: '\$850.00 (when buying 10+ units)',
  );

  static const stockQuantity = FieldInfo(
    title: 'Stock Quantity',
    description:
        'The current number of units available for sale. This helps you track inventory levels, know when to reorder, and prevent overselling.',
    example: '150, 25, 3',
    required: '⚠️ Required Field',
  );

  static const minStockAlert = FieldInfo(
    title: 'Minimum Stock Alert',
    description:
        'The minimum quantity that triggers a low-stock notification. When stock falls below this number, you\'ll receive an alert to reorder and avoid stockouts.',
    example: '10 (alert when stock reaches 10 units)',
    required: '⚠️ Required Field',
  );

  static const maxStock = FieldInfo(
    title: 'Maximum Stock',
    description:
        'The maximum quantity you want to keep in inventory. Helps with warehouse space planning, prevents overstocking, and manages cash flow.',
    example: '500 (don\'t stock more than 500 units)',
  );

  static const unit = FieldInfo(
    title: 'Unit',
    description:
        'The measurement unit for counting or measuring the product. Choose from pieces, weight, volume, or quantity units that best describe how the product is sold.',
    example:
        'pcs (Pieces), kg (Kilograms), l (Liters), box (Box), dozen (Dozen), pack (Pack)',
    required: '⚠️ Required Field',
  );

  static const weight = FieldInfo(
    title: 'Weight',
    description:
        'The physical weight of a single unit of the product. Used for shipping calculations, handling costs, and courier fee estimation.',
    example: '0.5, 2.5, 10 (depends on weight unit selected)',
  );

  static const weightUnit = FieldInfo(
    title: 'Weight Unit',
    description:
        'The measurement system for the product\'s weight. Choose between metric (kg, g) or imperial (lbs, oz) units based on your preference.',
    example: 'kg (Kilograms), g (Grams), lbs (Pounds), oz (Ounces)',
  );

  // ===== EXPIRY & DATES FIELDS =====
  static const manufactureDate = FieldInfo(
    title: 'Manufacture Date',
    description:
        'The date when the product was manufactured or produced. Important for batch tracking, quality control, and identifying production runs.',
    example: '01/01/2024',
  );

  static const expiryDate = FieldInfo(
    title: 'Expiry Date',
    description:
        'The date when the product expires and should not be sold. Critical for medicines, food, beverages, and perishable items. Helps ensure product safety.',
    example: '01/01/2026',
  );

  static const bestBeforeDate = FieldInfo(
    title: 'Best Before Date',
    description:
        'The date by which the product is at its best quality. After this date, quality may decline but the product may still be safe to use (unlike expiry date).',
    example: '01/06/2024',
  );

  // ===== ADDITIONAL DETAILS FIELDS =====
  static const barcode = FieldInfo(
    title: 'Barcode',
    description:
        'A scannable code (UPC/EAN) printed on product packaging. Used for quick product lookup, inventory management, and checkout speed.',
    example: '8901234567890',
  );

  static const qrCode = FieldInfo(
    title: 'QR Code',
    description:
        'A Quick Response code that contains product information. An alternative to barcodes for product identification and can store more data.',
    example: 'https://product.com/12345',
  );

  static const category = FieldInfo(
    title: 'Category',
    description:
        'The main classification or department for the product. Helps organize products, enable category-specific searches, and generate departmental reports.',
    example: 'Electronics, Medicines, Food & Beverages, Clothing, Books',
    required: '⚠️ Required Field',
  );

  static const subCategory = FieldInfo(
    title: 'Sub Category',
    description:
        'A more specific classification within the main category. Provides finer product organization and more detailed reporting capabilities.',
    example:
        'Smartphones (under Electronics), Pain Relief (under Medicines), Dairy (under Food & Beverages)',
  );

  static const taxClass = FieldInfo(
    title: 'Tax Class',
    description:
        'The tax rate or tax exemption status applied to this product. Determines how much tax is charged on sales.',
    example: 'Standard (18%), Reduced (5%), Zero (0%), Exempt',
  );

  static const reorderPoint = FieldInfo(
    title: 'Reorder Point',
    description:
        'The stock level that automatically triggers a reorder notification. Helps maintain optimal inventory levels and prevent stockouts.',
    example: '15 (reorder when stock reaches 15)',
  );

  static const reorderQuantity = FieldInfo(
    title: 'Reorder Quantity',
    description:
        'The quantity to order when a reorder is triggered. Helps standardize purchase orders and maintain consistent inventory levels.',
    example: '100 (order 100 units when reorder point is reached)',
  );

  // ===== SUPPLIER INFO FIELDS =====
  static const supplierName = FieldInfo(
    title: 'Supplier Name',
    description:
        'The vendor, company, or distributor who supplies this product. Helps track purchase sources and contact information for reordering.',
    example: 'MediSource Distributors, TechWorld Supplies, FreshMart Foods',
  );

  static const supplierSku = FieldInfo(
    title: 'Supplier SKU',
    description:
        'The supplier\'s internal product code or reference number. Used when placing orders with the supplier to ensure correct product identification.',
    example: 'MW-SUP-001, TWS-4567',
  );

  // ===== STATUS FIELDS =====
  static const activeStatus = FieldInfo(
    title: 'Product Active',
    description:
        'Controls whether the product is available for sale. Toggle off to temporarily hide the product without deleting it (e.g., out of stock, discontinued).',
    example: 'On: Available for sale, Off: Hidden from store',
  );

  static const featured = FieldInfo(
    title: 'Featured Product',
    description:
        'Highlights this product in the "featured" section of your store. Great for promoting new arrivals, best sellers, or special offers.',
    example: 'On: Appears in featured section, Off: Not featured',
  );

  static const digital = FieldInfo(
    title: 'Digital Product',
    description:
        'Indicates whether the product is digital (software, ebooks, digital downloads) or physical. Affects shipping requirements and delivery methods.',
    example: 'On: Digital (no shipping), Off: Physical (requires shipping)',
  );

  static const hasVariants = FieldInfo(
    title: 'Has Variants',
    description:
        'Indicates whether the product has variations like size, color, or style. Enables variant management for products sold in multiple configurations.',
    example:
        'On: Has variants (size, color), Off: Single product without variations',
  );

  static const productImage = FieldInfo(
    title: 'Product Image',
    description:
        'Add a visual representation of your product. Images help customers identify products quickly, make your inventory visually organized, and improve sales.',
    example: 'product_photo.jpg, product_front_view.png',
  );
}

// ===== INFO ICON WIDGET =====
class InfoIconWidget extends StatelessWidget {
  final FieldInfo info;

  const InfoIconWidget({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showInfoDialog(context),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withOpacity(0.1),
        ),
        child: Icon(Icons.info_outline, size: 18, color: Colors.blue.shade600),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                info.title,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.required != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.red.shade900 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  info.required!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode
                        ? Colors.red.shade400
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              info.description,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white : Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.example,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
