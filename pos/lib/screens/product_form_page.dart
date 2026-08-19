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

  // ===== BASIC CONTROLLERS =====
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

  // ===== MEDICINE CONTROLLERS =====
  final _genericNameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _drugRegNoController = TextEditingController();
  final _medicineManufacturerController = TextEditingController();

  // ===== FOOD CONTROLLERS =====
  final _countryOfOriginController = TextEditingController();

  // ===== DATE STATE =====
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

  // ===== MEDICINE STATE =====
  String? _selectedDosageForm;
  String? _selectedStorageCondition;
  String? _selectedRouteOfAdmin;
  bool _rxRequired = false;
  bool _controlledDrug = false;

  // ===== FOOD STATE =====
  bool _halalCertified = false;
  bool _organicCertified = false;

  // ===== PAKISTAN CATEGORY TREE =====
  static const Map<String, List<String>> _categoryTree = {
    'Medicine & Pharma': [
      'Tablets & Capsules',
      'Syrups & Liquids',
      'Injections & Vials',
      'Topical / Creams & Ointments',
      'Eye / Ear / Nasal Drops',
      'Inhalers & Nebulizers',
      'Surgical & Disposables',
      'Vitamins & Supplements',
      'Herbal / Unani',
      'Dental Products',
      'Contraceptives',
      'Veterinary Medicines',
    ],
    'Food & Grocery': [
      'Spices & Condiments',
      'Rice & Grains',
      'Pulses & Lentils',
      'Cooking Oil & Ghee',
      'Flour & Baking',
      'Dairy Products',
      'Snacks & Biscuits',
      'Beverages & Juices',
      'Tea & Coffee',
      'Frozen Foods',
      'Ready-to-Eat',
      'Confectionery & Sweets',
      'Dry Fruits & Nuts',
      'Salt & Sugar',
    ],
    'Electronics': [
      'Mobile Phones',
      'Laptops & Tablets',
      'Mobile Accessories',
      'Batteries & Chargers',
      'TV & Home Theater',
      'Printers & Cartridges',
      'Networking Equipment',
      'CCTV & Security',
      'Computer Components',
      'Wearables & Smartwatches',
    ],
    'Clothing & Textile': [
      'Men\'s Shalwar Kameez',
      'Men\'s Western Wear',
      'Women\'s Shalwar Kameez',
      'Women\'s Western Wear',
      'Children\'s Clothing',
      'Fabrics & Cloth (per meter)',
      'Shoes & Footwear',
      'Undergarments & Innerwear',
      'School Uniform',
      'Workwear & Safety',
      'Scarves & Dupattas',
    ],
    'Home & Kitchen': [
      'Cookware & Utensils',
      'Home Appliances',
      'Cleaning Supplies',
      'Furniture',
      'Home Décor',
      'Bedding & Linen',
      'Storage & Organisation',
      'Crockery & Cutlery',
      'Air Coolers & Fans',
    ],
    'Beauty & Personal Care': [
      'Skincare',
      'Hair Care',
      'Makeup & Cosmetics',
      'Fragrances & Perfumes',
      'Oral Care',
      'Shaving & Grooming',
      'Baby & Child Care',
      'Sanitary & Hygiene',
    ],
    'Stationery & Office': [
      'Paper & Notebooks',
      'Pens, Pencils & Markers',
      'Printers & Ink / Toner',
      'Office Supplies',
      'School Supplies',
      'Arts & Craft',
      'Files & Folders',
    ],
    'Agriculture & Livestock': [
      'Fertilizers',
      'Pesticides & Herbicides',
      'Seeds & Saplings',
      'Animal Feed',
      'Veterinary Supplies',
      'Farming Tools',
      'Irrigation Equipment',
    ],
    'Auto & Transport': [
      'Car Parts & Accessories',
      'Motorcycle Parts',
      'Lubricants & Engine Oil',
      'Batteries & Tyres',
      'Tools & Workshop Equipment',
      'Car Care & Cleaning',
    ],
    'Toys & Sports': [
      'Toys & Games',
      'Cricket Equipment',
      'Football & Sports',
      'Outdoor Recreation',
      'Fitness Equipment',
      'Gym Supplements',
    ],
    'Construction & Hardware': [
      'Cement & Concrete',
      'Steel & Iron',
      'Plumbing & Pipes',
      'Electrical Fittings & Wire',
      'Paint & Coatings',
      'Hand & Power Tools',
      'Tiles & Flooring',
      'Wood & Timber',
    ],
    'Uncategorized': ['General'],
  };

  List<String> get _categories => _categoryTree.keys.toList();

  List<String> get _subCategories {
    if (_selectedCategory == null) return [];
    return _categoryTree[_selectedCategory] ?? [];
  }

  bool get _isMedicineCategory => _selectedCategory == 'Medicine & Pharma';
  bool get _isFoodCategory => _selectedCategory == 'Food & Grocery';

  // ===== PAKISTAN TAX CLASSES =====
  static const List<String> _taxClasses = [
    'GST 0% – Exempt (Food staples, Medicine, Books)',
    'GST 5% – Reduced Rate',
    'GST 17% – Standard Rate',
    'GST 18% – High-Value Goods',
    'Sales Tax on Services (SRB/PRA)',
    'Drug / Pharma Duty',
    'Zero-Rated (Exports / Raw Materials)',
    'Exempt – Agricultural Produce',
  ];

  // ===== UNITS =====
  static const List<String> _units = [
    'pcs (Pieces)',
    'strip (Strip)',
    'pack (Pack)',
    'box (Box)',
    'bottle (Bottle)',
    'vial (Vial)',
    'ampoule (Ampoule)',
    'kg (Kilograms)',
    'g (Grams)',
    'mg (Milligrams)',
    'l (Liters)',
    'ml (Milliliters)',
    'm (Meters)',
    'cm (Centimeters)',
    'set (Set)',
    'pair (Pair)',
    'dozen (Dozen)',
    'roll (Roll)',
    'bag (Bag)',
    'can (Can)',
    'sachet (Sachet)',
    'tablet (Tablet)',
    'capsule (Capsule)',
  ];

  static const List<String> _weightUnits = ['kg', 'g', 'mg', 'lbs', 'oz'];

  // ===== MEDICINE DROPDOWNS =====
  static const List<String> _dosageForms = [
    'Tablet',
    'Capsule',
    'Soft Gel Capsule',
    'Syrup',
    'Suspension',
    'Oral Solution',
    'Drops (Oral)',
    'Injection (IV)',
    'Injection (IM)',
    'Injection (SC)',
    'Cream',
    'Ointment',
    'Gel',
    'Lotion',
    'Eye Drops',
    'Ear Drops',
    'Nasal Spray / Drops',
    'Inhaler (MDI)',
    'Nebuliser Solution',
    'Powder (for suspension)',
    'Sachet',
    'Suppository',
    'Patch (Transdermal)',
    'Sublingual Tablet',
    'Lozenge / Troche',
    'Pessary',
  ];

  static const List<String> _storageConditions = [
    'Room Temperature (15–30°C)',
    'Cool & Dry (Below 25°C)',
    'Refrigerate (2–8°C)',
    'Freeze (Below -20°C)',
    'Protect from Light',
    'Protect from Moisture',
    'Keep Below 30°C',
    'Do Not Freeze',
  ];

  static const List<String> _routesOfAdmin = [
    'Oral',
    'Sublingual',
    'Inhalation',
    'Topical',
    'Ophthalmic (Eye)',
    'Otic (Ear)',
    'Nasal',
    'Intravenous (IV)',
    'Intramuscular (IM)',
    'Subcutaneous (SC)',
    'Rectal',
    'Vaginal',
    'Intradermal',
    'Intrathecal',
  ];

  // ===================================================================
  @override
  void initState() {
    super.initState();
    _countryOfOriginController.text = 'Pakistan';
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

    // Populate medicine details
    if (p.medicineDetails != null) {
      final md = p.medicineDetails!;
      _genericNameController.text = md['genericName'] ?? '';
      _strengthController.text = md['strength'] ?? '';
      _drugRegNoController.text = md['drugRegNo'] ?? '';
      _medicineManufacturerController.text = md['manufacturer'] ?? '';
      _selectedDosageForm = md['dosageForm'];
      _selectedStorageCondition = md['storageCondition'];
      _selectedRouteOfAdmin = md['routeOfAdmin'];
      _rxRequired = md['rxRequired'] ?? false;
      _controlledDrug = md['controlledDrug'] ?? false;
    }

    // Populate food details
    if (p.foodDetails != null) {
      final fd = p.foodDetails!;
      _halalCertified = fd['halalCertified'] ?? false;
      _organicCertified = fd['organicCertified'] ?? false;
      _countryOfOriginController.text = fd['countryOfOrigin'] ?? 'Pakistan';
    }
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
    _genericNameController.dispose();
    _strengthController.dispose();
    _drugRegNoController.dispose();
    _medicineManufacturerController.dispose();
    _countryOfOriginController.dispose();
    super.dispose();
  }

  // ===== IMAGE =====
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
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Product Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a product image to make it stand out',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: Text(
                'Select from your device',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('Take Photo'),
              subtitle: Text(
                'Capture with camera',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imageFile = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ===== DATE PICKER =====
  Future<void> _selectDate(BuildContext context, String type) async {
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
              brightness: Theme.of(context).brightness,
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

  // ===== SAVE =====
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? medicineDetails;
      if (_isMedicineCategory) {
        medicineDetails = {
          'dosageForm': _selectedDosageForm,
          'genericName': _genericNameController.text.trim(),
          'strength': _strengthController.text.trim(),
          'drugRegNo': _drugRegNoController.text.trim(),
          'manufacturer': _medicineManufacturerController.text.trim(),
          'rxRequired': _rxRequired,
          'controlledDrug': _controlledDrug,
          'storageCondition': _selectedStorageCondition,
          'routeOfAdmin': _selectedRouteOfAdmin,
        };
      }

      Map<String, dynamic>? foodDetails;
      if (_isFoodCategory) {
        foodDetails = {
          'halalCertified': _halalCertified,
          'organicCertified': _organicCertified,
          'countryOfOrigin': _countryOfOriginController.text.trim(),
        };
      }

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
        unit: _selectedUnit ?? 'pcs (Pieces)',
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
        medicineDetails: medicineDetails,
        foodDetails: foodDetails,
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
        if (mounted) _showSnackBar('✅ Product added successfully!');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSnackBar('❌ Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ===================================================================
  // BUILD
  // ===================================================================
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
            onPressed: () => _showSnackBar('QR Scanner coming soon!'),
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
                    _buildSectionHeader(
                      'Basic Information',
                      Icons.info,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildBasicInfoFields(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Category & Classification',
                      Icons.category,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryFields(isDarkMode),
                    const SizedBox(height: 20),

                    // Medicine-specific adaptive section
                    if (_isMedicineCategory) ...[
                      _buildSectionHeader(
                        'Medicine Details',
                        Icons.medication,
                        isDarkMode,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildMedicineFields(isDarkMode),
                      const SizedBox(height: 20),
                    ],

                    // Food-specific adaptive section
                    if (_isFoodCategory) ...[
                      _buildSectionHeader(
                        'Food Details',
                        Icons.restaurant,
                        isDarkMode,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildFoodFields(isDarkMode),
                      const SizedBox(height: 20),
                    ],

                    _buildSectionHeader(
                      'Pricing & Stock',
                      Icons.attach_money,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildPricingStockFields(currencySymbol, isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Weight & Measurement',
                      Icons.fitness_center,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildWeightFields(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Expiry & Dates',
                      Icons.calendar_today,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildDateFields(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Codes & Identifiers',
                      Icons.qr_code,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildCodesFields(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Supplier Info',
                      Icons.business,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildSupplierFields(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Reorder Settings',
                      Icons.notifications_active,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildReorderFields(isDarkMode),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Status', Icons.toggle_on, isDarkMode),
                    const SizedBox(height: 12),
                    _buildStatusSection(isDarkMode),
                    const SizedBox(height: 24),
                    _buildSaveButton(isDarkMode),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ===================================================================
  // HELPERS
  // ===================================================================

  Widget _buildFormHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
            isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            widget.isEditing ? Icons.edit : Icons.add_circle,
            color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Product' : 'Create New Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  widget.isEditing
                      ? 'Update product details and information'
                      : 'Fill in the details to add a new product to inventory',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    bool isDarkMode, {
    Color? color,
  }) {
    final activeColor =
        color ?? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700);
    final bgColor = color != null
        ? color.withValues(alpha: 0.12)
        : (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: activeColor),
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
              colors: [activeColor, activeColor.withValues(alpha: 0.1)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool isDarkMode, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDec(
    String label,
    IconData icon,
    bool isDarkMode, {
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
    );
  }

  TextStyle _textStyle(bool isDarkMode) =>
      TextStyle(color: isDarkMode ? Colors.white : Colors.black);

  // ===================================================================
  // IMAGE SECTION
  // ===================================================================
  Widget _buildImageSection(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Column(
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                  width: 2,
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
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
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
                          size: 40,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload product image',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG, WEBP (Max 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // BASIC INFO
  // ===================================================================
  Widget _buildBasicInfoFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: _inputDec(
              'Product Name *',
              Icons.production_quantity_limits,
              isDarkMode,
              hint: 'Enter the product name',
            ),
            style: _textStyle(isDarkMode),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter product name';
              if (v.length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _inputDec(
              'Description',
              Icons.description,
              isDarkMode,
              hint: 'Enter product description',
            ),
            style: _textStyle(isDarkMode),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: _inputDec(
                    'Brand / Company',
                    Icons.branding_watermark,
                    isDarkMode,
                    hint: 'e.g. GSK, Nestle',
                  ),
                  style: _textStyle(isDarkMode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: _inputDec(
                    'SKU Code',
                    Icons.code,
                    isDarkMode,
                    hint: 'Stock-keeping unit',
                  ),
                  style: _textStyle(isDarkMode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // CATEGORY
  // ===================================================================
  Widget _buildCategoryFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Column(
        children: [
          // Category
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category *',
              prefixIcon: Icon(
                Icons.category,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: _textStyle(isDarkMode),
            hint: Text(
              'Select category...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: _categories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedSubCategory = null; // reset sub
              });
            },
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please select a category' : null,
          ),
          const SizedBox(height: 12),

          // Sub Category — dynamically filtered
          DropdownButtonFormField<String>(
            initialValue: _selectedSubCategory,
            decoration: InputDecoration(
              labelText: 'Sub-Category',
              prefixIcon: Icon(
                Icons.subdirectory_arrow_right,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: _textStyle(isDarkMode),
            hint: Text(
              _selectedCategory == null
                  ? 'Select a category first'
                  : 'Select sub-category...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: _subCategories.map((sub) {
              return DropdownMenuItem(value: sub, child: Text(sub));
            }).toList(),
            onChanged: _subCategories.isEmpty
                ? null
                : (value) => setState(() => _selectedSubCategory = value),
          ),
          const SizedBox(height: 12),

          // Tax Class
          DropdownButtonFormField<String>(
            initialValue: _selectedTaxClass,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Tax Class (Pakistan)',
              prefixIcon: Icon(
                Icons.receipt_long,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: _textStyle(isDarkMode),
            hint: Text(
              'Select tax class...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: _taxClasses.map((tax) {
              return DropdownMenuItem(value: tax, child: Text(tax));
            }).toList(),
            onChanged: (value) => setState(() => _selectedTaxClass = value),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // MEDICINE DETAILS — shown only for Medicine & Pharma
  // ===================================================================
  Widget _buildMedicineFields(bool isDarkMode) {
    final greenIcon = isDarkMode
        ? Colors.green.shade400
        : Colors.green.shade700;
    final highlight = isDarkMode
        ? Colors.green.shade900.withValues(alpha: 0.3)
        : Colors.green.shade50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.green.shade800 : Colors.green.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: greenIcon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These fields appear because you selected Medicine & Pharma',
                    style: TextStyle(fontSize: 12, color: greenIcon),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Generic Name + Strength
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _genericNameController,
                  decoration: InputDecoration(
                    labelText: 'Generic Name (INN)',
                    hintText: 'e.g. Paracetamol, Amoxicillin',
                    prefixIcon: Icon(Icons.science, color: greenIcon),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  style: _textStyle(isDarkMode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _strengthController,
                  decoration: InputDecoration(
                    labelText: 'Strength',
                    hintText: 'e.g. 500mg',
                    prefixIcon: Icon(Icons.bar_chart, color: greenIcon),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  style: _textStyle(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dosage Form
          DropdownButtonFormField<String>(
            initialValue: _selectedDosageForm,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Dosage Form *',
              prefixIcon: Icon(Icons.medication, color: greenIcon),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: _textStyle(isDarkMode),
            hint: Text(
              'Select dosage form...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: _dosageForms.map((f) {
              return DropdownMenuItem(value: f, child: Text(f));
            }).toList(),
            onChanged: (v) => setState(() => _selectedDosageForm = v),
            validator: (v) => (v == null && _isMedicineCategory)
                ? 'Please select dosage form'
                : null,
          ),
          const SizedBox(height: 12),

          // Route of Admin
          DropdownButtonFormField<String>(
            initialValue: _selectedRouteOfAdmin,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Route of Administration',
              prefixIcon: Icon(Icons.route, color: greenIcon),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: _textStyle(isDarkMode),
            hint: Text(
              'Select route...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: _routesOfAdmin.map((r) {
              return DropdownMenuItem(value: r, child: Text(r));
            }).toList(),
            onChanged: (v) => setState(() => _selectedRouteOfAdmin = v),
          ),
          const SizedBox(height: 12),

          // Storage Condition
          DropdownButtonFormField<String>(
            initialValue: _selectedStorageCondition,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Storage Condition',
              prefixIcon: Icon(Icons.ac_unit, color: greenIcon),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            style: _textStyle(isDarkMode),
            hint: Text(
              'Select storage...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: _storageConditions.map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (v) => setState(() => _selectedStorageCondition = v),
          ),
          const SizedBox(height: 12),

          // DRAP Reg No + Manufacturer
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _drugRegNoController,
                  decoration: InputDecoration(
                    labelText: 'DRAP Reg. No.',
                    hintText: 'e.g. 031234',
                    prefixIcon: Icon(Icons.numbers, color: greenIcon),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  style: _textStyle(isDarkMode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _medicineManufacturerController,
                  decoration: InputDecoration(
                    labelText: 'Manufacturer',
                    hintText: 'e.g. GSK, Pfizer',
                    prefixIcon: Icon(Icons.factory, color: greenIcon),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  style: _textStyle(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rx + Controlled toggles
          Container(
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _rxRequired
                              ? Colors.red.shade600
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _rxRequired ? 'Rx' : 'OTC',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prescription Required',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _rxRequired
                        ? 'This medicine requires a doctor\'s prescription (Rx)'
                        : 'Available over-the-counter (OTC)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  value: _rxRequired,
                  onChanged: (v) => setState(() => _rxRequired = v),
                  activeThumbColor: isDarkMode
                      ? Colors.red.shade400
                      : Colors.red,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(
                    'Controlled / Narcotic Drug',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _controlledDrug
                        ? 'Subject to CNS/DRAP controlled substance regulations'
                        : 'Not a controlled substance',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  value: _controlledDrug,
                  onChanged: (v) => setState(() => _controlledDrug = v),
                  activeThumbColor: isDarkMode
                      ? Colors.orange.shade400
                      : Colors.orange,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // FOOD DETAILS — shown only for Food & Grocery
  // ===================================================================
  Widget _buildFoodFields(bool isDarkMode) {
    final orangeIcon = isDarkMode
        ? Colors.orange.shade400
        : Colors.orange.shade700;
    final highlight = isDarkMode
        ? Colors.orange.shade900.withValues(alpha: 0.2)
        : Colors.orange.shade50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.orange.shade800 : Colors.orange.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: orangeIcon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These fields appear because you selected Food & Grocery',
                    style: TextStyle(fontSize: 12, color: orangeIcon),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _countryOfOriginController,
            decoration: InputDecoration(
              labelText: 'Country of Origin',
              hintText: 'e.g. Pakistan, India',
              prefixIcon: Icon(Icons.flag, color: orangeIcon),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
            style: _textStyle(isDarkMode),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Row(
                    children: [
                      const Text('🕌  '),
                      Text(
                        'Halal Certified',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _halalCertified
                        ? 'Product is Halal certified'
                        : 'Halal certification not specified',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  value: _halalCertified,
                  onChanged: (v) => setState(() => _halalCertified = v),
                  activeThumbColor: isDarkMode
                      ? Colors.green.shade400
                      : Colors.green,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Row(
                    children: [
                      const Text('🌿  '),
                      Text(
                        'Organic Certified',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _organicCertified
                        ? 'Product is organically produced'
                        : 'Organic certification not specified',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  value: _organicCertified,
                  onChanged: (v) => setState(() => _organicCertified = v),
                  activeThumbColor: isDarkMode
                      ? Colors.teal.shade400
                      : Colors.teal,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // PRICING & STOCK
  // ===================================================================
  Widget _buildPricingStockFields(String currencySymbol, bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Selling Price *',
                    hintText: '0.00',
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: isDarkMode
                          ? Colors.green.shade400
                          : Colors.green.shade700,
                    ),
                    prefixText: '$currencySymbol ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    if (double.parse(v) < 0) return 'Must be positive';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: 'Cost Price *',
                    hintText: '0.00',
                    prefixIcon: Icon(
                      Icons.currency_exchange,
                      color: isDarkMode
                          ? Colors.orange.shade400
                          : Colors.orange.shade700,
                    ),
                    prefixText: '$currencySymbol ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    if (double.parse(v) < 0) return 'Must be positive';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _salePriceController,
                  decoration: InputDecoration(
                    labelText: 'Sale Price',
                    hintText: '0.00 (Optional)',
                    prefixIcon: Icon(
                      Icons.local_offer,
                      color: isDarkMode
                          ? Colors.purple.shade400
                          : Colors.purple.shade700,
                    ),
                    prefixText: '$currencySymbol ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wholesalePriceController,
                  decoration: InputDecoration(
                    labelText: 'Wholesale Price',
                    hintText: '0.00 (Optional)',
                    prefixIcon: Icon(
                      Icons.shopping_bag,
                      color: isDarkMode
                          ? Colors.teal.shade400
                          : Colors.teal.shade700,
                    ),
                    prefixText: '$currencySymbol ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  decoration: InputDecoration(
                    labelText: 'Stock Quantity *',
                    hintText: '0',
                    prefixIcon: Icon(
                      Icons.inventory,
                      color: isDarkMode
                          ? Colors.blue.shade400
                          : Colors.blue.shade700,
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Invalid number';
                    if (int.parse(v) < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _minStockController,
                  decoration: InputDecoration(
                    labelText: 'Min Stock Alert *',
                    hintText: '10',
                    prefixIcon: Icon(
                      Icons.warning,
                      color: isDarkMode
                          ? Colors.red.shade400
                          : Colors.red.shade700,
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Invalid number';
                    if (int.parse(v) < 0) return 'Must be positive';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _maxStockController,
                  decoration: InputDecoration(
                    labelText: 'Max Stock',
                    hintText: '0 (Optional)',
                    prefixIcon: Icon(
                      Icons.inventory_2,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  style: _textStyle(isDarkMode),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Unit *',
                    prefixIcon: Icon(
                      Icons.straighten,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  dropdownColor: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.white,
                  style: _textStyle(isDarkMode),
                  hint: Text(
                    'Select unit',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  items: _units.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // WEIGHT
  // ===================================================================
  Widget _buildWeightFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _weightController,
              decoration: _inputDec(
                'Weight',
                Icons.fitness_center,
                isDarkMode,
                hint: '0.00 (Optional)',
              ),
              keyboardType: TextInputType.number,
              style: _textStyle(isDarkMode),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedWeightUnit,
              decoration: InputDecoration(
                labelText: 'Weight Unit',
                prefixIcon: Icon(
                  Icons.scale,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade50,
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: _textStyle(isDarkMode),
              hint: Text(
                'Select unit',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              items: _weightUnits.map((u) {
                return DropdownMenuItem(value: u, child: Text(u));
              }).toList(),
              onChanged: (v) => setState(() => _selectedWeightUnit = v),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // DATE FIELDS
  // ===================================================================
  Widget _buildDateFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Column(
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
      ),
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
          borderRadius: BorderRadius.circular(8),
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
                date != null ? DateFormat('dd/MM/yyyy').format(date) : label,
                style: TextStyle(
                  color: date != null
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : (isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                  fontWeight: date != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (label.contains('Manufacture')) _manufactureDate = null;
                    if (label.contains('Expiry')) _expiryDate = null;
                    if (label.contains('Best')) _bestBeforeDate = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade500,
                ),
              )
            else
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // CODES (Barcode / QR)
  // ===================================================================
  Widget _buildCodesFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _barcodeController,
              decoration: _inputDec(
                'Barcode',
                Icons.barcode_reader,
                isDarkMode,
                hint: 'Enter or scan barcode',
                suffix: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: isDarkMode
                        ? Colors.blue.shade400
                        : Colors.blue.shade700,
                  ),
                  onPressed: () => _showSnackBar('Scanner coming soon!'),
                ),
              ),
              style: _textStyle(isDarkMode),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _qrCodeController,
              decoration: _inputDec(
                'QR Code',
                Icons.qr_code,
                isDarkMode,
                hint: 'Enter or scan QR code',
                suffix: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: isDarkMode
                        ? Colors.blue.shade400
                        : Colors.blue.shade700,
                  ),
                  onPressed: () => _showSnackBar('Scanner coming soon!'),
                ),
              ),
              style: _textStyle(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // SUPPLIER
  // ===================================================================
  Widget _buildSupplierFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _supplierNameController,
              decoration: _inputDec(
                'Supplier Name',
                Icons.business,
                isDarkMode,
                hint: 'Enter supplier name',
              ),
              style: _textStyle(isDarkMode),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _supplierSkuController,
              decoration: _inputDec(
                'Supplier SKU',
                Icons.code,
                isDarkMode,
                hint: 'Supplier\'s SKU code',
              ),
              style: _textStyle(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // REORDER
  // ===================================================================
  Widget _buildReorderFields(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _reorderPointController,
              decoration: _inputDec(
                'Reorder Point',
                Icons.notifications_active,
                isDarkMode,
                hint: '0 (Optional)',
              ),
              keyboardType: TextInputType.number,
              style: _textStyle(isDarkMode),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _reorderQuantityController,
              decoration: _inputDec(
                'Reorder Quantity',
                Icons.shopping_cart,
                isDarkMode,
                hint: '0 (Optional)',
              ),
              keyboardType: TextInputType.number,
              style: _textStyle(isDarkMode),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // STATUS TOGGLES
  // ===================================================================
  Widget _buildStatusSection(bool isDarkMode) {
    return _buildCard(
      isDarkMode,
      Column(
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
                  ? 'Visible and available for sale'
                  : 'Hidden – not available for sale',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: isDarkMode ? Colors.green.shade400 : Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              'Featured Product',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(
              _isFeatured ? 'Appears in featured section' : 'Not featured',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeThumbColor: isDarkMode
                ? Colors.orange.shade400
                : Colors.orange,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
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
                  ? 'Digital – no physical shipping required'
                  : 'Physical product – requires delivery',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            value: _isDigital,
            onChanged: (v) => setState(() => _isDigital = v),
            activeThumbColor: isDarkMode
                ? Colors.purple.shade400
                : Colors.purple,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
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
                  ? 'Product has multiple variants (size, colour, etc.)'
                  : 'Single item – no variants',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            value: _hasVariants,
            onChanged: (v) => setState(() => _hasVariants = v),
            activeThumbColor: isDarkMode ? Colors.blue.shade400 : Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // SAVE BUTTON
  // ===================================================================
  Widget _buildSaveButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode
              ? Colors.blue.shade400
              : Colors.blue.shade700,
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

  // ===================================================================
  // HELP DIALOG
  // ===================================================================
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help – Product Form'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                '📝',
                'Basic Info',
                'Name, description, brand, SKU',
              ),
              _buildHelpItem(
                '📂',
                'Category',
                'Pakistan-specific categories + dynamic sub-categories + GST tax class',
              ),
              _buildHelpItem(
                '💊',
                'Medicine Details',
                'Appears only for Medicine & Pharma: Dosage form, strength, DRAP reg no, Rx/OTC, storage',
              ),
              _buildHelpItem(
                '🍽️',
                'Food Details',
                'Appears only for Food & Grocery: Halal, organic, country of origin',
              ),
              _buildHelpItem(
                '💰',
                'Pricing',
                'Selling price, cost, sale, and wholesale',
              ),
              _buildHelpItem(
                '📦',
                'Stock',
                'Quantity, min/max stock, and unit',
              ),
              _buildHelpItem('⚖️', 'Weight', 'Weight with unit (kg/g/mg/lbs)'),
              _buildHelpItem('📅', 'Dates', 'Manufacture, expiry, best before'),
              _buildHelpItem('🔢', 'Codes', 'Barcode and QR code'),
              _buildHelpItem('🏢', 'Supplier', 'Supplier name and SKU'),
              _buildHelpItem('🔔', 'Reorder', 'Reorder point and quantity'),
              _buildHelpItem(
                '✅',
                'Status',
                'Active, featured, digital, variants',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
