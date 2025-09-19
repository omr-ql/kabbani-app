import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

class SearchByIdScreen extends StatefulWidget {
  final Function(Product?)? onSearchPerformed;
  const SearchByIdScreen({Key? key, this.onSearchPerformed}) : super(key: key);

  @override
  State<SearchByIdScreen> createState() => _SearchByIdScreenState();
}

class _SearchByIdScreenState extends State<SearchByIdScreen> {
  final _searchController = TextEditingController();
  Product? _searchResult;
  bool _isSearching = false;
  String _errorMessage = '';

  void _searchProduct(String id) async {
    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _searchResult = null;
    });

    try {
      final product = await ApiService.searchProductById(id);
      setState(() {
        _searchResult = product;
        _isSearching = false;
        if (product == null) {
          _errorMessage = 'Product not found with ID: $id';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black, // Changed to black
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // Dark app bar
        elevation: 0,
        title: Text(
          l10n.searchByID,
          style: const TextStyle(color: Colors.white),
        ), // White text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white), // White icon
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
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
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white), // White text
                onSubmitted: (value) {
                  if (value.isNotEmpty) _searchProduct(value);
                },
                decoration: InputDecoration(
                  hintText: l10n.enterProductID,
                  hintStyle: const TextStyle(color: Colors.grey), // Grey hint
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchProduct(_searchController.text);
                      }
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.tryTheseIDs,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ), // White text
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                '2501000010100002',
                '2501000010100003',
                '2501000010100004',
              ].map((id) => GestureDetector(
                onTap: () {
                  _searchController.text = id;
                  _searchProduct(id);
                },
                child: Chip(
                  label: Text(
                    id,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ), // White text
                  backgroundColor: const Color(0xFFFF4B4B).withOpacity(0.2), // Darker chip background
                ),
              )).toList(),
            ),
            const SizedBox(height: 30),
            if (_isSearching)
              const CircularProgressIndicator(color: Color(0xFFFF4B4B))
            else if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[900], // Dark red background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[300]),
                      ),
                    ), // Light red text
                  ],
                ),
              )
            else if (_searchResult != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900], // Dark container
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[800], // Darker grey
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${l10n.idLabel}: ${_searchResult!.id}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ), // Grey text
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchResult!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ), // White text
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.priceLabel,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '\$${_searchResult!.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF4B4B),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    l10n.originalPriceLabel,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '\$${_searchResult!.originalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
