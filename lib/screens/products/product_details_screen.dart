import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';
import 'dart:async';
class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _userToken;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadProduct();
  }

  Future<void> _checkAdminStatus() async {
    try {
      print('🔍 DEBUG: Starting admin status check...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userRole = prefs.getString('user_role');

      print('🔍 DEBUG: Token exists: ${token != null}');
      print('🔍 DEBUG: User role from prefs: $userRole');

      // Simple role check - no API call needed
      final isAdmin = (token != null && userRole == 'admin');

      setState(() {
        _isAdmin = isAdmin;
        _userToken = token;
      });

      print('🔍 DEBUG: Final _isAdmin value: $_isAdmin');

    } catch (e) {
      print('❌ DEBUG: Error checking admin status: $e');
      setState(() {
        _isAdmin = false;
        _userToken = null;
      });
    }
  }


  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final product = await ApiService.searchProductById(widget.productId);

      setState(() {
        _product = product;
        _isLoading = false;
        if (product == null) {
          _errorMessage = 'Product not found: ${widget.productId}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading product: $e';
      });
    }
  }

  Future<void> _showEditQuantityDialog() async {
    if (_product == null || !_isAdmin || _userToken == null) return;

    final TextEditingController quantityController = TextEditingController();
    quantityController.text = _product!.currentQuantity.toString();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Edit Quantity',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (_product!.warehouseName.isNotEmpty)
                        Text(
                          'Warehouse: ${_product!.warehouseName}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Current: ',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '${_product!.currentQuantity}',
                            style: TextStyle(
                              color: _product!.currentQuantity == 0 ? Colors.red : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' units',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // New Quantity Input
                Text(
                  'New Quantity:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFFF4B4B), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    hintText: 'Enter quantity (0 or more)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.inventory, color: Colors.grey[400]),
                  ),
                ),
                SizedBox(height: 12),

                // Helper text
                Text(
                  'Enter the new quantity for this product. This will update the inventory immediately.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newQuantityText = quantityController.text.trim();
                final newQuantity = int.tryParse(newQuantityText);

                if (newQuantity == null || newQuantity < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid quantity (0 or more)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _updateQuantity(newQuantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF4B4B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Beautiful success animation
  void _showSuccessAnimation(int newQuantity) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[800]!, Colors.green[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with animation
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                '✅ Quantity Updated!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_product!.currentQuantity} → $newQuantity units',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Inventory has been updated successfully',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-close after 2 seconds
    Timer(Duration(seconds: 2), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

// Beautiful error message
  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[800]!, Colors.red[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                '❌ Update Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[600],
                ),
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _updateQuantity(int newQuantity) async {
    if (_userToken == null || _product == null) return;

    // Show beautiful loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated loading icon
              Container(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF4B4B),
                  strokeWidth: 4,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '🔄 Updating Inventory',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we update the quantity...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await ApiService.updateProductQuantity(
        token: _userToken!,
        productId: _product!.id,
        quantity: newQuantity,
      );

      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        // Show beautiful success message
        _showSuccessAnimation(newQuantity);

        // Reload product to get updated data
        await _loadProduct();

      } else {
        _showErrorMessage(result['message']);
      }

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorMessage('Failed to update quantity: $e');
    }
  }

  Future<void> _navigateToHome() async {
    try {
      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final workerName = prefs.getString('workerName');
      final workerEmail = prefs.getString('workerEmail');

      print('🔵 Navigating to Home - Name: $workerName, Email: $workerEmail');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              workerName: workerName, // ✅ Pass the actual user data
              workerEmail: workerEmail, // ✅ Pass the actual user data
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to home: $e');
      // Fallback navigation without user data
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }



  // Helper function to get localized category names
  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
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

  // Helper function to format currency
  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Helper function to get stock status color
  Color _getStockStatusColor() {
    if (!_product!.inStock) return Colors.red;
    if (_product!.currentQuantity <= 5) return Colors.orange;
    if (_product!.currentQuantity <= 10) return Colors.yellow[700]!;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Debug print in build method
    print('🔍 DEBUG: Building UI - _isAdmin: $_isAdmin');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l10n.productDetails,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF4B4B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProduct,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4B4B),
        ),
      )
          : _errorMessage.isNotEmpty
          ? _buildErrorView(l10n)
          : _buildProductView(l10n),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loadProduct,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4B),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.goBack),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductView(AppLocalizations l10n) {
    if (_product == null) {
      return _buildErrorView(l10n);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.productFound,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 30),

          // Main product details card
          Container(
            padding: const EdgeInsets.all(24),
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
                // Product ID badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code, color: Color(0xFFFF4B4B), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.idLabel}: ${_product!.id}',
                        style: const TextStyle(
                          color: Color(0xFFFF4B4B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Product name
                Text(
                  l10n.productNameLabel,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  _product!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Stock Section with Admin Edit Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStockStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStockStatusColor().withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                color: _getStockStatusColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stock: ${_product!.currentQuantity} units',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStockStatusColor(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _product!.stockStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Admin Edit Button - This is where it should appear!
                      if (_isAdmin) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showEditQuantityDialog,
                            icon: Icon(Icons.edit, size: 20),
                            label: Text('Edit Quantity (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Warehouse info (if available)
                if (_product!.warehouseName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warehouse, color: Color(0xFFFF4B4B), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Warehouse Information',
                              style: const TextStyle(
                                color: Color(0xFFFF4B4B),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _product!.warehouseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Category and Sector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category, color: Colors.grey[400], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Category',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocalizedCategory(_product!.category, l10n),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_product!.sector.isNotEmpty) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.business, color: Colors.grey[400], size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Sector',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _product!.sector,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 30),

                // Pricing section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.priceLabel,
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatCurrency(_product!.effectivePrice),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF4B4B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_product!.hasDiscount)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.originalPriceLabel,
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatCurrency(_product!.originalPrice),
                              style: TextStyle(
                                fontSize: 20,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Discount section
                if (_product!.hasDiscount) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[600]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${l10n.saveLabel}: ${_formatCurrency(_product!.savings)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_product!.discount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_product!.discount.toStringAsFixed(1)}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n.scanAnother),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B4B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToHome,
                  icon: const Icon(Icons.home),
                  label: Text(l10n.home),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4B4B),
                    side: const BorderSide(color: Color(0xFFFF4B4B)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}