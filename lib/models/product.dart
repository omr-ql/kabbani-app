class Product {
  final String id;
  final String name;
  final double price;
  final double originalPrice;
  final double currentPrice;
  final String category;
  final String warehouseName;
  final String sector;
  final int currentQuantity;
  final double discountAmount;
  final double discountPercentage;
  final double totalValue;
  final DateTime? importDate;
  final DateTime? lastUpdated;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.currentPrice,
    required this.category,
    this.warehouseName = '',
    this.sector = '',
    this.currentQuantity = 0,
    this.discountAmount = 0.0,
    this.discountPercentage = 0.0,
    this.totalValue = 0.0,
    this.importDate,
    this.lastUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // DEBUG: Print the raw JSON to see what we're receiving
    print('🔍 Raw JSON received: $json');

    final product = Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      originalPrice: _parseDouble(json['original_price']),
      currentPrice: _parseDouble(json['current_price']),
      category: json['category']?.toString() ?? 'General',
      warehouseName: json['warehouse_name']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      currentQuantity: _parseInt(json['current_quantity']),
      discountAmount: _parseDouble(json['discount_amount']),
      discountPercentage: _parseDouble(json['discount_percentage']),
      totalValue: _parseDouble(json['total_value']),
      importDate: _parseDateTime(json['import_date']),
      lastUpdated: _parseDateTime(json['last_updated']),
    );

    // DEBUG: Print parsed values
    print('📦 Parsed Product:');
    print('   Name: ${product.name}');
    print('   Warehouse: "${product.warehouseName}"');
    print('   Sector: "${product.sector}"');
    print('   Current Quantity: ${product.currentQuantity}');
    print('   Current Price: ${product.currentPrice}');
    print('   In Stock: ${product.inStock}');
    print('   Stock Status: ${product.stockStatus}');

    return product;
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        print('⚠️ Failed to parse double: "$value"');
        return 0.0;
      }
      return parsed;
    }
    print('⚠️ Unexpected type for double: ${value.runtimeType} = $value');
    return 0.0;
  }

  // Helper method to safely parse integer values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        print('⚠️ Failed to parse int: "$value"');
        return 0;
      }
      return parsed;
    }
    print('⚠️ Unexpected type for int: ${value.runtimeType} = $value');
    return 0;
  }

  // Helper method to safely parse DateTime values
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'original_price': originalPrice,
      'current_price': currentPrice,
      'category': category,
      'warehouse_name': warehouseName,
      'sector': sector,
      'current_quantity': currentQuantity,
      'discount_amount': discountAmount,
      'discount_percentage': discountPercentage,
      'total_value': totalValue,
      'import_date': importDate?.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  // Get the effective selling price
  double get effectivePrice {
    return currentPrice > 0 ? currentPrice : price;
  }

  // Check if product has discount
  bool get hasDiscount {
    return originalPrice > price && originalPrice > 0;
  }

  // Get discount percentage
  double get discount {
    if (discountPercentage > 0) return discountPercentage;
    if (originalPrice > 0) {
      return ((originalPrice - price) / originalPrice * 100);
    }
    return 0.0;
  }

  // Get discount amount
  double get savings {
    if (discountAmount > 0) return discountAmount;
    return originalPrice - price;
  }

  // FIXED: Check if product is in stock
  bool get inStock {
    print('📊 Stock Check - currentQuantity: $currentQuantity, inStock: ${currentQuantity > 0}');
    return currentQuantity > 0;
  }

  // FIXED: Get stock status with better logic
  String get stockStatus {
    print('📊 Stock Status Check - currentQuantity: $currentQuantity');
    if (currentQuantity <= 0) return 'Out of Stock';
    if (currentQuantity <= 5) return 'Low Stock';
    if (currentQuantity <= 10) return 'Limited Stock';
    return 'In Stock';
  }

  // Check if this is a high-value item
  bool get isHighValue {
    return totalValue > 1000 || effectivePrice > 500;
  }

  // Get warehouse location (city from warehouse name)
  String get warehouseLocation {
    if (warehouseName.isEmpty) return 'Unknown';

    // Extract city from warehouse name (format: "الفيوم - مفروشات ومراتب")
    final parts = warehouseName.split(' - ');
    return parts.isNotEmpty ? parts[0].trim() : warehouseName;
  }

  // Get warehouse type from warehouse name
  String get warehouseType {
    if (warehouseName.isEmpty) return 'Unknown';

    // Extract type from warehouse name
    final parts = warehouseName.split(' - ');
    return parts.length > 1 ? parts[1].trim() : 'General';
  }

  // Format currency helper
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Get formatted effective price
  String get formattedEffectivePrice => formatCurrency(effectivePrice);

  // Get formatted original price
  String get formattedOriginalPrice => formatCurrency(originalPrice);

  // Get formatted discount amount
  String get formattedSavings => formatCurrency(savings);

  @override
  String toString() {
    return 'Product{id: $id, name: $name, warehouse: "$warehouseName", sector: "$sector", quantity: $currentQuantity, price: $effectivePrice, inStock: $inStock}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}