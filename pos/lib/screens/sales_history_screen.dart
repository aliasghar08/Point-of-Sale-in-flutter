import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pos/models/sale.dart';
import 'package:pos/services/firebase_service.dart';
import 'package:pos/services/format_service.dart';
import 'package:pos/services/receipt_service.dart';
import 'package:pos/services/export_service.dart';
import 'package:pos/services/feedback_service.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/providers/auth_provider.dart';
import 'package:pos/theme/app_colors.dart';
import 'package:pos/widgets/pos_card.dart';
import 'package:pos/widgets/stat_badge.dart';
import 'package:pos/widgets/empty_state_view.dart';

/// Modern Sales History & Transaction Archive Screen.
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String _filterType = 'Today'; // 'Today', 'Week', 'Month', 'All', 'Custom'
  String _searchQuery = '';
  bool _isLoading = true;
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];

  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot;
      switch (_filterType) {
        case 'Today':
          snapshot = await _firebaseService.getTodaySales();
          break;
        case 'Week':
          snapshot = await _firebaseService.getWeekSales();
          break;
        case 'Month':
          snapshot = await _firebaseService.getMonthSales();
          break;
        case 'Custom':
          if (_startDate != null && _endDate != null) {
            snapshot = await _firebaseService.getSalesByDateRange(
              startDate: _startDate!,
              endDate: _endDate!,
              limit: 500,
            );
          } else {
            snapshot = await _firebaseService.getTodaySales();
          }
          break;
        case 'All':
        default:
          snapshot = await _firebaseService.getAllSales();
          break;
      }

      final loaded = snapshot.docs.map((doc) {
        return Sale.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      setState(() {
        _sales = loaded;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackService.error();
    }
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredSales = List.from(_sales);
      return;
    }

    final q = _searchQuery.trim().toLowerCase();
    _filteredSales = _sales.where((s) {
      return s.receiptNumber.toLowerCase().contains(q) ||
          s.productName.toLowerCase().contains(q) ||
          s.customerDisplayName.toLowerCase().contains(q) ||
          s.customerPhone.toLowerCase().contains(q) ||
          s.paymentMethod.toLowerCase().contains(q);
    }).toList();
  }

  void _exportSales() {
    final csv = ExportService.exportSalesToCsv(_filteredSales);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported Sales Transactions (CSV)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
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
                const SnackBar(content: Text('Transactions copied to clipboard / exported!'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _reprintReceipt(Sale sale) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final pdf = await ReceiptService.generatePdfReceipt(
      businessName: 'Point of Sale Retail',
      receiptNumber: sale.receiptNumber,
      date: sale.saleDate,
      cashierName: authProvider.currentUser?.name ?? 'Staff',
      customerName: sale.customerDisplayName,
      items: [
        {
          'name': sale.productName,
          'qty': sale.quantity,
          'price': sale.price,
          'total': sale.total,
        }
      ],
      subtotal: sale.total,
      tax: 0.0,
      discount: 0.0,
      grandTotal: sale.total,
      paymentMethod: sale.paymentMethod,
      currencySymbol: settingsProvider.currencySymbol,
    );

    await ReceiptService.printReceipt(pdf);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currencySymbol = settingsProvider.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Financial Metrics
    final totalRevenue = _filteredSales.fold(0.0, (prev, s) => prev + s.total);
    final totalProfit = _filteredSales.fold(0.0, (prev, s) => prev + s.profit);
    final totalCount = _filteredSales.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History & Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exportSales,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSales,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Search
          _buildFilterBar(isDark),

          // Overview KPI Card
          _buildKpiSummary(
            revenue: totalRevenue,
            profit: totalProfit,
            count: totalCount,
            currencySymbol: currencySymbol,
            isDark: isDark,
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No sales records found',
                        description: 'Try changing your date filter or search query.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSales.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _buildSaleCard(_filteredSales[i], currencySymbol, isDark),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final options = ['Today', 'Week', 'Month', 'All'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (val) {
              _searchQuery = val;
              setState(() => _applySearch());
            },
            decoration: InputDecoration(
              hintText: 'Search by Receipt #, Customer, or Product...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          // Time Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isSelected = _filterType == opt;
                final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(opt),
                    selected: isSelected,
                    selectedColor: primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: primaryColor,
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryColor : null,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _filterType = opt;
                        _loadSales();
                      });
                      FeedbackService.lightTap();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummary({
    required double revenue,
    required double profit,
    required int count,
    required String currencySymbol,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: PosCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Sales', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    FormatService.formatCurrency(revenue, symbol: currencySymbol),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PosCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Net Profit', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    FormatService.formatCurrency(profit, symbol: currencySymbol),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PosCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orders', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale, String currencySymbol, bool isDark) {
    return PosCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryLight.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sale.receiptNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatBadge(label: sale.paymentMethod, type: BadgeType.info),
                ],
              ),
              Text(
                FormatService.formatCurrency(sale.total, symbol: currencySymbol),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${sale.quantity}x ${sale.productName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                FormatService.formatDateTime(sale.saleDate),
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer: ${sale.customerDisplayName}',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              TextButton.icon(
                onPressed: () => _reprintReceipt(sale),
                icon: const Icon(Icons.print, size: 14),
                label: const Text('Re-Print', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }
}