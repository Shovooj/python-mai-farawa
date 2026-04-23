import 'dart:async';
import 'package:flutter/material.dart';
import '../data/lesson_data.dart';
import 'login_screen.dart';

// SplashScreen is the first screen shown when the app starts.
// It prepares lesson data, waits briefly, and then opens the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Start app setup immediately after the splash screen appears.
    _startApp();
  }

  Future<void> _startApp() async {
    try {
      // Load and prepare lesson data before entering the main app.
      await LessonData.initializeLessons();
    } catch (e) {
      // Print any startup error for debugging.
      debugPrint('Lesson initialization error: $e');
    }

    // Keep the splash screen visible for a short time.
    await Future.delayed(const Duration(seconds: 3));

    // Stop if this screen is no longer active.
    if (!mounted) return;

    // Move from splash screen to login screen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Main brand colors used in the splash screen design.
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
                // Top spacer pushes the main logo/text section downward
                // so it sits closer to the visual center of the screen.
                const Spacer(flex: 5),

                // Center the full branding block horizontally.
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular logo container.
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

                      // Main application title.
                      const Text(
                        'Python Mai Farawa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle describing the purpose of the app.
                      const Text(
                        'Learn basic Python in Hausa language',
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

                // This spacer creates the large empty blue area between
                // the branding block and the loader near the bottom.
                const Spacer(flex: 6),

                // Center the loading indicator horizontally.
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

                // Small bottom spacing for a cleaner finish.
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
