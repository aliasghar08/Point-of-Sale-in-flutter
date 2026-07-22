import 'package:flutter/material.dart';
import 'package:pos/models/product_reference.dart';

class ProductAutocomplete extends StatefulWidget {
  final Function(String) onProductSelected;
  final String? category;
  final String hintText;

  const ProductAutocomplete({
    super.key,
    required this.onProductSelected,
    this.category,
    this.hintText = 'Search products...',
  });

  @override
  State<ProductAutocomplete> createState() => _ProductAutocompleteState();
}

class _ProductAutocompleteState extends State<ProductAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    
    // Debug: Print available categories to verify data
    print('📦 Available categories: ${ProductReference.getCategories()}');
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Only show suggestions when focused and there are suggestions
    if (_focusNode.hasFocus && _suggestions.isNotEmpty && !_isSelecting) {
      setState(() => _showSuggestions = true);
    } else if (!_focusNode.hasFocus && !_isSelecting) {
      // Delay hiding to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isSelecting) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  void _searchProducts(String query) {
    print('🔍 Searching for: "$query"');
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = ProductReference.searchProducts(
        query: query,
        category: widget.category,
        limit: 15,
      );
      
      print('📊 Found ${results.length} results for "$query"');
      print('📋 Results: $results');
      
      setState(() {
        _suggestions = results;
        // ✅ Force show suggestions if there are results
        _showSuggestions = results.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error searching: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectProduct(String product) {
    _isSelecting = true;
    _controller.text = product;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
    widget.onProductSelected(product);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _isSelecting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.category != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Category: ${widget.category}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _searchProducts,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _selectProduct(value);
            }
          },
        ),
        
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        
        // ✅ Suggestions dropdown - wrapped in Material to fix ListTile error
        if (_showSuggestions && _suggestions.isNotEmpty)
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final product = _suggestions[index];
                  final isLast = index == _suggestions.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDarkMode 
                              ? Colors.blue.shade900 
                              : Colors.blue.shade100,
                          radius: 18,
                          child: Text(
                            product.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode 
                                  ? Colors.blue.shade400 
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        title: Text(
                          product,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Tap to add',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline,
                          size: 24,
                          color: isDarkMode ? Colors.green.shade400 : Colors.green,
                        ),
                        onTap: () => _selectProduct(product),
                      ),
                      if (!isLast)
                        Divider(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                          height: 1,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        
        // Show if no results found
        if (_controller.text.isNotEmpty && !_isLoading && _suggestions.isEmpty && _showSuggestions)
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No products found. Try a different search term.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}