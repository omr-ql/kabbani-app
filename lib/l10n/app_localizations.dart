import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Home Furnishing account'**
  String get signInToAccount;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinToday.
  ///
  /// In en, this message translates to:
  /// **'Join Home Furnishing today'**
  String get joinToday;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Conditions and Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Logout Confirmation'**
  String get logoutConfirmation;

  /// No description provided for @sureToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout'**
  String get sureToLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Inventory Management'**
  String get appSubtitle;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @welcomeBackWorker.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back,'**
  String get welcomeBackWorker;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by name, ID, or category...'**
  String get searchHint;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @scanProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan Product'**
  String get scanProduct;

  /// No description provided for @quickScan.
  ///
  /// In en, this message translates to:
  /// **'Quick scan'**
  String get quickScan;

  /// No description provided for @searchID.
  ///
  /// In en, this message translates to:
  /// **'Search ID'**
  String get searchID;

  /// No description provided for @manualSearch.
  ///
  /// In en, this message translates to:
  /// **'Manual search'**
  String get manualSearch;

  /// No description provided for @browseCategory.
  ///
  /// In en, this message translates to:
  /// **'Browse by Category'**
  String get browseCategory;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get furniture;

  /// No description provided for @carpets.
  ///
  /// In en, this message translates to:
  /// **'Carpets'**
  String get carpets;

  /// No description provided for @linens.
  ///
  /// In en, this message translates to:
  /// **'Linens'**
  String get linens;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @departments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departments;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @noProductsFoundIn.
  ///
  /// In en, this message translates to:
  /// **'No products found in'**
  String get noProductsFoundIn;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @productFound.
  ///
  /// In en, this message translates to:
  /// **'Product Found!'**
  String get productFound;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @originalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Original Price'**
  String get originalPriceLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @scanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan Another'**
  String get scanAnother;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @resultsFound.
  ///
  /// In en, this message translates to:
  /// **'Results found'**
  String get resultsFound;

  /// No description provided for @startSearching.
  ///
  /// In en, this message translates to:
  /// **'Start searching for products'**
  String get startSearching;

  /// No description provided for @filterSort.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterSort;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortPriceHigh;

  /// No description provided for @sortDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get sortDiscount;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @scanProductCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Product Code'**
  String get scanProductCode;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionRequired;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @placeBarcodeInBox.
  ///
  /// In en, this message translates to:
  /// **'Place the barcode inside the red box'**
  String get placeBarcodeInBox;

  /// No description provided for @codeScannedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Code scanned successfully!'**
  String get codeScannedSuccessfully;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Code Manually'**
  String get enterCodeManually;

  /// No description provided for @searchByID.
  ///
  /// In en, this message translates to:
  /// **'Search by ID'**
  String get searchByID;

  /// No description provided for @enterProductID.
  ///
  /// In en, this message translates to:
  /// **'Enter Product ID (e.g., 250-10-0001-01-00002)'**
  String get enterProductID;

  /// No description provided for @tryTheseIDs.
  ///
  /// In en, this message translates to:
  /// **'Try these IDs:'**
  String get tryTheseIDs;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @editQuantity.
  ///
  /// In en, this message translates to:
  /// **'Edit Quantity'**
  String get editQuantity;

  /// No description provided for @editQuantityAdmin.
  ///
  /// In en, this message translates to:
  /// **'Edit Quantity (Admin)'**
  String get editQuantityAdmin;

  /// No description provided for @newQuantity.
  ///
  /// In en, this message translates to:
  /// **'New Quantity'**
  String get newQuantity;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get units;

  /// No description provided for @enterQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity (0 or more)'**
  String get enterQuantityHint;

  /// No description provided for @quantityUpdateHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the new quantity for this product. This will update the inventory immediately.'**
  String get quantityUpdateHelper;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity (0 or more)'**
  String get enterValidQuantity;

  /// No description provided for @quantityUpdated.
  ///
  /// In en, this message translates to:
  /// **'✅ Quantity Updated!'**
  String get quantityUpdated;

  /// No description provided for @inventoryUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Inventory has been updated successfully'**
  String get inventoryUpdatedSuccess;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Update Failed'**
  String get updateFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @updatingInventory.
  ///
  /// In en, this message translates to:
  /// **'🔄 Updating Inventory'**
  String get updatingInventory;

  /// No description provided for @pleaseWaitUpdating.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we update the quantity...'**
  String get pleaseWaitUpdating;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update quantity'**
  String get failedToUpdate;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @warehouseInformation.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Information'**
  String get warehouseInformation;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @sector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get sector;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @searchingForProduct.
  ///
  /// In en, this message translates to:
  /// **'Searching for product...'**
  String get searchingForProduct;

  /// No description provided for @enterProductIdToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter a product ID to search'**
  String get enterProductIdToSearch;

  /// No description provided for @scanBarcodeOrType.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or type the product ID manually'**
  String get scanBarcodeOrType;

  /// No description provided for @enterProductIdInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter a product ID or scan a barcode to view detailed product information'**
  String get enterProductIdInstruction;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get currentPrice;

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original Price'**
  String get originalPrice;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmount;

  /// No description provided for @discountPercentage.
  ///
  /// In en, this message translates to:
  /// **'Discount Percentage'**
  String get discountPercentage;

  /// No description provided for @stockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockQuantity;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @warehouseAndInventory.
  ///
  /// In en, this message translates to:
  /// **'Warehouse & Inventory'**
  String get warehouseAndInventory;

  /// No description provided for @availableQuantitynow.
  ///
  /// In en, this message translates to:
  /// **'Available Quantity'**
  String get availableQuantitynow;

  /// No description provided for @inventoryValue.
  ///
  /// In en, this message translates to:
  /// **'Inventory Value'**
  String get inventoryValue;

  /// No description provided for @fullDetails.
  ///
  /// In en, this message translates to:
  /// **'Full Details'**
  String get fullDetails;

  /// No description provided for @reserveProduct.
  ///
  /// In en, this message translates to:
  /// **'Reserve Product'**
  String get reserveProduct;

  /// No description provided for @reserveThisProduct.
  ///
  /// In en, this message translates to:
  /// **'Reserve This Product'**
  String get reserveThisProduct;

  /// No description provided for @reservationCreated.
  ///
  /// In en, this message translates to:
  /// **'Reservation Created!'**
  String get reservationCreated;

  /// No description provided for @reservationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your reservation has been confirmed'**
  String get reservationConfirmed;

  /// No description provided for @myReservations.
  ///
  /// In en, this message translates to:
  /// **'My Reservations'**
  String get myReservations;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @noReservationsYet.
  ///
  /// In en, this message translates to:
  /// **'No reservations yet'**
  String get noReservationsYet;

  /// No description provided for @yourReservationsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your product reservations will appear here'**
  String get yourReservationsAppearHere;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'copied to clipboard'**
  String get copied;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @availableQuantity.
  ///
  /// In en, this message translates to:
  /// **'متوفر: {count}'**
  String availableQuantity(int count);

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @notEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock available'**
  String get notEnoughStock;

  /// No description provided for @pickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get pickupDate;

  /// No description provided for @pickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup Time'**
  String get pickupTime;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @pleaseSelectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup date and time'**
  String get pleaseSelectDateTime;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @anySpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Any special requests?'**
  String get anySpecialRequests;

  /// No description provided for @confirmReservation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reservation'**
  String get confirmReservation;

  /// No description provided for @cancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reservation'**
  String get cancelReservation;

  /// No description provided for @cancelReservationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reservation?'**
  String get cancelReservationQuestion;

  /// No description provided for @sureToCancel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this reservation? Stock will be restored.'**
  String get sureToCancel;

  /// No description provided for @reservationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled successfully'**
  String get reservationCancelled;

  /// No description provided for @stockRestored.
  ///
  /// In en, this message translates to:
  /// **'Stock restored'**
  String get stockRestored;

  /// No description provided for @markAsFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Mark as Fulfilled'**
  String get markAsFulfilled;

  /// No description provided for @markedAsFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Reservation marked as fulfilled'**
  String get markedAsFulfilled;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @fulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get fulfilled;

  /// No description provided for @pastDue.
  ///
  /// In en, this message translates to:
  /// **'Past Due'**
  String get pastDue;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @activeReservations.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String activeReservations(int count);

  /// No description provided for @fulfilledReservations.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled ({count})'**
  String fulfilledReservations(int count);

  /// No description provided for @allReservations.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String allReservations(int count);

  /// No description provided for @noActiveReservations.
  ///
  /// In en, this message translates to:
  /// **'No active reservations'**
  String get noActiveReservations;

  /// No description provided for @noFulfilledReservations.
  ///
  /// In en, this message translates to:
  /// **'No fulfilled reservations'**
  String get noFulfilledReservations;

  /// No description provided for @reservedOn.
  ///
  /// In en, this message translates to:
  /// **'Reserved {date}'**
  String reservedOn(String date);

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @viewManageReservations.
  ///
  /// In en, this message translates to:
  /// **'View and manage your product reservations'**
  String get viewManageReservations;

  /// No description provided for @failedToCreateReservation.
  ///
  /// In en, this message translates to:
  /// **'Failed to create reservation'**
  String get failedToCreateReservation;

  /// No description provided for @failedToLoadReservations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reservations'**
  String get failedToLoadReservations;

  /// No description provided for @failedToCancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel reservation'**
  String get failedToCancelReservation;

  /// No description provided for @failedToFulfillReservation.
  ///
  /// In en, this message translates to:
  /// **'Failed to fulfill reservation'**
  String get failedToFulfillReservation;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @notEnoughQuantityTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Enough Stock'**
  String get notEnoughQuantityTitle;

  /// No description provided for @notEnoughQuantityMessage.
  ///
  /// In en, this message translates to:
  /// **'There isn\'t enough quantity! Available: {available}, Requested: {requested}'**
  String notEnoughQuantityMessage(int available, int requested);

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get validationPasswordMinLength;

  /// No description provided for @validationPasswordLettersNumbers.
  ///
  /// In en, this message translates to:
  /// **'Password must contain both letters and numbers'**
  String get validationPasswordLettersNumbers;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get validationNameRequired;

  /// No description provided for @validationNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters long'**
  String get validationNameMinLength;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsNotMatch;

  /// No description provided for @validationAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms and Conditions'**
  String get validationAgreeToTerms;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check your internet connection.'**
  String get errorConnection;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please try again.'**
  String get errorNetwork;

  /// No description provided for @errorServerError.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred. Please try again later.'**
  String get errorServerError;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested information was not found.'**
  String get errorNotFound;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get errorForbidden;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please check the inputs.'**
  String get errorBadRequest;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'A data conflict occurred. Please refresh and try again.'**
  String get errorConflict;

  /// No description provided for @errorBadGateway.
  ///
  /// In en, this message translates to:
  /// **'The server is temporarily unavailable. Please try again.'**
  String get errorBadGateway;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again later.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorGatewayTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server did not respond in time. Please try again.'**
  String get errorGatewayTimeout;

  /// No description provided for @errorClientError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred with the request. Please try again.'**
  String get errorClientError;

  /// No description provided for @errorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response from the server. Please try again.'**
  String get errorInvalidResponse;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue.'**
  String get errorNotAuthenticated;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorUserExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorUserExists;

  /// No description provided for @errorProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found. Please check the product ID.'**
  String get errorProductNotFound;

  /// No description provided for @errorInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'There is not enough stock available for this order.'**
  String get errorInsufficientStock;

  /// No description provided for @successLogin.
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome back.'**
  String get successLogin;

  /// No description provided for @successSignup.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Welcome!'**
  String get successSignup;

  /// No description provided for @successLogout.
  ///
  /// In en, this message translates to:
  /// **'You have been logged out successfully.'**
  String get successLogout;

  /// No description provided for @successReservationCreated.
  ///
  /// In en, this message translates to:
  /// **'Reservation created successfully!'**
  String get successReservationCreated;

  /// No description provided for @successReservationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled successfully.'**
  String get successReservationCancelled;

  /// No description provided for @successReservationFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Reservation has been marked as fulfilled.'**
  String get successReservationFulfilled;

  /// No description provided for @successQuantityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product quantity updated successfully.'**
  String get successQuantityUpdated;

  /// No description provided for @successGeneric.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully!'**
  String get successGeneric;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get tryAgainLater;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get checkConnection;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'If the problem persists, please contact support.'**
  String get contactSupport;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
