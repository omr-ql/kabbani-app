import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Import your app files - adjust paths as needed
import 'package:kabbani_home/screens/home/home_screen.dart';
import 'package:kabbani_home/l10n/app_localizations.dart';
import 'package:kabbani_home/widgets/custom_widgets.dart';
import 'package:kabbani_home/providers/language_provider.dart';

// Mock classes
class MockLanguageProvider extends LanguageProvider {
  MockLanguageProvider() : super();

  @override
  String get currentLocale => 'en';

  @override
  Future<void> changeLanguage(String locale) async {
    // Mock implementation - make it async to match parent class
    notifyListeners();
  }
}

void main() {
  group('HomeScreen Widget Tests', () {

    // Setup function to create testable widget with all required providers
    Widget createTestWidget({String? workerName, String? workerEmail}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => MockLanguageProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          home: HomeScreen(
            workerName: workerName,
            workerEmail: workerEmail,
          ),
        ),
      );
    }

    testWidgets('should display bottom navigation with 4 tabs', (WidgetTester tester) async {
      // Arrange - Set up SharedPreferences for this test
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(); // Wait for async operations

      // Assert - Check bottom navigation exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Check bottom navigation items specifically by looking at the BottomNavigationBar
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.items.length, 4);

      // Verify the labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should display welcome message with passed worker name', (WidgetTester tester) async {
      // Arrange - Pass parameters that should override SharedPreferences
      // BUG FIX: Clear SharedPreferences to ensure parameters take priority
      SharedPreferences.setMockInitialValues({}); // Empty to force parameter use

      await tester.pumpWidget(createTestWidget(workerName: 'John Doe'));
      await tester.pumpAndSettle();

      // Assert - Should show the passed name, not SharedPreferences
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.textContaining('Welcome back'), findsOneWidget);
    });

    testWidgets('should display worker initials in profile avatar', (WidgetTester tester) async {
      // Arrange - Clear SharedPreferences and pass parameters
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createTestWidget(workerName: 'John Doe'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('JD'), findsOneWidget); // Should show initials
    });

    testWidgets('should handle single name initials correctly', (WidgetTester tester) async {
      // Arrange - Clear SharedPreferences and pass single name
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createTestWidget(workerName: 'Ahmad'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('A'), findsOneWidget); // Should show single initial
    });

    testWidgets('should navigate between bottom navigation tabs', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act: Tap on Search tab (use specific finder for bottom nav)
      final bottomNavItems = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Search'),
      );
      await tester.tap(bottomNavItems);
      await tester.pumpAndSettle();

      // Assert: Should change selected index
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, 2); // Search tab is index 2

      // Act: Tap on Profile tab
      final profileTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Profile'),
      );
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // Assert: Should navigate to profile tab
      final updatedBottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(updatedBottomNav.currentIndex, 3); // Profile tab is index 3
    });

    testWidgets('should display quick action cards', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Look for QuickActionCard widgets
      expect(find.byType(QuickActionCard), findsAtLeastNWidgets(2));

      // Look for specific text in quick actions
      expect(find.text('Scan Product'), findsOneWidget);
      expect(find.text('Search ID'), findsOneWidget);
    });

    testWidgets('should navigate to scanner when scan product is tapped', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act: Find the "Scan Product" quick action and tap it
      await tester.tap(find.text('Scan Product'));
      await tester.pumpAndSettle();

      // Assert: Should navigate to scanner tab (index 1)
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, 1);
    });

    testWidgets('should display category chips', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Look for CategoryChip widgets
      expect(find.byType(CategoryChip), findsAtLeastNWidgets(5));

      // Check for specific categories (look for text in CategoryChips)
      expect(find.text('All'), findsOneWidget);
      // Note: "Furniture" appears in both category chips AND department cards
      // So we expect to find 2 instances
      expect(find.text('Furniture'), findsAtLeastNWidgets(1));
      expect(find.text('Carpets'), findsAtLeastNWidgets(1));
      expect(find.text('Linens'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display department cards', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DepartmentCard), findsNWidgets(3));
    });

    testWidgets('should tap profile avatar and navigate to profile tab', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'John Doe',
        'workerEmail': 'john@example.com',
      });

      await tester.pumpWidget(createTestWidget(workerName: 'John Doe'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      // Assert: Should navigate to profile tab (index 3)
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, 3);
    });

    testWidgets('should tap search bar and navigate to search tab', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(CustomSearchBar));
      await tester.pumpAndSettle();

      // Assert: Should navigate to search tab (index 2)
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, 2);
    });

    testWidgets('should display loading indicator while loading user data', (WidgetTester tester) async {
      // Arrange: Create widget without SharedPreferences setup to trigger loading
      SharedPreferences.setMockInitialValues({}); // Empty preferences
      await tester.pumpWidget(createTestWidget());

      // Assert: Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle();
    });

    testWidgets('should handle missing user data gracefully', (WidgetTester tester) async {
      // Arrange: No user data provided
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Should display default values
      expect(find.text('Worker'), findsOneWidget);
      expect(find.text('W'), findsOneWidget); // Default initial
    });

    testWidgets('should prioritize passed parameters over SharedPreferences', (WidgetTester tester) async {
      // Arrange: Set different values in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workerName': 'Stored Worker',
        'workerEmail': 'stored@example.com',
      });

      // Act: Pass different parameters
      await tester.pumpWidget(createTestWidget(
          workerName: 'Passed Worker',
          workerEmail: 'passed@example.com'
      ));
      await tester.pumpAndSettle();

      // Assert: Should use passed parameters, not stored ones
      expect(find.text('Passed Worker'), findsOneWidget);
      expect(find.text('Stored Worker'), findsNothing);
    });

    testWidgets('should display correct section headers', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Browse by Category'), findsOneWidget);
      expect(find.text('Departments'), findsOneWidget);
    });

    testWidgets('should display View All button', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Find the main content SingleChildScrollView (not the one in AdvancedSearchScreen)
      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews, findsAtLeastNWidgets(1));

      // Act: Try scrolling the first scroll view
      await tester.drag(scrollViews.first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // The test should complete without overflow errors
    });
  });

  group('HomeScreen Basic Functionality Tests', () {
    Widget createBasicTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => MockLanguageProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          home: const HomeScreen(),
        ),
      );
    }

    testWidgets('should display basic UI elements', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createBasicTestWidget());
      await tester.pumpAndSettle();

      // Basic UI elements should exist
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should handle tap interactions without errors', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(createBasicTestWidget());
      await tester.pumpAndSettle();

      // Test tapping quick action cards
      if (find.text('Scan Product').evaluate().isNotEmpty) {
        await tester.tap(find.text('Scan Product'));
        await tester.pump();
      }

      // Verify no errors occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen Error Handling Tests', () {
    testWidgets('should handle widget creation without errors', (WidgetTester tester) async {
      // Test with minimal setup
      SharedPreferences.setMockInitialValues({
        'workerName': 'Test Worker',
        'workerEmail': 'test@example.com',
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          home: const HomeScreen(),
        ),
      );

      // Should not crash during widget creation
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}