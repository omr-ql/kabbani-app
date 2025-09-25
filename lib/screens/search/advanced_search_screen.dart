import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../products/product_details_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final Function(Product?)? onSearchPerformed;

  const AdvancedSearchScreen({Key? key, this.onSearchPerformed}) : super(key: key);

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  List<Product> _allProducts = [];
  List<String> _availableCategories = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load categories first
      final categories = await ApiService.getCategories();

      // Load products
      final products = await ApiService.getAllProducts();

      setState(() {
        _availableCategories = ['All', ...categories];
        _allProducts = products;
        _searchResults = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = _allProducts;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await ApiService.searchProducts(
        query.trim(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        sortBy: _sortBy,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Call the callback if provided
      if (widget.onSearchPerformed != null && results.isNotEmpty) {
        widget.onSearchPerformed!(results.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Search failed: $e';
      });
    }
  }

  void _filterResults() {
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch(_searchController.text.trim());
      return;
    }

    List<Product> filtered = List.from(_allProducts);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) =>
      p.category.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }

    // Apply sorting
    _applySorting(filtered);

    setState(() {
      _searchResults = filtered;
    });
  }

  void _applySorting(List<Product> products) {
    switch (_sortBy) {
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_high':
        products.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'discount':
        products.sort((a, b) => _getDiscountPercentage(b).compareTo(_getDiscountPercentage(a)));
        break;
    }
  }

  // Helper method to get discount percentage from product
  double _getDiscountPercentage(Product product) {
    if (!product.hasDiscount) return 0.0;
    return product.discount; // Use the actual discount value from the Product model
  }

  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
      case 'all':
        return l10n.all;
      case 'furniture':
        return l10n.furniture;
      case 'carpets':
        return l10n.carpets;
      case 'linens':
        return l10n.linens;
      case 'general':
        return l10n.general;
      default:
        return category;
    }
  }

  void _navigateToProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: Text(
          l10n.searchProducts,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFFFF4B4B)),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section
          _buildSearchSection(l10n),

          // Results Count and Sort Section
          if (_searchController.text.isNotEmpty || _selectedCategory != 'All')
            _buildResultsHeaderSection(l10n),

          // Main Content Section
          Expanded(
            child: _buildMainContent(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[900],
      child: Column(
        children: [
          // Search TextField
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                if (value.isEmpty) {
                  _filterResults();
                }
              },
              onSubmitted: (value) => _performSearch(value),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = _allProducts;
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Category Filter Chips
          if (_availableCategories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableCategories.map((category) {
                  final localizedName = _getLocalizedCategory(category, l10n);
                  return _buildFilterChip(localizedName, _selectedCategory == category, category);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsHeaderSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_searchResults.length} ${l10n.resultsFound}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _filterResults();
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: 'name',
                    child: Text(l10n.sortName, style: const TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'price_low',
                    child: Text(l10n.sortPriceLow, style: const TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'price_high',
                    child: Text(l10n.sortPriceHigh, style: const TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'discount',
                    child: Text(l10n.sortDiscount, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF4B4B)),
            SizedBox(height: 20),
            Text(
              'Loading products...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty
                  ? l10n.startSearching
                  : l10n.noProductsFound,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            if (_searchController.text.isNotEmpty || _selectedCategory != 'All') ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategory = 'All';
                  });
                  _filterResults();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4B4B),
                  side: const BorderSide(color: Color(0xFFFF4B4B)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, String category) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF4B4B) : Colors.white,
          ),
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = category;
            _filterResults();
          });
        },
        backgroundColor: Colors.grey[800],
        selectedColor: const Color(0xFFFF4B4B).withOpacity(0.2),
        checkmarkColor: const Color(0xFFFF4B4B),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final l10n = AppLocalizations.of(context)!;
    final discountPercentage = _getDiscountPercentage(product);

    return GestureDetector(
      onTap: () => _navigateToProductDetails(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(product.category),
                    _getCategoryColor(product.category).withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.idLabel}: ${product.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCategoryColor(product.category),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF4B4B),
                            ),
                          ),
                          if (product.hasDiscount)
                            Text(
                              '\$${product.originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      if (product.hasDiscount && discountPercentage > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'furniture':
        return const Color(0xFF667EEA);
      case 'carpets':
        return const Color(0xFFFF6B9D);
      case 'linens':
        return const Color(0xFF48C9B0);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'furniture':
        return Icons.weekend;
      case 'carpets':
        return Icons.texture;
      case 'linens':
        return Icons.king_bed;
      default:
        return Icons.category;
    }
  }

  void _showFilterBottomSheet() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.filterSort,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategory = 'All';
                                _sortBy = 'name';
                              });
                              _filterResults();
                            },
                            child: Text(
                              l10n.reset,
                              style: const TextStyle(color: Color(0xFFFF4B4B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category Section
                      Text(
                        'Category',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: _availableCategories.map((category) {
                          final localizedName = _getLocalizedCategory(category, l10n);
                          return ChoiceChip(
                            label: Text(localizedName, style: const TextStyle(color: Colors.white)),
                            selected: _selectedCategory == category,
                            backgroundColor: Colors.grey[800],
                            selectedColor: const Color(0xFFFF4B4B).withOpacity(0.3),
                            onSelected: (selected) {
                              setModalState(() => _selectedCategory = category);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Sort Section
                      Text(
                        l10n.sortBy,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.sortName, style: const TextStyle(color: Colors.white)),
                            selected: _sortBy == 'name',
                            backgroundColor: Colors.grey[800],
                            selectedColor: const Color(0xFFFF4B4B).withOpacity(0.3),
                            onSelected: (selected) {
                              setModalState(() => _sortBy = 'name');
                            },
                          ),
                          ChoiceChip(
                            label: Text(l10n.sortPriceLow, style: const TextStyle(color: Colors.white)),
                            selected: _sortBy == 'price_low',
                            backgroundColor: Colors.grey[800],
                            selectedColor: const Color(0xFFFF4B4B).withOpacity(0.3),
                            onSelected: (selected) {
                              setModalState(() => _sortBy = 'price_low');
                            },
                          ),
                          ChoiceChip(
                            label: Text(l10n.sortPriceHigh, style: const TextStyle(color: Colors.white)),
                            selected: _sortBy == 'price_high',
                            backgroundColor: Colors.grey[800],
                            selectedColor: const Color(0xFFFF4B4B).withOpacity(0.3),
                            onSelected: (selected) {
                              setModalState(() => _sortBy = 'price_high');
                            },
                          ),
                          ChoiceChip(
                            label: Text(l10n.sortDiscount, style: const TextStyle(color: Colors.white)),
                            selected: _sortBy == 'discount',
                            backgroundColor: Colors.grey[800],
                            selectedColor: const Color(0xFFFF4B4B).withOpacity(0.3),
                            onSelected: (selected) {
                              setModalState(() => _sortBy = 'discount');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _filterResults();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4B4B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.applyFilters,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}