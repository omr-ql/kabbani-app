import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/product.dart';

class ApiService {
  // IMPORTANT: Change this URL based on your setup:
  // For Android Emulator: http://10.0.2.2:3000/api
  // For iOS Simulator: http://localhost:3000/api
  static const String baseUrl = 'http://192.168.1.4:3000/api';

  // Timeout duration for API calls
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Headers for all requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper method to handle HTTP errors with better error messages
  static void _handleHttpError(http.Response response) {
    if (response.statusCode >= 400) {
      Map<String, dynamic> errorBody;
      try {
        errorBody = json.decode(response.body);
      } catch (e) {
        errorBody = {'error': 'Unknown error occurred'};
      }

      throw HttpException(
        errorBody['error'] ?? 'HTTP ${response.statusCode}',
        uri: Uri.parse(response.request?.url.toString() ?? ''),
      );
    }
  }

  // ============ AUTHENTICATION METHODS ============

  // Signup with proper null safety and enhanced error handling
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs before sending
      if (name.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
        return {
          'success': false,
          'message': 'All fields are required',
        };
      }

      print('🔐 Attempting signup for: ${email.trim().toLowerCase()}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: _headers,
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(timeoutDuration);

      print('📱 Signup Response Status: ${response.statusCode}');
      print('📱 Signup Response Body: ${response.body}');

      // Handle successful response
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': data['message'] ?? 'Account created successfully',
          'user': data['user'] ?? {
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
          },
          'token': data['user']?['token'],
        };
      }
      // Handle error responses
      else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? errorData['message'] ?? 'Registration failed',
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on FormatException catch (e) {
      print('📄 JSON Format Error: $e');
      return {
        'success': false,
        'message': 'Invalid server response. Please try again.',
      };
    } on http.ClientException catch (e) {
      print('🔌 Network Error: $e');
      return {
        'success': false,
        'message': 'Network connection error. Please check your internet.',
      };
    } catch (e) {
      print('❌ Signup Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Login with proper null safety and enhanced error handling
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty || password.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
        };
      }

      print('🔐 Attempting login for: ${email.trim().toLowerCase()}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(timeoutDuration);

      print('📱 Login Response Status: ${response.statusCode}');
      print('📱 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'] ?? {},
          'token': data['user']?['token'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? errorData['message'] ?? 'Login failed',
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on FormatException catch (e) {
      print('📄 JSON Format Error: $e');
      return {
        'success': false,
        'message': 'Invalid server response. Please try again.',
      };
    } on http.ClientException catch (e) {
      print('🔌 Network Error: $e');
      return {
        'success': false,
        'message': 'Network connection error. Please check your internet.',
      };
    } catch (e) {
      print('❌ Login Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Logout with token handling
  static Future<Map<String, dynamic>> logout(String? token) async {
    try {
      final Map<String, String> headers = Map.from(_headers);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Logged out successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Logout failed',
        };
      }
    } catch (e) {
      print('❌ Logout error: $e');
      return {
        'success': true, // Return success even if server call fails
        'message': 'Logged out locally',
      };
    }
  }

  // ============ PRODUCT METHODS ============

  // Search product by ID with enhanced error handling (for barcode scanning)
  static Future<Product?> searchProductById(String id) async {
    try {
      if (id.trim().isEmpty) {
        print('⚠️ Empty product ID provided');
        return null;
      }

      print('🔍 Searching for product ID: ${id.trim()}');

      final response = await http.get(
        Uri.parse('$baseUrl/products/search?id=${Uri.encodeComponent(id.trim())}'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Search Response Status: ${response.statusCode}');
      print('📱 Search Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['product'] != null) {
          print('✅ Product found: ${data['product']['name']}');
          return Product.fromJson(data['product']);
        }
      } else if (response.statusCode == 404) {
        print('❌ Product not found for ID: ${id.trim()}');
        return null;
      }

      _handleHttpError(response);
      return null;
    } catch (e) {
      print('❌ Search error: $e');
      if (e is HttpException && e.message.contains('not found')) {
        return null;
      }
      rethrow;
    }
  }

  // Enhanced search products with filters and sorting
  static Future<List<Product>> searchProducts(
      String query, {
        String? category,
        String? sortBy,
      }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};

      if (query.isNotEmpty) {
        queryParams['q'] = query;
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort'] = sortBy;
      }

      final uri = Uri.parse('$baseUrl/products/search-by-name')
          .replace(queryParameters: queryParams);

      print('🔍 Searching products: $uri');

      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Search Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products');

        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Search products error: $e');
      return [];
    }
  }

  // Get all products with enhanced error handling
  static Future<List<Product>> getAllProducts() async {
    try {
      print('📥 Fetching all products from: $baseUrl/products');

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Get All Products Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products');

        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get all products error: $e');
      return [];
    }
  }

  // Get products by category/department
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      print('🏷️ Fetching products for category: $category');

      final response = await http.get(
        Uri.parse('$baseUrl/products/department/${Uri.encodeComponent(category)}'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Category Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products in $category');

        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get products by category error: $e');
      return [];
    }
  }

  // Get all available categories
  static Future<List<String>> getCategories() async {
    try {
      print('📂 Fetching categories from: $baseUrl/categories');

      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Categories Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categoriesJson = data['categories'] ?? [];

        print('📂 Found ${categoriesJson.length} categories');

        return categoriesJson
            .map((category) => category.toString())
            .where((category) => category.isNotEmpty)
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get categories error: $e');
      return [];
    }
  }

  // Get product suggestions for autocomplete
  static Future<List<Product>> getProductSuggestions(String query) async {
    try {
      if (query.length < 2) {
        return [];
      }

      print('💡 Getting suggestions for: $query');

      final response = await http.get(
        Uri.parse('$baseUrl/products/suggestions?q=${Uri.encodeComponent(query)}'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Suggestions Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> suggestionsJson = data['suggestions'] ?? [];

        print('💡 Found ${suggestionsJson.length} suggestions');

        return suggestionsJson
            .map((json) => Product.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('❌ Get suggestions error: $e');
      return [];
    }
  }

  // ============ UTILITY METHODS ============

  // Enhanced health check with detailed response
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      print('🏥 Checking server health...');

      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      print('📱 Health Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Server is healthy');
        return data;
      }

      _handleHttpError(response);
      return {'status': 'ERROR', 'message': 'Server unhealthy'};
    } catch (e) {
      print('❌ Health check error: $e');
      return {'status': 'ERROR', 'message': 'Server unreachable', 'error': e.toString()};
    }
  }

  // Simple boolean health check
  static Future<bool> isServerHealthy() async {
    try {
      final healthData = await healthCheck();
      return healthData['status'] == 'OK';
    } catch (e) {
      return false;
    }
  }

  // Test connection to server
  static Future<bool> testConnection() async {
    try {
      print('🔌 Testing connection to server...');
      final isHealthy = await isServerHealthy();
      print(isHealthy ? '✅ Connection successful' : '❌ Connection failed');
      return isHealthy;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }


  static Future<bool> isAdmin(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user']['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('❌ Check admin error: $e');
      return false;
    }
  }

// Update product quantity (Admin only)
  static Future<Map<String, dynamic>> updateProductQuantity({
    required String token,
    required String productId,
    required int quantity,
  }) async {
    try {
      print('🔒 Admin updating quantity for product: $productId to $quantity');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/products/$productId/quantity'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      ).timeout(timeoutDuration);

      print('📱 Update quantity response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'product': data['product'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Admin access required',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to update quantity',
        };
      }
    } catch (e) {
      print('❌ Update quantity error: $e');
      return {
        'success': false,
        'message': 'Error updating quantity: $e',
      };
    }
  }

  // Get server statistics and information
  static Future<Map<String, dynamic>> getServerStats() async {
    try {
      final healthData = await healthCheck();
      final categories = await getCategories();

      return {
        'server_status': healthData['status'],
        'products_count': healthData['productsInDatabase'] ?? 0,
        'categories_count': categories.length,
        'server_time': healthData['timestamp'],
        'base_url': baseUrl,
        'categories': categories,
      };
    } catch (e) {
      print('❌ Error getting server stats: $e');
      return {
        'server_status': 'ERROR',
        'products_count': 0,
        'categories_count': 0,
        'error': e.toString(),
      };
    }
  }

  static Future<List<String>> getWarehouses() async {
    try {
      print('🏪 Fetching warehouses from: $baseUrl/warehouses');

      final response = await http.get(
        Uri.parse('$baseUrl/warehouses'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Warehouses Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> warehousesJson = data['warehouses'] ?? [];

        print('🏪 Found ${warehousesJson.length} warehouses');

        return warehousesJson
            .map((warehouse) => warehouse.toString())
            .where((warehouse) => warehouse.isNotEmpty)
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get warehouses error: $e');
      return [];
    }
  }

  // Get products by warehouse
  static Future<List<Product>> getProductsByWarehouse(String warehouse) async {
    try {
      print('🏪 Fetching products for warehouse: $warehouse');

      final response = await http.get(
        Uri.parse('$baseUrl/products/warehouse/${Uri.encodeComponent(warehouse)}'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Warehouse Products Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products in $warehouse');

        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get products by warehouse error: $e');
      return [];
    }
  }

  // Get warehouse statistics
  static Future<List<Map<String, dynamic>>> getWarehouseStats() async {
    try {
      print('📊 Fetching warehouse statistics from: $baseUrl/warehouses/stats');

      final response = await http.get(
        Uri.parse('$baseUrl/warehouses/stats'),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Warehouse Stats Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> statsJson = data['warehouses'] ?? [];

        print('📊 Found stats for ${statsJson.length} warehouses');

        return statsJson.map((stat) => Map<String, dynamic>.from(stat)).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get warehouse stats error: $e');
      return [];
    }
  }

  // Enhanced search with warehouse filter
  static Future<List<Product>> searchProductsAdvanced(
      String query, {
        String? category,
        String? warehouse,
        String? sortBy,
      }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};

      if (query.isNotEmpty) {
        queryParams['q'] = query;
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }

      if (warehouse != null && warehouse.isNotEmpty && warehouse != 'All') {
        queryParams['warehouse'] = warehouse;
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort'] = sortBy;
      }

      final uri = Uri.parse('$baseUrl/products/search-by-name')
          .replace(queryParameters: queryParams);

      print('🔍 Advanced search: $uri');

      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(timeoutDuration);

      print('📱 Advanced Search Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products');

        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Advanced search error: $e');
      return [];
    }
  }

  // Get warehouse summary information
  static Future<Map<String, dynamic>> getWarehouseSummary(String warehouse) async {
    try {
      print('📋 Fetching summary for warehouse: $warehouse');

      final response = await http.get(
        Uri.parse('$baseUrl/products/warehouse/${Uri.encodeComponent(warehouse)}'),
        headers: _headers,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        // Calculate summary statistics
        int totalProducts = productsJson.length;
        int totalQuantity = 0;
        double totalValue = 0.0;
        Set<String> categories = {};

        for (var productJson in productsJson) {
          totalQuantity += (productJson['current_quantity'] as int? ?? 0);
          totalValue += (productJson['total_value'] as double? ?? 0.0);
          if (productJson['category'] != null) {
            categories.add(productJson['category']);
          }
        }

        return {
          'warehouse_name': warehouse,
          'total_products': totalProducts,
          'total_quantity': totalQuantity,
          'total_value': totalValue,
          'categories_count': categories.length,
          'categories': categories.toList(),
          'products': productsJson.map((json) => Product.fromJson(json)).toList(),
        };
      }

      _handleHttpError(response);
      return {};
    } catch (e) {
      print('❌ Get warehouse summary error: $e');
      return {};
    }
  }

  static Future<void> debugProductSearch(String productId) async {
    try {
      print('🐛 DEBUG: Testing product search for ID: $productId');

      final url = '$baseUrl/products/search?id=${Uri.encodeComponent(productId)}';
      print('🐛 DEBUG: Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(timeoutDuration);

      print('🐛 DEBUG: Response Status Code: ${response.statusCode}');
      print('🐛 DEBUG: Response Headers: ${response.headers}');
      print('🐛 DEBUG: Raw Response Body:');
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🐛 DEBUG: Parsed JSON:');
        print('   Product data exists: ${data.containsKey('product')}');

        if (data.containsKey('product')) {
          final productData = data['product'];
          print('🐛 DEBUG: Product fields:');
          productData.forEach((key, value) {
            print('   $key: $value (${value.runtimeType})');
          });
        }
      } else {
        print('🐛 DEBUG: Error response: ${response.body}');
      }

    } catch (e) {
      print('🐛 DEBUG: Exception during API call: $e');
    }
  }

// Also add this method to test server health and see what fields are available
  static Future<void> debugServerHealth() async {
    try {
      print('🐛 DEBUG: Testing server health');

      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      print('🐛 DEBUG: Health Check Status: ${response.statusCode}');
      print('🐛 DEBUG: Health Response: ${response.body}');

      // Test getting all products to see structure
      final productsResponse = await http.get(
        Uri.parse('$baseUrl/products?limit=1'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      print('🐛 DEBUG: Products Response Status: ${productsResponse.statusCode}');
      if (productsResponse.statusCode == 200) {
        final data = json.decode(productsResponse.body);
        print('🐛 DEBUG: Sample product structure:');
        if (data['products'] != null && data['products'].isNotEmpty) {
          final sampleProduct = data['products'][0];
          sampleProduct.forEach((key, value) {
            print('   $key: $value (${value.runtimeType})');
          });
        }
      }

    } catch (e) {
      print('🐛 DEBUG: Health check failed: $e');
    }
  }


  // Helper method to check if response is successful
  static bool _isSuccessResponse(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // Helper method to log response details
  static void _logResponse(String endpoint, http.Response response) {
    print('📡 API Call: $endpoint');
    print('📱 Status: ${response.statusCode}');
    print('📄 Response: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');
  }
}