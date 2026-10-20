import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pos/models/product.dart';
import 'package:pos/viewmodels/product_form_view_model.dart';
import 'package:pos/viewmodels/inventory_view_model.dart';
import 'package:pos/viewmodels/pos_view_model.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/barcode_scanner.dart';
import 'package:pos/widgets/product_image_widget.dart';

/// Premium, Retail-Grade Product Catalog Creation & Editing Screen.
/// Designed to Apple, Square, and Stripe retail standards with deep obsidian surfaces,
/// live margin calculations, fluid pill selectors, and a glassmorphic sticky bottom bar.
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final bool isEditing;

  const ProductFormScreen({super.key, this.product, this.isEditing = false});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final ProductFormViewModel _viewModel;

  // Text Controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _wholesaleController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Accordion State
  bool _isAdvancedExpanded = false;

  // Color Palette Constants
  static const Color _bgObsidian = Color(0xFF0B0F19);
  static const Color _surfaceNavy = Color(0xFF1E293B);
  static const Color _borderSlate = Color(0xFF334155);
  static const Color _accentSky = Color(0xFF38BDF8);
  static const Color _accentIndigo = Color(0xFF6366F1);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _crimson = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _viewModel = ProductFormViewModel();

    // Populate initial data from product or defaults
    _viewModel.initFromProduct(widget.product);

    // Initialize controller values
    _nameController.text = _viewModel.name;
    _skuController.text = _viewModel.sku;
    _barcodeController.text = _viewModel.barcode;
    _costController.text =
        _viewModel.costPrice > 0 ? _viewModel.costPrice.toStringAsFixed(2) : '';
    _sellingPriceController.text = _viewModel.sellingPrice > 0
        ? _viewModel.sellingPrice.toStringAsFixed(2)
        : '';
    _stockController.text = _viewModel.stockQuantity.toString();
    _minStockController.text = _viewModel.minStockAlert.toString();
    _wholesaleController.text = _viewModel.wholesalePrice != null
        ? _viewModel.wholesalePrice!.toStringAsFixed(2)
        : '';
    _salePriceController.text = _viewModel.salePrice != null
        ? _viewModel.salePrice!.toStringAsFixed(2)
        : '';
    _descriptionController.text = _viewModel.description;

    // Attach listeners
    _nameController.addListener(() => _viewModel.setName(_nameController.text));
    _skuController.addListener(() => _viewModel.setSku(_skuController.text));
    _barcodeController
        .addListener(() => _viewModel.setBarcode(_barcodeController.text));
    _costController.addListener(() {
      final val = double.tryParse(_costController.text) ?? 0.0;
      _viewModel.setCostPrice(val);
    });
    _sellingPriceController.addListener(() {
      final val = double.tryParse(_sellingPriceController.text) ?? 0.0;
      _viewModel.setSellingPrice(val);
    });
    _stockController.addListener(() {
      final val = int.tryParse(_stockController.text) ?? 0;
      _viewModel.setStockQuantity(val);
    });
    _minStockController.addListener(() {
      final val = int.tryParse(_minStockController.text) ?? 0;
      _viewModel.setMinStockAlert(val);
    });
    _wholesaleController.addListener(() {
      final val = double.tryParse(_wholesaleController.text);
      _viewModel.setWholesalePrice(val);
    });
    _salePriceController.addListener(() {
      final val = double.tryParse(_salePriceController.text);
      _viewModel.setSalePrice(val);
    });
    _descriptionController.addListener(
      () => _viewModel.setDescription(_descriptionController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _wholesaleController.dispose();
    _salePriceController.dispose();
    _descriptionController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScanner(
          title: 'Scan Item Barcode',
          hintText: 'Align barcode or QR code in frame',
          expectedType: ScannerExpectedType.any,
          onScan: (code) {
            _viewModel.onBarcodeScanned(code);
            _barcodeController.text = _viewModel.barcode;
            if (_skuController.text.trim().isEmpty) {
              _skuController.text = _viewModel.sku;
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        _viewModel.setImageFile(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: _crimson,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderSlate,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _accentSky),
                title: const Text('Take Photo',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _accentSky),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_viewModel.imageFile != null || _viewModel.imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: _crimson),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: _crimson)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _viewModel.clearImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategorySheet() {
    final catController = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Dairy, Spices, Cosmetics',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _bgObsidian,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _borderSlate),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _borderSlate),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentSky, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final text = catController.text.trim();
                  if (text.isNotEmpty) {
                    _viewModel.addCategory(text);
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentSky,
                  foregroundColor: _bgObsidian,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final businessId = auth.currentBusinessId;
    if (businessId == null || businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active store selected. Please login again.'),
          backgroundColor: _crimson,
        ),
      );
      return;
    }

    final inventoryVm = Provider.of<InventoryViewModel>(context, listen: false);
    final posVm = Provider.of<PosViewModel>(context, listen: false);

    HapticFeedback.mediumImpact();
    final success = await _viewModel.saveProduct(
      existingProduct: widget.product,
      businessId: businessId,
      inventoryViewModel: inventoryVm,
      posViewModel: posVm,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Product updated successfully!'
              : 'Product saved to catalog!'),
          backgroundColor: _emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && _viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: _crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final currencySymbol = settings.currencySymbol;
    final isEditing = widget.isEditing || widget.product != null;

    return ChangeNotifierProvider<ProductFormViewModel>.value(
      value: _viewModel,
      child: Consumer<ProductFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: _bgObsidian,
            resizeToAvoidBottomInset: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildStickyHeader(isEditing),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Identity & Media Card
                  _buildHeroIdentityCard(vm),
                  const SizedBox(height: 16),

                  // 2. Dynamic Financial & Profit Margin Card
                  _buildFinancialMarginCard(vm, currencySymbol),
                  const SizedBox(height: 16),

                  // 3. Inventory & Fast Unit Chips Card
                  _buildInventoryUnitCard(vm),
                  const SizedBox(height: 16),

                  // 4. Categorization Pill Cloud Card
                  _buildCategorizationCard(vm),
                  const SizedBox(height: 16),

                  // 5. Collapsible Advanced Details Accordion
                  _buildAdvancedDetailsCard(vm, currencySymbol),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            bottomNavigationBar: _buildStickyBottomActionBar(vm),
          );
        },
      ),
    );
  }

  // ==================== STICKY HEADER ====================

  PreferredSizeWidget _buildStickyHeader(bool isEditing) {
    return AppBar(
      backgroundColor: _bgObsidian,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Cancel',
      ),
      title: Text(
        isEditing ? 'Edit Product' : 'New Catalog Item',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: _accentSky, size: 24),
          onPressed: _openBarcodeScanner,
          tooltip: 'Scan Barcode',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: _borderSlate,
          height: 0.8,
        ),
      ),
    );
  }

  // ==================== CARD 1: HERO IDENTITY & MEDIA ====================

  Widget _buildHeroIdentityCard(ProductFormViewModel vm) {
    return PosCard(
      backgroundColor: _surfaceNavy,
      borderRadius: 16,
      border: Border.all(color: _borderSlate, width: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 88x88 px Interactive Image Square
              GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _bgObsidian,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: vm.imageFile != null || vm.imageUrl != null
                          ? _accentSky
                          : _borderSlate,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: (vm.imageFile != null ||
                                (vm.imageUrl != null && vm.imageUrl!.isNotEmpty))
                            ? ProductImageWidget(
                                localFile: vm.imageFile,
                                imageUrl: vm.imageUrl,
                                width: 88,
                                height: 88,
                                borderRadius: 14,
                                fallbackIcon: Icons.shopping_bag_outlined,
                                iconSize: 32,
                              )
                            : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_a_photo_outlined,
                                          color: _accentSky, size: 28),
                                      SizedBox(height: 4),
                                      Text(
                                        'Photo',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                      if (vm.imageFile != null ||
                          (vm.imageUrl != null && vm.imageUrl!.isNotEmpty))
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: _bgObsidian,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit,
                                size: 12, color: _accentSky),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Product Name Large Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRODUCT NAME *',
                      style: TextStyle(
                        color: _accentSky,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Organic Whole Milk 1L',
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: _bgObsidian,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _accentSky, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Displayed on register grid & print receipts',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _borderSlate, height: 1),
          const SizedBox(height: 16),

          // Barcode & SKU Row
          Row(
            children: [
              // SKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SKU (STOCK KEEPING UNIT)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _skuController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., MILK-01',
                        hintStyle: const TextStyle(color: Colors.white24),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: _bgObsidian,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _accentSky, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Barcode with attached scan button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BARCODE / UPC',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _barcodeController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., 0123456789',
                        hintStyle: const TextStyle(color: Colors.white24),
                        isDense: true,
                        contentPadding: const EdgeInsets.only(
                            left: 12, top: 12, bottom: 12, right: 4),
                        filled: true,
                        fillColor: _bgObsidian,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: _accentSky, size: 20),
                          onPressed: _openBarcodeScanner,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _accentSky, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CARD 2: DYNAMIC FINANCIAL & MARGIN ====================

  Widget _buildFinancialMarginCard(
      ProductFormViewModel vm, String currencySymbol) {
    Color marginColor = _emerald;
    String marginLabel = 'Healthy Retail Margin';
    IconData marginIcon = Icons.trending_up;

    if (vm.marginHealth == MarginHealth.loss) {
      marginColor = _crimson;
      marginLabel = vm.profit < 0
          ? 'Warning: Selling at Loss!'
          : 'Warning: Zero Margin';
      marginIcon = Icons.warning_amber_rounded;
    } else if (vm.marginHealth == MarginHealth.low) {
      marginColor = _amber;
      marginLabel = 'Thin Margin (<25%)';
      marginIcon = Icons.trending_flat;
    }

    return PosCard(
      backgroundColor: _surfaceNavy,
      borderRadius: 16,
      border: Border.all(color: _borderSlate, width: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FINANCIALS & PROFITABILITY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _bgObsidian,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _borderSlate),
                ),
                child: Text(
                  'Currency: $currencySymbol',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cost & Selling Inputs
          Row(
            children: [
              // Cost Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cost Price',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixText: '$currencySymbol ',
                        prefixStyle: const TextStyle(
                            color: Colors.white70, fontSize: 15),
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Colors.white24),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: _bgObsidian,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _accentSky, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Selling Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selling Price *',
                      style: TextStyle(
                        color: _accentSky,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixText: '$currencySymbol ',
                        prefixStyle: const TextStyle(
                            color: _accentSky,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Colors.white24),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: _bgObsidian,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _accentSky, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Live Margin Indicator Box
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: marginColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: marginColor.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              children: [
                Icon(marginIcon, color: marginColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gross Profit: $currencySymbol ${vm.profit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: marginColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: marginColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${vm.marginPercentage.toStringAsFixed(1)}% Margin',
                              style: const TextStyle(
                                color: _bgObsidian,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        marginLabel,
                        style: TextStyle(
                          color: marginColor.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CARD 3: INVENTORY & FAST UNIT CHIPS ====================

  Widget _buildInventoryUnitCard(ProductFormViewModel vm) {
    return PosCard(
      backgroundColor: _surfaceNavy,
      borderRadius: 16,
      border: Border.all(color: _borderSlate, width: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INVENTORY & UNIT OF MEASURE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Stock Stepper Row
          Row(
            children: [
              // Initial Stock with Stepper
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Initial Stock',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Decrement Button
                        InkWell(
                          onTap: () {
                            vm.decrementStock();
                            _stockController.text =
                                vm.stockQuantity.toString();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 38,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _bgObsidian,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _borderSlate),
                            ),
                            child: const Icon(Icons.remove,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Numeric Field
                        Expanded(
                          child: TextField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              filled: true,
                              fillColor: _bgObsidian,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: _borderSlate),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: _borderSlate),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: _accentSky, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Increment Button
                        InkWell(
                          onTap: () {
                            vm.incrementStock();
                            _stockController.text =
                                vm.stockQuantity.toString();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 38,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _bgObsidian,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _borderSlate),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Low Stock Warning Threshold
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Low Stock Alert',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        filled: true,
                        fillColor: _bgObsidian,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _borderSlate),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _accentSky, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Unit Selector Chips
          const Text(
            'Unit of Measurement',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProductFormViewModel.unitPresets.map((preset) {
                final isSelected = vm.unit == preset['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(preset['label']!),
                    selected: isSelected,
                    onSelected: (_) => vm.setUnit(preset['value']!),
                    backgroundColor: _bgObsidian,
                    selectedColor: _accentIndigo,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? _accentSky : _borderSlate,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CARD 4: CATEGORIZATION PILL CLOUD ====================

  Widget _buildCategorizationCard(ProductFormViewModel vm) {
    return PosCard(
      backgroundColor: _surfaceNavy,
      borderRadius: 16,
      border: Border.all(color: _borderSlate, width: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CATEGORY CLASSIFICATION',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Active: ${vm.category}',
                style: const TextStyle(
                  color: _accentSky,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wrapping Category Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // + Add Category Action Chip
              ActionChip(
                avatar: const Icon(Icons.add, color: _accentSky, size: 16),
                label: const Text('Add Category'),
                labelStyle: const TextStyle(
                  color: _accentSky,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                backgroundColor: _bgObsidian,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: _accentSky, width: 1.2),
                ),
                onPressed: _showAddCategorySheet,
              ),

              // Dynamic Categories
              ...vm.availableCategories.map((cat) {
                final isSelected = vm.category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) vm.setCategory(cat);
                  },
                  backgroundColor: _bgObsidian,
                  selectedColor: _accentIndigo,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _accentSky : _borderSlate,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  showCheckmark: false,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CARD 5: ADVANCED DETAILS ACCORDION ====================

  Widget _buildAdvancedDetailsCard(
      ProductFormViewModel vm, String currencySymbol) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return PosCard(
      backgroundColor: _surfaceNavy,
      borderRadius: 16,
      border: Border.all(color: _borderSlate, width: 1),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isAdvancedExpanded = !_isAdvancedExpanded);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune, color: _accentSky, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Advanced Details (Optional)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isAdvancedExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          if (_isAdvancedExpanded) ...[
            const Divider(color: _borderSlate, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wholesale & Promotional Sale Price Row
                  Row(
                    children: [
                      // Wholesale Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wholesale Price',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _wholesaleController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixText: '$currencySymbol ',
                                prefixStyle: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                                hintText: '0.00',
                                hintStyle:
                                    const TextStyle(color: Colors.white24),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: _bgObsidian,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: _borderSlate),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: _borderSlate),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: _accentSky, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sale / Promotional Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Special Sale Price',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _salePriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixText: '$currencySymbol ',
                                prefixStyle: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                                hintText: '0.00',
                                hintStyle:
                                    const TextStyle(color: Colors.white24),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: _bgObsidian,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: _borderSlate),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: _borderSlate),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: _accentSky, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dates Row
                  Row(
                    children: [
                      // Manufacture Date Pill
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mfg Date',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final dt = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      vm.manufactureDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (dt != null) vm.setManufactureDate(dt);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _bgObsidian,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderSlate),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: _accentSky),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        vm.manufactureDate != null
                                            ? dateFormat
                                                .format(vm.manufactureDate!)
                                            : 'Select date',
                                        style: TextStyle(
                                          color: vm.manufactureDate != null
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Expiry Date Pill
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expiry Date',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final dt = await showDatePicker(
                                  context: context,
                                  initialDate: vm.expiryDate ??
                                      DateTime.now()
                                          .add(const Duration(days: 365)),
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 30)),
                                  lastDate: DateTime(2040),
                                );
                                if (dt != null) vm.setExpiryDate(dt);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _bgObsidian,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderSlate),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_busy,
                                        size: 16, color: _crimson),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        vm.expiryDate != null
                                            ? dateFormat.format(vm.expiryDate!)
                                            : 'Select date',
                                        style: TextStyle(
                                          color: vm.expiryDate != null
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description / Notes Field
                  const Text('Internal Product Description / Notes',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Add private supplier notes, batch specifics, or specifications...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: _bgObsidian,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderSlate),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderSlate),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: _accentSky, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== STICKY FLOATING GLASS BOTTOM BAR ====================

  Widget _buildStickyBottomActionBar(ProductFormViewModel vm) {
    final isEnabled = vm.isValid && !vm.isSaving;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _bgObsidian.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: _borderSlate, width: 0.8),
          ),
        ),
        child: Row(
              children: [
                // Left Summary Chip: Margin % or SKU
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _surfaceNavy,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderSlate),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vm.marginHealth == MarginHealth.loss
                            ? Icons.trending_down
                            : Icons.trending_up,
                        size: 16,
                        color: vm.marginHealth == MarginHealth.loss
                            ? _crimson
                            : _emerald,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${vm.marginPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: vm.marginHealth == MarginHealth.loss
                              ? _crimson
                              : _emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right: Gradient Save Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isEnabled
                            ? const LinearGradient(
                                colors: [Color(0xFF0284C7), _accentIndigo],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isEnabled ? null : _borderSlate,
                        boxShadow: isEnabled
                            ? [
                                BoxShadow(
                                  color: _accentIndigo.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: isEnabled ? _submitProduct : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.white38,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: vm.isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                widget.isEditing
                                    ? 'Update Product'
                                    : 'Save Item to Catalog',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
