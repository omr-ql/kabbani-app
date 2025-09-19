import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import 'product_details_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.searchProducts(
        '',
        category: widget.category == 'All' ? null : widget.category,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getCategoryLocalizedName(String category, AppLocalizations l10n) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedCategoryName = _getCategoryLocalizedName(widget.category, l10n);

    return Scaffold(
      backgroundColor: Colors.black, // Changed to black
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // Dark app bar
        elevation: 0,
        title: Text(
          '${localizedCategoryName} ${l10n.products}',
          style: const TextStyle(color: Colors.white), // White text
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white), // White icon
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4B4B),
        ),
      )
          : _products.isEmpty
          ? Center(
        child: Text(
          '${l10n.noProductsFoundIn} ${localizedCategoryName}',
          style: const TextStyle(color: Colors.white), // White text
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900], // Dark container
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Icon(Icons.shopping_bag, size: 40, color: Colors.white),
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
                      color: Colors.white, // White text
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.idLabel}: ${product.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey, // Grey text
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4B4B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
