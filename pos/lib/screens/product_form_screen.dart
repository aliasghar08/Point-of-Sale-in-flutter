import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/providers/settings_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final bool isEditing;

  const ProductFormScreen({super.key, this.product, this.isEditing = false});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ===== CONTROLLERS =====
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _weightController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _qrCodeController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _supplierSkuController = TextEditingController();
  final _reorderPointController = TextEditingController();
  final _reorderQuantityController = TextEditingController();

  // ===== DATE CONTROLLERS =====
  DateTime? _manufactureDate;
  DateTime? _expiryDate;
  DateTime? _bestBeforeDate;

  // ===== SELECTION STATE =====
  File? _imageFile;
  String? _imageUrl;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedTaxClass;
  String? _selectedUnit;
  String? _selectedWeightUnit;
  bool _isLoading = false;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isDigital = false;
  bool _hasVariants = false;

  // ===== DROPDOWN OPTIONS =====
  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Food & Beverages',
    'Books',
    'Beauty & Health',
    'Home & Kitchen',
    'Sports & Outdoors',
    'Toys & Games',
    'Automotive',
    'Furniture',
    'Jewelry',
    'Shoes',
    'Accessories',
    'Uncategorized',
  ];

  final List<String> _subCategories = [
    'Smartphones',
    'Laptops',
    'Tablets',
    'Accessories',
    'T-Shirts',
    'Jeans',
    'Dresses',
    'Snacks',
    'Beverages',
    'Frozen Foods',
    'Skincare',
    'Makeup',
    'Furniture',
    'Home Decor',
    'Kitchenware',
    'Toys',
    'Games',
    'Uncategorized',
  ];

  final List<String> _taxClasses = [
    'Standard (18%)',
    'Reduced (5%)',
    'Zero (0%)',
    'Exempt',
  ];

  final List<String> _units = [
    'pcs (Pieces)',
    'kg (Kilograms)',
    'g (Grams)',
    'mg (Milligrams)',
    'l (Liters)',
    'ml (Milliliters)',
    'm (Meters)',
    'cm (Centimeters)',
    'box (Box)',
    'pack (Pack)',
    'set (Set)',
    'pair (Pair)',
    'dozen (Dozen)',
    'roll (Roll)',
  ];

  final List<String> _weightUnits = ['kg', 'g', 'lbs', 'oz'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.product != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final p = widget.product!;
    _nameController.text = p.name;
    _descriptionController.text = p.description;
    _brandController.text = p.brand;
    _skuController.text = p.sku;
    _priceController.text = p.price.toStringAsFixed(2);
    _costController.text = p.costPrice.toStringAsFixed(2);
    _salePriceController.text = p.salePrice?.toStringAsFixed(2) ?? '';
    _wholesalePriceController.text = p.wholesalePrice?.toStringAsFixed(2) ?? '';
    _stockController.text = p.stock.toString();
    _minStockController.text = p.minStock.toString();
    _maxStockController.text = p.maxStock > 0 ? p.maxStock.toString() : '';
    _weightController.text = p.weight?.toString() ?? '';
    _barcodeController.text = p.barcode;
    _qrCodeController.text = p.qrCode;
    _selectedCategory = p.category;
    _selectedSubCategory = p.subCategory;
    _selectedTaxClass = p.taxClass;
    _selectedUnit = p.unit;
    _selectedWeightUnit = p.weightUnit;
    _supplierNameController.text = p.supplierName ?? '';
    _supplierSkuController.text = p.supplierSku ?? '';
    _reorderPointController.text = p.reorderPoint?.toString() ?? '';
    _reorderQuantityController.text = p.reorderQuantity?.toString() ?? '';
    _manufactureDate = p.manufactureDate;
    _expiryDate = p.expiryDate;
    _bestBeforeDate = p.bestBeforeDate;
    _isActive = p.isActive;
    _isFeatured = p.isFeatured;
    _isDigital = p.isDigital;
    _hasVariants = p.hasVariants;
    _imageUrl = p.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _salePriceController.dispose();
    _wholesalePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _weightController.dispose();
    _barcodeController.dispose();
    _qrCodeController.dispose();
    _supplierNameController.dispose();
    _supplierSkuController.dispose();
    _reorderPointController.dispose();
    _reorderQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _showImagePickerOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Product Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a product image to make it stand out',
              style: TextStyle(
                fontSize: 14, 
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: isDarkMode ? Colors.blue.shade400 : Colors.blue),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: Text(
                'Select from your device',
                style: TextStyle(
                  fontSize: 12, 
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.green.shade900 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: isDarkMode ? Colors.green.shade400 : Colors.green),
              ),
              title: const Text('Take Photo'),
              subtitle: Text(
                'Capture with camera',
                style: TextStyle(
                  fontSize: 12, 
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.red.shade900 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: isDarkMode ? Colors.red.shade400 : Colors.red),
                ),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'manufacture':
            _manufactureDate = picked;
            break;
          case 'expiry':
            _expiryDate = picked;
            break;
          case 'bestBefore':
            _bestBeforeDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      final product = Product(
        id: widget.isEditing ? widget.product!.id : '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim(),
        sku: _skuController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costController.text),
        salePrice: _salePriceController.text.isNotEmpty
            ? double.parse(_salePriceController.text)
            : null,
        wholesalePrice: _wholesalePriceController.text.isNotEmpty
            ? double.parse(_wholesalePriceController.text)
            : null,
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        maxStock: _maxStockController.text.isNotEmpty
            ? int.parse(_maxStockController.text)
            : 0,
        unit: _selectedUnit ?? 'pcs',
        weight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
        weightUnit: _selectedWeightUnit,
        reorderPoint: _reorderPointController.text.isNotEmpty
            ? int.parse(_reorderPointController.text)
            : null,
        reorderQuantity: _reorderQuantityController.text.isNotEmpty
            ? int.parse(_reorderQuantityController.text)
            : null,
        manufactureDate: _manufactureDate,
        expiryDate: _expiryDate,
        bestBeforeDate: _bestBeforeDate,
        barcode: _barcodeController.text.trim(),
        qrCode: _qrCodeController.text.trim(),
        category: _selectedCategory ?? 'Uncategorized',
        subCategory: _selectedSubCategory,
        taxClass: _selectedTaxClass,
        supplierName: _supplierNameController.text.trim(),
        supplierSku: _supplierSkuController.text.trim(),
        imageUrl: _imageUrl ?? '',
        isActive: _isActive,
        isFeatured: _isFeatured,
        isDigital: _isDigital,
        hasVariants: _hasVariants,
        createdAt: widget.isEditing
            ? widget.product!.createdAt
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firebaseService = FirebaseService();

      if (widget.isEditing) {
        await firebaseService.updateProduct(
          widget.product!.id,
          product.toMap(),
        );
        _showSnackBar('✅ Product updated successfully!');
      } else {
        await firebaseService.addProduct(product.toMap());
        _showSnackBar('✅ Product added successfully!');
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('❌ Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isError
            ? (isDarkMode ? Colors.red.shade400 : Colors.red.shade700)
            : (isDarkMode ? Colors.green.shade400 : Colors.green.shade700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode
            ? Colors.blue.shade800
            : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              _showSnackBar('QR Scanner coming soon!');
            },
            tooltip: 'Scan QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormHeader(isDarkMode),
                    const SizedBox(height: 20),
                    _buildImageSection(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.info,
                      child: _buildBasicInfoFields(isDarkMode),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Pricing & Stock',
                      icon: Icons.attach_money,
                      child: _buildPricingStockFields(currencySymbol, isDarkMode),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Expiry & Dates',
                      icon: Icons.calendar_today,
                      child: _buildDateFields(isDarkMode),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Additional Details',
                      icon: Icons.more_horiz,
                      child: _buildAdditionalFields(isDarkMode),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Supplier Info',
                      icon: Icons.business,
                      child: _buildSupplierFields(isDarkMode),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Status',
                      icon: Icons.toggle_on,
                      child: _buildStatusSection(isDarkMode),
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 24),
                    _buildSaveButton(isDarkMode),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ===== BUILD METHODS =====

  Widget _buildFormHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
            isDarkMode ? Colors.blue.shade900 : Colors.blue.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isEditing ? Icons.edit : Icons.add_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Product' : 'Create New Product',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.isEditing
                      ? 'Update product details and information'
                      : 'Fill in the details to add a new product',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Product Image',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 48,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload product image',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PNG, JPG, WEBP (Max 5MB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 2,
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                        isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoFields(bool isDarkMode) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Product Name *',
            hintText: 'Enter the product name',
            prefixIcon: Icon(
              Icons.production_quantity_limits,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Enter product description',
            prefixIcon: Icon(
              Icons.description,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _brandController,
          decoration: InputDecoration(
            labelText: 'Brand',
            hintText: 'Enter brand name',
            prefixIcon: Icon(
              Icons.branding_watermark,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _skuController,
          decoration: InputDecoration(
            labelText: 'SKU',
            hintText: 'Enter SKU code',
            prefixIcon: Icon(
              Icons.code,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  Widget _buildPricingStockFields(String currencySymbol, bool isDarkMode) {
    return Column(
      children: [
        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Selling Price *',
            hintText: '0.00',
            prefixIcon: Icon(
              Icons.attach_money,
              color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
            ),
            prefixText: '$currencySymbol ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (double.tryParse(value) == null) return 'Invalid number';
            if (double.parse(value) < 0) return 'Price must be positive';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _costController,
          decoration: InputDecoration(
            labelText: 'Cost Price *',
            hintText: '0.00',
            prefixIcon: Icon(
              Icons.currency_exchange,
              color: isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700,
            ),
            prefixText: '$currencySymbol ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (double.tryParse(value) == null) return 'Invalid number';
            if (double.parse(value) < 0) return 'Cost must be positive';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _salePriceController,
          decoration: InputDecoration(
            labelText: 'Sale Price',
            hintText: '0.00 (Optional)',
            prefixIcon: Icon(
              Icons.local_offer,
              color: isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700,
            ),
            prefixText: '$currencySymbol ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _wholesalePriceController,
          decoration: InputDecoration(
            labelText: 'Wholesale Price',
            hintText: '0.00 (Optional)',
            prefixIcon: Icon(
              Icons.shopping_bag,
              color: isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700,
            ),
            prefixText: '$currencySymbol ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _stockController,
          decoration: InputDecoration(
            labelText: 'Stock Quantity *',
            hintText: '0',
            prefixIcon: Icon(
              Icons.inventory,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (int.tryParse(value) == null) return 'Invalid number';
            if (int.parse(value) < 0) return 'Stock cannot be negative';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minStockController,
          decoration: InputDecoration(
            labelText: 'Min Stock Alert *',
            hintText: '10',
            prefixIcon: Icon(
              Icons.warning,
              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (int.tryParse(value) == null) return 'Invalid number';
            if (int.parse(value) < 0) return 'Min stock must be positive';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxStockController,
          decoration: InputDecoration(
            labelText: 'Max Stock',
            hintText: '0 (Optional)',
            prefixIcon: Icon(
              Icons.inventory_2,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: const InputDecoration(
              labelText: 'Unit *',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            items: _units.map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUnit = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a unit';
              }
              return null;
            },
            hint: Text(
              'Select unit',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: 'Weight',
            hintText: '0.00 (Optional)',
            prefixIcon: Icon(
              Icons.fitness_center,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedWeightUnit,
            decoration: const InputDecoration(
              labelText: 'Weight Unit',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            items: _weightUnits.map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWeightUnit = value;
              });
            },
            hint: Text(
              'Select unit',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFields(bool isDarkMode) {
    return Column(
      children: [
        _buildDatePicker(
          label: 'Manufacture Date',
          date: _manufactureDate,
          icon: Icons.factory,
          onTap: () => _selectDate(context, 'manufacture'),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 12),
        _buildDatePicker(
          label: 'Expiry Date',
          date: _expiryDate,
          icon: Icons.warning_amber,
          onTap: () => _selectDate(context, 'expiry'),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 12),
        _buildDatePicker(
          label: 'Best Before Date',
          date: _bestBeforeDate,
          icon: Icons.calendar_today,
          onTap: () => _selectDate(context, 'bestBefore'),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yyyy').format(date)
                    : label,
                style: TextStyle(
                  color: date != null
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                  fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFields(bool isDarkMode) {
    return Column(
      children: [
        TextFormField(
          controller: _barcodeController,
          decoration: InputDecoration(
            labelText: 'Barcode',
            hintText: 'Enter barcode',
            prefixIcon: Icon(
              Icons.barcode_reader,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _qrCodeController,
          decoration: InputDecoration(
            labelText: 'QR Code',
            hintText: 'Enter QR code',
            prefixIcon: Icon(
              Icons.qr_code,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category *',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select category...'),
              ),
              ..._categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedSubCategory,
            decoration: const InputDecoration(
              labelText: 'Sub Category',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select sub category...'),
              ),
              ..._subCategories.map((subCat) {
                return DropdownMenuItem(
                  value: subCat,
                  child: Text(subCat),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSubCategory = value;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedTaxClass,
            decoration: const InputDecoration(
              labelText: 'Tax Class',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select tax class...'),
              ),
              ..._taxClasses.map((tax) {
                return DropdownMenuItem(value: tax, child: Text(tax));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTaxClass = value;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reorderPointController,
          decoration: InputDecoration(
            labelText: 'Reorder Point',
            hintText: '0 (Optional)',
            prefixIcon: Icon(
              Icons.notifications_active,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reorderQuantityController,
          decoration: InputDecoration(
            labelText: 'Reorder Quantity',
            hintText: '0 (Optional)',
            prefixIcon: Icon(
              Icons.shopping_cart,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildSupplierFields(bool isDarkMode) {
    return Column(
      children: [
        TextFormField(
          controller: _supplierNameController,
          decoration: InputDecoration(
            labelText: 'Supplier Name',
            hintText: 'Enter supplier name',
            prefixIcon: Icon(
              Icons.business,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _supplierSkuController,
          decoration: InputDecoration(
            labelText: 'Supplier SKU',
            hintText: 'Enter supplier SKU',
            prefixIcon: Icon(
              Icons.code,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isDarkMode) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            'Product Active',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            _isActive
                ? 'Product is visible and available for sale'
                : 'Product is hidden and not available for sale',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          activeColor: isDarkMode ? Colors.green.shade400 : Colors.green,
          inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: Text(
            'Featured Product',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            _isFeatured
                ? 'Product appears in featured section'
                : 'Product not featured',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          value: _isFeatured,
          onChanged: (value) {
            setState(() {
              _isFeatured = value;
            });
          },
          activeColor: isDarkMode ? Colors.orange.shade400 : Colors.orange,
          inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: Text(
            'Digital Product',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            _isDigital
                ? 'Product is digital (no shipping required)'
                : 'Product is physical (requires shipping)',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          value: _isDigital,
          onChanged: (value) {
            setState(() {
              _isDigital = value;
            });
          },
          activeColor: isDarkMode ? Colors.purple.shade400 : Colors.purple,
          inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: Text(
            'Has Variants',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            _hasVariants
                ? 'Product has multiple variants (size, color, etc.)'
                : 'Product is a single item without variants',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          value: _hasVariants,
          onChanged: (value) {
            setState(() {
              _hasVariants = value;
            });
          },
          activeColor: isDarkMode ? Colors.blue.shade400 : Colors.blue,
          inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.grey,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.isEditing ? Icons.update : Icons.save, size: 20),
            const SizedBox(width: 12),
            Text(
              widget.isEditing ? 'Update Product' : 'Add Product',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Help - Add Product',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('📝', 'Basic Info', 'Name, description, brand, and SKU', isDarkMode),
            _buildHelpItem('💰', 'Pricing', 'Selling price, cost, sale, and wholesale', isDarkMode),
            _buildHelpItem('📦', 'Stock', 'Quantity, min stock, max stock, and unit', isDarkMode),
            _buildHelpItem('📅', 'Dates', 'Manufacture, expiry, and best before dates', isDarkMode),
            _buildHelpItem('🔢', 'Codes', 'Barcode and QR code for scanning', isDarkMode),
            _buildHelpItem('📂', 'Categories', 'Category, sub-category, and tax class', isDarkMode),
            _buildHelpItem('🏢', 'Supplier', 'Supplier name and SKU', isDarkMode),
            _buildHelpItem('✅', 'Status', 'Active, featured, digital, and variants', isDarkMode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String icon, String title, String description, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}