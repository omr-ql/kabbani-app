import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../auth/splash_auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? workerName;
  final String? workerEmail;

  const ProfileScreen({
    super.key,
    this.workerName,
    this.workerEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isLoggingOut = false; // ✅ Separate flag for logout process

  @override
  void initState() {
    super.initState();
    print('🔵 ProfileScreen initialized - Name: ${widget.workerName}, Email: ${widget.workerEmail}');
  }

  // ✅ Improved logout state clearing with better error handling
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all login-related data in batch
      await Future.wait([
        prefs.setBool('isLoggedIn', false),
        prefs.remove('workerName'),
        prefs.remove('workerEmail'),
      ]);

      print('✅ Login state cleared from SharedPreferences');
    } catch (e) {
      print('❌ Error clearing login state: $e');
      rethrow; // Re-throw to handle in calling method
    }
  }

  // Get initials from name for avatar
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  // ✅ Improved logout handler with better state management
  void _handleLogout() {
    // Prevent multiple logout attempts
    if (_isLoggingOut) {
      print('⚠️ Logout already in progress, ignoring click');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false, // ✅ Prevent dismissing during logout
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            l10n.logoutConfirmation,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            '${l10n.sureToLogout}, ${widget.workerName ?? 'User'}?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: _isLoggingOut ? Colors.grey[600] : Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoggingOut ? null : () => _performLogout(context),
              child: _isLoggingOut
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                l10n.logout,
                style: const TextStyle(color: Color(0xFFFF4B4B)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Separated logout logic for better error handling
  Future<void> _performLogout(BuildContext dialogContext) async {
    setState(() {
      _isLoading = true;
      _isLoggingOut = true;
    });

    try {
      print('🔵 Starting logout process...');

      // ✅ Close dialog first to prevent UI issues
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      // Perform logout operations
      await Future.wait([
        ApiService.logout(null),
        _clearLoginState(),
      ]);

      if (mounted) {
        print('🚀 Logout successful, navigating to SplashAuthScreen...');

        // ✅ Navigate immediately without showing snackbar to prevent timing issues
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const SplashAuthScreen(),
          ),
              (route) => false, // Clear all routes
        );
      }
    } catch (e) {
      print('💥 Logout error: $e');

      if (mounted) {
        // Reset states on error
        setState(() {
          _isLoading = false;
          _isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.profile,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // Profile Avatar
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF4B4B),
                        const Color(0xFFFF4B4B).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4B4B).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(widget.workerName ?? 'U'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Worker Name Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.name,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.workerName ?? 'Not Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Worker Email Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.workerEmail ?? 'Not Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Language Selection Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.language,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageProvider.isArabic ? l10n.arabic : l10n.english,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: languageProvider.isArabic,
                          onChanged: (value) {
                            languageProvider.toggleLanguage();
                          },
                          activeColor: const Color(0xFFFF4B4B),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey[800],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // ✅ Improved Logout Button with better state handling
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isLoggingOut) ? null : _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: (_isLoading || _isLoggingOut)
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    (_isLoading || _isLoggingOut) ? 'Logging out...' : l10n.logout,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // App Version
              Center(
                child: Text(
                  'Kabbani Home v1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}