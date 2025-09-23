import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';
import 'screens/auth/splash_auth_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Kabbani Home',

          // Localization configuration
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Put Arabic first as the default supported locale
          supportedLocales: const [
            Locale('ar'), // Arabic - now first/default
            Locale('en'), // English
          ],

          // Add RTL support for Arabic
          builder: (context, child) {
            // Determine text direction based on locale
            final textDirection = languageProvider.locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr;

            return Directionality(
              textDirection: textDirection,
              child: child!,
            );
          },

          theme: ThemeData(
            primarySwatch: Colors.red,
            canvasColor: Colors.transparent,
            useMaterial3: true,

            // Add font family support for Arabic if needed
            fontFamily: languageProvider.locale.languageCode == 'ar'
                ? 'NotoSansArabic'  // You can add Arabic fonts to pubspec.yaml
                : null,
          ),

          debugShowCheckedModeBanner: false,
          home: const SplashAuthScreen(),
          routes: {
            '/splash': (context) => const SplashAuthScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}