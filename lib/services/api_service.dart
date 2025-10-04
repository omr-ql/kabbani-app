import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/reservation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.10:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ ERROR HANDLING HELPERS ============

  /// Returns appropriate error message key based on exception type
  static String _getErrorKey(dynamic error) {
    if (error is SocketException) {
      return 'errorNoInternet';
    } else if (error is TimeoutException) {
      return 'errorTimeout';
    } else if (error is http.ClientException) {
      return 'errorConnection';
    } else if (error is FormatException) {
      return 'errorInvalidResponse';
    } else if (error is HttpException) {
      return _getHttpErrorKey(error);
    }
    return 'errorGeneric';
  }

  /// Returns error key based on HTTP status code
  static String _getHttpErrorKey(dynamic error) {
    if (error is HttpException) {
      final message = error.message.toLowerCase();
      if (message.contains('unauthorized') || message.contains('401')) {
        return 'errorUnauthorized';
      } else if (message.contains('forbidden') || message.contains('403')) {
        return 'errorForbidden';
      } else if (message.contains('not found') || message.contains('404')) {
        return 'errorNotFound';
      } else if (message.contains('conflict') || message.contains('409')) {
        return 'errorConflict';
      } else if (message.contains('bad gateway') || message.contains('502')) {
        return 'errorBadGateway';
      } else if (message.contains('service unavailable') ||
          message.contains('503')) {
        return 'errorServiceUnavailable';
      } else if (message.contains('gateway timeout') ||
          message.contains('504')) {
        return 'errorGatewayTimeout';
      } else if (message.contains('bad request') || message.contains('400')) {
        return 'errorBadRequest';
      } else if (message.contains('500')) {
        return 'errorServerError';
      }
    }
    return 'errorGeneric';
  }

  /// Returns error key based on HTTP response status code
  static String _getStatusCodeErrorKey(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'errorBadRequest';
      case 401:
        return 'errorUnauthorized';
      case 403:
        return 'errorForbidden';
      case 404:
        return 'errorNotFound';
      case 409:
        return 'errorConflict';
      case 500:
        return 'errorServerError';
      case 502:
        return 'errorBadGateway';
      case 503:
        return 'errorServiceUnavailable';
      case 504:
        return 'errorGatewayTimeout';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'errorClientError';
        } else if (statusCode >= 500) {
          return 'errorServerError';
        }
        return 'errorGeneric';
    }
  }

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

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (name.trim().isEmpty ||
          email.trim().isEmpty ||
          password.trim().isEmpty) {
        return {
          'success': false,
          'messageKey': 'errorBadRequest',
          'message': 'All fields are required',
        };
      }

      print('🔐 Attempting signup for: ${email.trim().toLowerCase()}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/signup'),
            headers: _headers,
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(timeoutDuration);

      print('📱 Signup Response Status: ${response.statusCode}');
      print('📱 Signup Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'messageKey': 'successSignup',
          'message': data['message'] ?? 'Account created successfully',
          'user':
              data['user'] ??
              {'name': name.trim(), 'email': email.trim().toLowerCase()},
          'token': data['user']?['token'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg =
            errorData['error'] ?? errorData['message'] ?? 'Registration failed';

        // Check for specific errors
        String messageKey = 'errorGeneric';
        if (errorMsg.toLowerCase().contains('already exists') ||
            errorMsg.toLowerCase().contains('duplicate')) {
          messageKey = 'errorUserExists';
        } else {
          messageKey = _getStatusCodeErrorKey(response.statusCode);
        }

        return {
          'success': false,
          'messageKey': messageKey,
          'message': errorMsg,
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorNoInternet',
        'message': 'No internet connection',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout Error: $e');
      return {
        'success': false,
        'messageKey': 'errorTimeout',
        'message': 'Request timed out',
      };
    } on FormatException catch (e) {
      print('📄 JSON Format Error: $e');
      return {
        'success': false,
        'messageKey': 'errorInvalidResponse',
        'message': 'Invalid server response',
      };
    } on http.ClientException catch (e) {
      print('🔌 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorConnection',
        'message': 'Connection failed',
      };
    } catch (e) {
      print('❌ Signup Error: $e');
      return {
        'success': false,
        'messageKey': _getErrorKey(e),
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        return {
          'success': false,
          'messageKey': 'errorBadRequest',
          'message': 'Email and password are required',
        };
      }

      print('🔐 Attempting login for: ${email.trim().toLowerCase()}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(timeoutDuration);

      print('📱 Login Response Status: ${response.statusCode}');
      print('📱 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'messageKey': 'successLogin',
          'message': data['message'] ?? 'Login successful',
          'user': data['user'] ?? {},
          'token': data['user']?['token'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg =
            errorData['error'] ?? errorData['message'] ?? 'Login failed';

        // Check for invalid credentials
        String messageKey = 'errorGeneric';
        if (response.statusCode == 401 ||
            errorMsg.toLowerCase().contains('invalid') ||
            errorMsg.toLowerCase().contains('incorrect') ||
            errorMsg.toLowerCase().contains('wrong')) {
          messageKey = 'errorInvalidCredentials';
        } else {
          messageKey = _getStatusCodeErrorKey(response.statusCode);
        }

        return {
          'success': false,
          'messageKey': messageKey,
          'message': errorMsg,
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorNoInternet',
        'message': 'No internet connection',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout Error: $e');
      return {
        'success': false,
        'messageKey': 'errorTimeout',
        'message': 'Request timed out',
      };
    } on FormatException catch (e) {
      print('📄 JSON Format Error: $e');
      return {
        'success': false,
        'messageKey': 'errorInvalidResponse',
        'message': 'Invalid server response',
      };
    } on http.ClientException catch (e) {
      print('🔌 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorConnection',
        'message': 'Connection failed',
      };
    } catch (e) {
      print('❌ Login Error: $e');
      return {
        'success': false,
        'messageKey': _getErrorKey(e),
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> logout(String? token) async {
    try {
      final Map<String, String> headers = Map.from(_headers);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(Uri.parse('$baseUrl/auth/logout'), headers: headers)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'messageKey': 'successLogout',
          'message': 'Logged out successfully',
        };
      } else {
        return {
          'success': false,
          'messageKey': _getStatusCodeErrorKey(response.statusCode),
          'message': 'Logout failed',
        };
      }
    } catch (e) {
      print('❌ Logout error: $e');
      return {
        'success': true, // Return success even if server call fails
        'messageKey': 'successLogout',
        'message': 'Logged out locally',
      };
    }
  }

  // ============ PRODUCT METHODS ============

  static Future<Product?> searchProductById(String id) async {
    try {
      if (id.trim().isEmpty) {
        print('⚠️ Empty product ID provided');
        return null;
      }

      print('🔍 Searching for product ID: ${id.trim()}');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/products/search?id=${Uri.encodeComponent(id.trim())}',
            ),
            headers: _headers,
          )
          .timeout(timeoutDuration);

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

  static Future<List<Product>> searchProducts(
    String query, {
    String? category,
    String? sortBy,
  }) async {
    try {
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

      final uri = Uri.parse(
        '$baseUrl/products/search-by-name',
      ).replace(queryParameters: queryParams);

      print('🔍 Searching products: $uri');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(timeoutDuration);

      print('📱 Search Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products');

        return productsJson.map((json) => Product.fromJson(json)).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Search products error: $e');
      return [];
    }
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      print('📥 Fetching all products from: $baseUrl/products');

      final response = await http
          .get(Uri.parse('$baseUrl/products'), headers: _headers)
          .timeout(timeoutDuration);

      print('📱 Get All Products Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products');

        return productsJson.map((json) => Product.fromJson(json)).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get all products error: $e');
      return [];
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      print('🏷️ Fetching products for category: $category');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/products/department/${Uri.encodeComponent(category)}',
            ),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      print('📱 Category Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products in $category');

        return productsJson.map((json) => Product.fromJson(json)).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get products by category error: $e');
      return [];
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      print('📂 Fetching categories from: $baseUrl/categories');

      final response = await http
          .get(Uri.parse('$baseUrl/categories'), headers: _headers)
          .timeout(timeoutDuration);

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

  static Future<List<Product>> getProductSuggestions(String query) async {
    try {
      if (query.length < 2) {
        return [];
      }

      print('💡 Getting suggestions for: $query');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/products/suggestions?q=${Uri.encodeComponent(query)}',
            ),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      print('📱 Suggestions Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> suggestionsJson = data['suggestions'] ?? [];

        print('💡 Found ${suggestionsJson.length} suggestions');

        return suggestionsJson.map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Get suggestions error: $e');
      return [];
    }
  }

  // ============ WAREHOUSE METHODS ============

  static Future<List<String>> getWarehouses() async {
    try {
      print('🏪 Fetching warehouses from: $baseUrl/warehouses');

      final response = await http
          .get(Uri.parse('$baseUrl/warehouses'), headers: _headers)
          .timeout(timeoutDuration);

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

  static Future<List<Product>> getProductsByWarehouse(String warehouse) async {
    try {
      print('🏪 Fetching products for warehouse: $warehouse');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/products/warehouse/${Uri.encodeComponent(warehouse)}',
            ),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      print('📱 Warehouse Products Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products in $warehouse');

        return productsJson.map((json) => Product.fromJson(json)).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get products by warehouse error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getWarehouseStats() async {
    try {
      print('📊 Fetching warehouse statistics from: $baseUrl/warehouses/stats');

      final response = await http
          .get(Uri.parse('$baseUrl/warehouses/stats'), headers: _headers)
          .timeout(timeoutDuration);

      print('📱 Warehouse Stats Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> statsJson = data['warehouses'] ?? [];

        print('📊 Found stats for ${statsJson.length} warehouses');

        return statsJson
            .map((stat) => Map<String, dynamic>.from(stat))
            .toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Get warehouse stats error: $e');
      return [];
    }
  }

  static Future<List<Product>> searchProductsAdvanced(
    String query, {
    String? category,
    String? warehouse,
    String? sortBy,
  }) async {
    try {
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

      final uri = Uri.parse(
        '$baseUrl/products/search-by-name',
      ).replace(queryParameters: queryParams);

      print('🔍 Advanced search: $uri');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(timeoutDuration);

      print('📱 Advanced Search Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

        print('📦 Found ${productsJson.length} products');

        return productsJson.map((json) => Product.fromJson(json)).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('❌ Advanced search error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getWarehouseSummary(
    String warehouse,
  ) async {
    try {
      print('📋 Fetching summary for warehouse: $warehouse');

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/products/warehouse/${Uri.encodeComponent(warehouse)}',
            ),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];

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
          'products': productsJson
              .map((json) => Product.fromJson(json))
              .toList(),
        };
      }

      _handleHttpError(response);
      return {};
    } catch (e) {
      print('❌ Get warehouse summary error: $e');
      return {};
    }
  }

  // ============ ADMIN METHODS ============

  static Future<bool> isAdmin(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeoutDuration);

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

  static Future<Map<String, dynamic>> updateProductQuantity({
    required String token,
    required String productId,
    required int quantity,
  }) async {
    try {
      print('🔒 Admin updating quantity for product: $productId to $quantity');

      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/products/$productId/quantity'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'quantity': quantity}),
          )
          .timeout(timeoutDuration);

      print('📱 Update quantity response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'messageKey': 'successQuantityUpdated',
          'message': data['message'],
          'product': data['product'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'messageKey': 'errorForbidden',
          'message': 'Admin access required',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'messageKey': _getStatusCodeErrorKey(response.statusCode),
          'message': errorData['error'] ?? 'Failed to update quantity',
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorNoInternet',
        'message': 'No internet connection',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout Error: $e');
      return {
        'success': false,
        'messageKey': 'errorTimeout',
        'message': 'Request timed out',
      };
    } catch (e) {
      print('❌ Update quantity error: $e');
      return {
        'success': false,
        'messageKey': _getErrorKey(e),
        'message': 'Error updating quantity',
      };
    }
  }

  // ============ RESERVATION METHODS ============

  static Future<Map<String, dynamic>> createReservation({
    required String token,
    required String productId,
    required String productName,
    required String customerName,
    required String customerContact,
    required int quantity,
    required DateTime pickupDate,
    String? notes,
  }) async {
    try {
      print('📝 Creating reservation for product: $productName');

      final response = await http
          .post(
            Uri.parse('$baseUrl/reservations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'productId': productId,
              'productName': productName,
              'customerName': customerName,
              'customerContact': customerContact,
              'quantity': quantity,
              'pickupDate': pickupDate.toIso8601String(),
              'notes': notes,
            }),
          )
          .timeout(timeoutDuration);

      print('📱 Create Reservation Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'messageKey': 'successReservationCreated',
          'message': 'Reservation created successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg = errorData['error'] ?? 'Failed to create reservation';

        // Check for insufficient stock
        String messageKey = 'errorGeneric';
        if (errorMsg.toLowerCase().contains('stock') ||
            errorMsg.toLowerCase().contains('insufficient') ||
            errorMsg.toLowerCase().contains('not enough')) {
          messageKey = 'errorInsufficientStock';
        } else {
          messageKey = _getStatusCodeErrorKey(response.statusCode);
        }

        return {
          'success': false,
          'messageKey': messageKey,
          'message': errorMsg,
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorNoInternet',
        'message': 'No internet connection',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout Error: $e');
      return {
        'success': false,
        'messageKey': 'errorTimeout',
        'message': 'Request timed out',
      };
    } catch (e) {
      print('❌ Create reservation error: $e');
      return {
        'success': false,
        'messageKey': _getErrorKey(e),
        'message': 'Error creating reservation',
      };
    }
  }

  static Future<List<Reservation>> getAllReservations(String token) async {
    try {
      print('📋 Fetching all reservations');

      final response = await http
          .get(
            Uri.parse('$baseUrl/reservations'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeoutDuration);

      print('📱 Get Reservations Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Reservation.fromJson(json)).toList();
      } else {
        throw HttpException(
          'Failed to load reservations: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching reservations: $e');
      return [];
    }
  }

  static Future<List<Reservation>> getMyReservations(String token) async {
    try {
      print('📋 Fetching my reservations');

      final response = await http
          .get(
            Uri.parse('$baseUrl/reservations/my'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeoutDuration);

      print('📱 Get My Reservations Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Reservation.fromJson(json)).toList();
      } else {
        throw HttpException(
          'Failed to load my reservations: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching my reservations: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelReservation(
    String token,
    String reservationId,
  ) async {
    try {
      print('🚫 Cancelling reservation: $reservationId');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/reservations/$reservationId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeoutDuration);

      print('📱 Cancel Reservation Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'messageKey': 'successReservationCancelled',
          'message': 'Reservation cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'messageKey': _getStatusCodeErrorKey(response.statusCode),
          'message': 'Failed to cancel reservation',
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorNoInternet',
        'message': 'No internet connection',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout Error: $e');
      return {
        'success': false,
        'messageKey': 'errorTimeout',
        'message': 'Request timed out',
      };
    } catch (e) {
      print('❌ Error canceling reservation: $e');
      return {
        'success': false,
        'messageKey': _getErrorKey(e),
        'message': 'Error canceling reservation',
      };
    }
  }

  static Future<Map<String, dynamic>> fulfillReservation(
    String token,
    String reservationId,
  ) async {
    try {
      print('✅ Fulfilling reservation: $reservationId');

      final response = await http
          .patch(
            Uri.parse('$baseUrl/reservations/$reservationId/fulfill'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeoutDuration);

      print('📱 Fulfill Reservation Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'messageKey': 'successReservationFulfilled',
          'message': 'Reservation marked as fulfilled',
        };
      } else {
        return {
          'success': false,
          'messageKey': _getStatusCodeErrorKey(response.statusCode),
          'message': 'Failed to fulfill reservation',
        };
      }
    } on SocketException catch (e) {
      print('🌐 Network Error: $e');
      return {
        'success': false,
        'messageKey': 'errorNoInternet',
        'message': 'No internet connection',
      };
    } on TimeoutException catch (e) {
      print('⏱️ Timeout Error: $e');
      return {
        'success': false,
        'messageKey': 'errorTimeout',
        'message': 'Request timed out',
      };
    } catch (e) {
      print('❌ Error fulfilling reservation: $e');
      return {
        'success': false,
        'messageKey': _getErrorKey(e),
        'message': 'Error fulfilling reservation',
      };
    }
  }

  // ============ UTILITY METHODS ============

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      print('🏥 Checking server health...');

      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: _headers)
          .timeout(const Duration(seconds: 10));

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
      return {
        'status': 'ERROR',
        'message': 'Server unreachable',
        'error': e.toString(),
      };
    }
  }

  static Future<bool> isServerHealthy() async {
    try {
      final healthData = await healthCheck();
      return healthData['status'] == 'OK';
    } catch (e) {
      return false;
    }
  }

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

  // ============ DEBUG METHODS ============

  static Future<void> debugProductSearch(String productId) async {
    try {
      print('🛠 DEBUG: Testing product search for ID: $productId');

      final url =
          '$baseUrl/products/search?id=${Uri.encodeComponent(productId)}';
      print('🛠 DEBUG: Request URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(timeoutDuration);

      print('🛠 DEBUG: Response Status Code: ${response.statusCode}');
      print('🛠 DEBUG: Response Headers: ${response.headers}');
      print('🛠 DEBUG: Raw Response Body:');
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🛠 DEBUG: Parsed JSON:');
        print('   Product data exists: ${data.containsKey('product')}');

        if (data.containsKey('product')) {
          final productData = data['product'];
          print('🛠 DEBUG: Product fields:');
          productData.forEach((key, value) {
            print('   $key: $value (${value.runtimeType})');
          });
        }
      } else {
        print('🛠 DEBUG: Error response: ${response.body}');
      }
    } catch (e) {
      print('🛠 DEBUG: Exception during API call: $e');
    }
  }

  static Future<void> debugServerHealth() async {
    try {
      print('🛠 DEBUG: Testing server health');

      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: _headers)
          .timeout(Duration(seconds: 10));

      print('🛠 DEBUG: Health Check Status: ${response.statusCode}');
      print('🛠 DEBUG: Health Response: ${response.body}');

      final productsResponse = await http
          .get(Uri.parse('$baseUrl/products?limit=1'), headers: _headers)
          .timeout(Duration(seconds: 10));

      print(
        '🛠 DEBUG: Products Response Status: ${productsResponse.statusCode}',
      );
      if (productsResponse.statusCode == 200) {
        final data = json.decode(productsResponse.body);
        print('🛠 DEBUG: Sample product structure:');
        if (data['products'] != null && data['products'].isNotEmpty) {
          final sampleProduct = data['products'][0];
          sampleProduct.forEach((key, value) {
            print('   $key: $value (${value.runtimeType})');
          });
        }
      }
    } catch (e) {
      print('🛠 DEBUG: Health check failed: $e');
    }
  }
}
