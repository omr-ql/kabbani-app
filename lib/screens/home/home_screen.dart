import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../widgets/custom_widgets.dart';
import '../profile/profile_screen.dart';
import '../search/advanced_search_screen.dart';
import '../search/barcode_scanner_screen.dart';
import '../search/search_by_id_screen.dart';
import '../products/all_products_screen.dart';
import '../products/category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? workerName;
  final String? workerEmail;

  const HomeScreen({Key? key, this.workerName, this.workerEmail})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _recentSearches = [];

  // Variables to store loaded user data
  String? _currentWorkerName;
  String? _currentWorkerEmail;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  // FIX 1: Better parameter handling with immediate priority check
  Future<void> _initializeUserData() async {
    try {
      // FIXED: Check parameters first BEFORE any async operations
      if (widget.workerName != null && widget.workerEmail != null) {
        print('🔵 Using passed parameters - Name: ${widget.workerName}, Email: ${widget.workerEmail}');
        setState(() {
          _currentWorkerName = widget.workerName;
          _currentWorkerEmail = widget.workerEmail;
          _isLoadingUserData = false;
        });
        return; // Exit early, don't load from SharedPreferences
      }

      // Only load from SharedPreferences if NO parameters were provided
      print('🔍 No parameters provided, loading from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final storedName = prefs.getString('workerName');
      final storedEmail = prefs.getString('workerEmail');

      print('🔵 Loaded from SharedPreferences - Name: $storedName, Email: $storedEmail');

      setState(() {
        _currentWorkerName = storedName;
        _currentWorkerEmail = storedEmail;
        _isLoadingUserData = false;
      });

    } catch (e) {
      print('❌ Error loading user data: $e');
      // FIX 2: Better fallback handling
      setState(() {
        _currentWorkerName = widget.workerName ?? 'Worker';
        _currentWorkerEmail = widget.workerEmail;
        _isLoadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return BarcodeScannerScreen(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
          onProductScanned: () {
            print('Product scanned');
          },
        );
      case 2:
        return const AdvancedSearchScreen();
      case 3:
        return ProfileScreen(
          workerName: _currentWorkerName,
          workerEmail: _currentWorkerEmail,
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final l10n = AppLocalizations.of(context)!;

    // Show loading indicator while loading user data
    if (_isLoadingUserData) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4B4B),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Worker Name
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcomeBackWorker,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Text(
                        _currentWorkerName ?? 'Worker',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // FIX 3: Better profile avatar with explicit text widget
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 3),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFFF4B4B),
                          child: Text(
                            _getInitials(_currentWorkerName ?? 'W'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // Added explicit font size
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Custom Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomSearchBar(
                hintText: l10n.searchHint,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ),

            const SizedBox(height: 25),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quickActions,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.qr_code_scanner,
                          title: l10n.scanProduct,
                          subtitle: l10n.quickScan,
                          color: const Color(0xFFFF4B4B),
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.search,
                          title: l10n.searchID,
                          subtitle: l10n.manualSearch,
                          color: const Color(0xFF667EEA),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchByIdScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.browseCategory,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllProductsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.viewAll,
                          style: const TextStyle(color: Color(0xFFFF4B4B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        CategoryChip(
                          label: l10n.all,
                          isSelected: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryProductsScreen(
                                  category: 'All',
                                ),
                              ),
                            );
                          },
                        ),
                        CategoryChip(
                          label: l10n.furniture,
                          isSelected: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryProductsScreen(
                                  category: 'Furniture',
                                ),
                              ),
                            );
                          },
                        ),
                        CategoryChip(
                          label: l10n.carpets,
                          isSelected: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryProductsScreen(
                                  category: 'Carpets',
                                ),
                              ),
                            );
                          },
                        ),
                        CategoryChip(
                          label: l10n.linens,
                          isSelected: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryProductsScreen(
                                  category: 'Linens',
                                ),
                              ),
                            );
                          },
                        ),
                        CategoryChip(
                          label: l10n.general,
                          isSelected: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoryProductsScreen(
                                  category: 'General',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Departments
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.departments,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DepartmentCard(
                        name: l10n.carpets,
                        icon: Icons.texture,
                        color: const Color(0xFFFF6B9D),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryProductsScreen(
                                category: 'Carpets',
                              ),
                            ),
                          );
                        },
                      ),
                      DepartmentCard(
                        name: l10n.furniture,
                        icon: Icons.weekend,
                        color: const Color(0xFF667EEA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryProductsScreen(
                                category: 'Furniture',
                              ),
                            ),
                          );
                        },
                      ),
                      DepartmentCard(
                        name: l10n.linens,
                        icon: Icons.king_bed,
                        color: const Color(0xFF48C9B0),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryProductsScreen(
                                category: 'Linens',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIX 4: Enhanced initials generation with better error handling
  String _getInitials(String name) {
    if (name.isEmpty) return 'W'; // Default fallback

    List<String> nameParts = name.trim().split(' ');
    nameParts = nameParts.where((part) => part.isNotEmpty).toList(); // Remove empty parts

    if (nameParts.length >= 2) {
      // Two or more names: use first letter of first two
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      // Single name: use first letter
      return nameParts[0][0].toUpperCase();
    }

    return 'W'; // Ultimate fallback
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        selectedItemColor: const Color(0xFFFF4B4B),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner),
            label: l10n.scan,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.search), label: l10n.search),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profile),
        ],
      ),
    );
  }
}