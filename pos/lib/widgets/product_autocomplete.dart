import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pos/models/product_reference.dart';

class ProductAutocomplete extends StatefulWidget {
  final Function(String) onProductSelected;
  final String? category;
  final String hintText;
  final FocusNode focusNode;

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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (!widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !widget.focusNode.hasFocus) {
          _hideOverlay();
        }
      });
    } else if (_suggestions.isNotEmpty && _controller.text.isNotEmpty) {
      _showOverlay();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideOverlay();
    widget.focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _searchProducts(query);
    });
  }

  void _searchProducts(String query) {
    if (!mounted) return;

    if (query.isEmpty) {
      _hideOverlay();
      setState(() {
        _suggestions = [];
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
          _isLoading = false;
        });

        if (widget.focusNode.hasFocus && results.isNotEmpty) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _hideOverlay();
      }
    }
  }

  void _selectProduct(String product) {
    _controller.text = product;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: product.length),
    );
    _hideOverlay();
    setState(() {
      _suggestions = [];
    });
    widget.focusNode.unfocus();
    widget.onProductSelected(product);
  }

  void _showOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hideOverlay();
      if (_suggestions.isNotEmpty && widget.focusNode.hasFocus) {
        final overlay = Overlay.maybeOf(context);
        if (overlay != null) {
          _overlayEntry = _createOverlayEntry();
          overlay.insert(_overlayEntry!);
        }
      }
    });
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final renderBox = this.context.findRenderObject() as RenderBox?;
        final size = renderBox?.size ?? const Size(300, 50);
        final isDarkMode = Theme.of(this.context).brightness == Brightness.dark;

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _suggestions.isEmpty && _controller.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No products found.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final product = _suggestions[index];
                          final isLast = index == _suggestions.length - 1;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) => _selectProduct(product),
                            onTap: () => _selectProduct(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? (index % 2 == 0 ? Colors.grey.shade800 : Colors.grey.shade900)
                                    : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                borderRadius: isLast
                                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                    : BorderRadius.zero,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isDarkMode
                                        ? Colors.blue.shade900
                                        : Colors.blue.shade100,
                                    radius: 14,
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          product,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Tap to add to cart',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: isDarkMode
                                        ? Colors.green.shade400
                                        : Colors.green.shade700,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            focusNode: widget.focusNode,
            onChanged: _onSearchChanged,
            onTap: () {
              if (_suggestions.isNotEmpty && _controller.text.isNotEmpty) {
                _showOverlay();
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
                        _hideOverlay();
                        setState(() {
                          _suggestions = [];
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
                if (_suggestions.length == 1) {
                  _selectProduct(_suggestions.first);
                } else {
                  _selectProduct(value);
                }
              }
            },
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(4.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}