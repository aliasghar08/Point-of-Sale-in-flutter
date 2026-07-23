import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pos/models/product_reference.dart';

class ProductAutocomplete extends StatefulWidget {
  final Function(String) onProductSelected;
  final String? category;
  final String hintText;
  final FocusNode focusNode; // ✅ Now properly required and utilized

  const ProductAutocomplete({
    super.key,
    required this.onProductSelected,
    required this.focusNode,
    this.category,
    this.hintText = 'Search products...',
  });

  @override
  State<ProductAutocomplete> createState() => _ProductAutocompleteState();
}

class _ProductAutocompleteState extends State<ProductAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  Timer? _debounce; // ✅ Added to prevent rapid-fire searching

  @override
  void initState() {
    super.initState();
    debugPrint('📦 Available categories: ${ProductReference.getCategories()}');
    
    // ✅ Listen to focus changes to hide suggestions when tapping outside
    widget.focusNode.addListener(() {
      if (!widget.focusNode.hasFocus && mounted) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    // ⚠️ Do NOT dispose widget.focusNode here! The parent (HomeScreen) owns it.
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // ✅ Debounce for 300ms to prevent lag while typing fast
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchProducts(query);
    });
  }

  void _searchProducts(String query) {
    if (!mounted) return;
    
    debugPrint('🔍 Searching for: "$query"');
    
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
      
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error searching: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectProduct(String product) {
    _controller.text = product; // Can keep or clear this depending on your UX preference
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    
    // Optional: Clear the text field immediately after selection so it's ready for the next scan/search
    _controller.clear(); 
    
    widget.focusNode.unfocus();
    widget.onProductSelected(product);
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
        
        // Search field
        TextField(
          controller: _controller,
          focusNode: widget.focusNode, // ✅ USING THE PARENT'S FOCUS NODE
          onChanged: _onSearchChanged, // ✅ Using debounced search
          onTap: () {
            // Show suggestions when tapping if there are any
            if (_suggestions.isNotEmpty && _controller.text.isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
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
                      widget.focusNode.requestFocus();
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
              // If they hit enter, and there's a perfect match or only 1 suggestion, pick it.
              // Otherwise, just do a standard search lookup in parent.
              if (_suggestions.length == 1) {
                 _selectProduct(_suggestions.first);
              } else {
                 _selectProduct(value);
              }
            }
          },
        ),
        
        // Loading indicator
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
        
        // ✅ Suggestions dropdown - shown as overlay
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final product = _suggestions[index];
                final isLast = index == _suggestions.length - 1;

                return InkWell(
                  onTap: () => _selectProduct(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? (index % 2 == 0 ? Colors.grey.shade800 : Colors.grey.shade800)
                          : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                      borderRadius: isLast 
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            )
                          : BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDarkMode 
                              ? Colors.blue.shade900 
                              : Colors.blue.shade100,
                          radius: 16,
                          child: Text(
                            product.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode 
                                  ? Colors.blue.shade400 
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Tap to add to cart',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline,
                          size: 22,
                          color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        
        // No results message
        if (_controller.text.isNotEmpty && !_isLoading && _suggestions.isEmpty && _showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
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
      ],
    );
  }
}