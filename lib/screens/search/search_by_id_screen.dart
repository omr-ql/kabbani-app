import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../products/product_details_screen.dart';

class SearchByIdScreen extends StatefulWidget {
  final Function(Product?)? onSearchPerformed;
  final VoidCallback? onBackToHome;
  const SearchByIdScreen({Key? key, this.onSearchPerformed, this.onBackToHome})
    : super(key: key);

  @override
  State<SearchByIdScreen> createState() => _SearchByIdScreenState();
}

class _SearchByIdScreenState extends State<SearchByIdScreen> {
  final _searchController = TextEditingController();
  Product? _searchResult;
  bool _isSearching = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchProduct(String id) async {
    if (id.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _searchResult = null;
    });

    try {
      final product = await ApiService.searchProductById(id.trim());
      setState(() {
        _searchResult = product;
        _isSearching = false;
        if (product == null) {
          _errorMessage = 'Product not found with ID: ${id.trim()}';
        }
      });

      // Call the callback if provided
      if (widget.onSearchPerformed != null) {
        widget.onSearchPerformed!(product);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching for product: $e';
      });
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

  // Handle back navigation - go to home screen
  void _handleBackNavigation() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!(); // Reset to home tab
      Navigator.pop(context); // Pop current screen
    } else {
      Navigator.pop(context); // Default back behavior
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false; // We handle the navigation manually
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          centerTitle: true,
          title: Text(
            l10n.searchByID,
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _handleBackNavigation,
          ),
          actions: [
            if (_searchResult != null)
              IconButton(
                icon: const Icon(Icons.launch, color: Color(0xFFFF4B4B)),
                onPressed: () => _navigateToProductDetails(_searchResult!),
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Section
                Container(
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
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _searchProduct(value),
                    decoration: InputDecoration(
                      hintText: l10n.enterProductID,
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResult = null;
                                  _errorMessage = '';
                                });
                              },
                            ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF4B4B),
                                    Color(0xFFFF6B6B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () =>
                                _searchProduct(_searchController.text),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Results Section
                _buildResultsSection(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(AppLocalizations l10n) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF4B4B)),
            const SizedBox(height: 20),
            Text(
              l10n.searchingForProduct, // Localized
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 60, color: Colors.grey[600]),
              const SizedBox(height: 15),
              Text(
                l10n.enterProductIdToSearch, // Localized
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.scanBarcodeOrType, // Localized
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResult != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Main Product Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4B4B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${l10n.idLabel}: ${_searchResult!.id}', // Localized
                          style: const TextStyle(
                            color: Color(0xFFFF4B4B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_searchResult!.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              _searchResult!.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _searchResult!.category,
                            style: TextStyle(
                              color: _getCategoryColor(_searchResult!.category),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  Text(
                    _searchResult!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Price Information (REMOVED "Current Price" label)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${_searchResult!.effectivePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF4B4B),
                              ),
                            ),
                          ],
                        ),
                        if (_searchResult!.hasDiscount)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.originalPrice, // Localized
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${_searchResult!.originalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${_searchResult!.discountPercentage.toStringAsFixed(0)}%',
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warehouse & Inventory Information (if available)
            if (_searchResult!.warehouseName != null &&
                _searchResult!.warehouseName!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warehouse,
                          color: Colors.orange[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.warehouseAndInventory, // Localized
                          style: TextStyle(
                            color: Colors.orange[300],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_searchResult!.warehouseName != null &&
                        _searchResult!.warehouseName!.isNotEmpty)
                      _buildInfoRow(
                        l10n,
                        l10n.warehouse,
                        _searchResult!.warehouseName!,
                      ),

                    if (_searchResult!.sector != null &&
                        _searchResult!.sector!.isNotEmpty)
                      _buildInfoRow(l10n, l10n.sector, _searchResult!.sector!),

                    if (_searchResult!.currentQuantity != null)
                      _buildInfoRow(
                        l10n,
                        l10n.availableQuantitynow,
                        _searchResult!.currentQuantity.toString(),
                      ),

                    if (_searchResult!.totalValue != null &&
                        _searchResult!.totalValue! > 0)
                      _buildInfoRow(
                        l10n,
                        l10n.inventoryValue,
                        '\$${_searchResult!.totalValue!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToProductDetails(_searchResult!),
                    icon: const Icon(Icons.launch, size: 18),
                    label: Text(l10n.fullDetails), // Localized
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Clear results to search again
                    _searchController.clear();
                    setState(() {
                      _searchResult = null;
                      _errorMessage = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.search, size: 18),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Empty state
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 15),
            Text(
              l10n.enterProductIdToSearch, // Localized
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppLocalizations l10n, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
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
}
