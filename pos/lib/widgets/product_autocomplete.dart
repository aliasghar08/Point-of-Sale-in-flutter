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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
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
      
      setState(() {
        _suggestions = results;
        _showSuggestions = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category indicator
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
          focusNode: _focusNode,
          onChanged: _searchProducts,
          onTap: () {
            if (_controller.text.isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
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
        ),
        
        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
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
                        _highlightMatch(product, _controller.text),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () {
                        _controller.text = product;
                        setState(() => _showSuggestions = false);
                        widget.onProductSelected(product);
                      },
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
      ],
    );
  }

  String _highlightMatch(String text, String query) {
    if (query.isEmpty) return text;
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);
    
    if (startIndex == -1) return text;
    
    final endIndex = startIndex + query.length;
    return text.substring(0, startIndex) +
        text.substring(startIndex, endIndex) +
        text.substring(endIndex);
  }
}