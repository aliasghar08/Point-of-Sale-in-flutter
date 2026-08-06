import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/cache_service.dart';
import 'package:pos/services/format_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/services/export_service.dart';
import 'package:pos/services/sample_data_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/stat_badge.dart';
import 'package:pos/widgets/category_pill.dart';
import 'package:pos/widgets/empty_state_view.dart';
import 'package:pos/screens/product_form_screen.dart';

/// Modern Inventory & Stock Management Screen.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final CacheService _cache = CacheService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _stockFilter = 'all'; // 'all', 'low', 'out'
  bool _isGridView = false;
  bool _isSeeding = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      setState(() => _searchQuery = val);
    });
  }

  Future<void> _seedSampleCatalog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Demo Products?'),
        content: const Text(
          'This will add 12+ realistic sample products with categories, barcodes, SKUs, and stock to your catalog.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Load Demo Products')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final count = await SampleDataService.seedSampleProducts();
      FeedbackService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded $count demo products!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      FeedbackService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading demo products: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _exportCatalog(List<Product> products) {
    final csv = ExportService.exportProductsToCsv(products);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported Inventory CSV'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV ready! You can copy text from the dialog.'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStock(Product product, int delta) async {
    final newStock = (product.stock + delta).clamp(0, 99999);
    try {
      await _firebaseService.updateProductStock(product.id, newStock);
      _cache.upsertProduct(product.copyWith(stock: newStock));
      FeedbackService.lightTap();
    } catch (e) {
      FeedbackService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stock: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteProduct(product.id);
        _cache.removeProduct(product.id);
        FeedbackService.success();
      } catch (e) {
        FeedbackService.error();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
        },
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.productsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_cache.hasValidProductCache) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Product> products = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            products = snapshot.data!.docs.map((doc) {
              return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
            _cache.setProducts(products);
          } else if (_cache.hasValidProductCache) {
            products = _cache.allProducts;
          }

          // Calculate Inventory Metrics
          final totalSkus = products.length;
          final lowStockCount = products.where((p) => p.stock > 0 && p.stock <= p.minStock).length;
          final outOfStockCount = products.where((p) => p.stock <= 0).length;
          final totalValuation = products.fold(0.0, (prev, p) => prev + (p.price * p.stock));

          // Filter Products
          final filtered = products.where((p) {
            // Stock state
            if (_stockFilter == 'low' && (p.stock <= 0 || p.stock > p.minStock)) return false;
            if (_stockFilter == 'out' && p.stock > 0) return false;

            // Category
            if (_selectedCategory != 'All' && p.category != _selectedCategory) return false;

            // Search query
            if (_searchQuery.trim().isNotEmpty) {
              final q = _searchQuery.trim().toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q) ||
                  p.barcode.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Search & Top Actions
              _buildTopBar(isDark, products),

              // KPI Stats Banner
              _buildStatsBar(
                totalSkus: totalSkus,
                lowStock: lowStockCount,
                outOfStock: outOfStockCount,
                valuation: totalValuation,
                currencySymbol: currencySymbol,
                isDark: isDark,
              ),

              // Filter Chips
              _buildFilterChips(isDark),

              // Product List / Grid
              Expanded(
                child: _isSeeding
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? EmptyStateView(
                            icon: Icons.inventory_2_outlined,
                            title: 'No inventory items match',
                            description: products.isEmpty
                                ? 'Your inventory is currently empty. Add your first item or load demo products!'
                                : 'No products match the selected search and filter criteria.',
                            actionLabel: products.isEmpty ? 'Load Demo Catalog' : 'Add New Product',
                            onAction: products.isEmpty
                                ? _seedSampleCatalog
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                                    ),
                          )
                        : _isGridView
                            ? _buildGridView(filtered, currencySymbol, isDark)
                            : _buildListView(filtered, currencySymbol, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== SUB-COMPONENTS ====================

  Widget _buildTopBar(bool isDark, List<Product> allProducts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products by name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _exportCatalog(allProducts),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Seed Demo Products',
            onPressed: _seedSampleCatalog,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar({
    required int totalSkus,
    required int lowStock,
    required int outOfStock,
    required double valuation,
    required String currencySymbol,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Total SKUs',
              value: '$totalSkus',
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Low Stock',
              value: '$lowStock',
              color: AppColors.warning,
              isDark: isDark,
              isSelected: _stockFilter == 'low',
              onTap: () => setState(() => _stockFilter = _stockFilter == 'low' ? 'all' : 'low'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Out of Stock',
              value: '$outOfStock',
              color: AppColors.error,
              isDark: isDark,
              isSelected: _stockFilter == 'out',
              onTap: () => setState(() => _stockFilter = _stockFilter == 'out' ? 'all' : 'out'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Stock Value',
              value: FormatService.formatCurrency(valuation, symbol: currencySymbol),
              color: AppColors.success,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return PosCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: onTap,
      backgroundColor: isSelected ? color.withValues(alpha: 0.15) : null,
      border: isSelected ? Border.all(color: color, width: 1.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final categories = _cache.allCategories;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;
          return CategoryPill(
            title: cat,
            isSelected: isSelected,
            onTap: () {
              setState(() => _selectedCategory = cat);
              FeedbackService.lightTap();
            },
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Product> products, String currencySymbol, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = products[i];

        return PosCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryLight.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatBadge.stock(stock: p.stock, minStock: p.minStock),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.category} • SKU: ${p.sku.isNotEmpty ? p.sku : '-'} • Price: ${FormatService.formatCurrency(p.price, symbol: currencySymbol)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Inline Stock Adjust Buttons
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    tooltip: 'Decrease Stock',
                    onPressed: () => _adjustStock(p, -1),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${p.stock}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    tooltip: 'Increase Stock',
                    onPressed: () => _adjustStock(p, 1),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)),
                        );
                      } else if (val == 'delete') {
                        _deleteProduct(p);
                      } else if (val == 'add5') {
                        _adjustStock(p, 5);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'add5', child: Text('Add +5 Units')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Product> products, String currencySymbol, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final p = products[i];

        return PosCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatBadge.stock(stock: p.stock, minStock: p.minStock),
                ],
              ),
              const Spacer(),
              Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                FormatService.formatCurrency(p.price, symbol: currencySymbol),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.success : AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () => _adjustStock(p, -1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      Text('${p.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => _adjustStock(p, 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}