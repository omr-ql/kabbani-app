import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashAuthScreen extends StatefulWidget {
  const SplashAuthScreen({Key? key}) : super(key: key);

  @override
  State<SplashAuthScreen> createState() => _SplashAuthScreenState();
}

class _SplashAuthScreenState extends State<SplashAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation and check auth status
    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      String? workerName = prefs.getString('workerName');
      String? workerEmail = prefs.getString('workerEmail');

      print('🔵 SplashAuth - isLoggedIn: $isLoggedIn');
      print('🔵 SplashAuth - workerName: $workerName');
      print('🔵 SplashAuth - workerEmail: $workerEmail');

      if (mounted) {
        if (isLoggedIn && workerName != null) {
          // User is logged in, navigate to home
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
                workerName: workerName,
                workerEmail: workerEmail,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          // User is not logged in, navigate to login
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      // On error, navigate to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get localization, but provide fallback since this is a splash screen
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (e) {
      // Fallback for when localization isn't ready yet
      l10n = null;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo with Glow Effect
                    Container(
                      width: 150,
                      height: 150,
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
                            color: const Color(0xFFFF4B4B).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App Title - Updated to Kabbani Home
                    const Text(
                      'Kabbani Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle - Localized with fallback
                    Text(
                      l10n?.appSubtitle ?? 'Professional Inventory Management',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading Animation
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFFF4B4B).withOpacity(0.8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Loading Text - Localized with fallback
                    Text(
                      l10n?.initializing ?? 'Initializing...',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
