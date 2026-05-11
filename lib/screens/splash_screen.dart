import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

// Simple splash screen shown on app start. Waits a short duration then
// navigates to the AuthGate which decides whether to show the Home or
// Login screen depending on authentication state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    const Color primaryBlue = Color(0xFF2D8CE0);
    const Color brandYellow = Color(0xFFF4D24D);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 5),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: brandYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        AppStrings.text(lang, 'appTitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.text(lang, 'appTagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 6),
                const Center(
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(brandYellow),
                      backgroundColor: Color(0x33FFFFFF),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
