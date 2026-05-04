import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import '../localization/app_strings.dart';

// This screen allows existing users to log in to the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final lang = 'en'; // temporary for now, until settings is connected

class _LoginScreenState extends State<LoginScreen> {
  // These controllers hold what the user types in the fields.
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // This service handles Firebase Authentication actions.
  final AuthService _authService = AuthService();

  // This helps show loading while login is in progress.
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up the controllers when the screen is removed.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // This handles the login process.
  Future<void> _handleLogin() async {
    // Remove keyboard from screen before login starts.
    FocusScope.of(context).unfocus();

    // Check if the fields are empty before continuing.
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.text(lang, 'loginEmptyFields'))),
      );
      return;
    }

    // Show loading state while Firebase login is running.
    setState(() {
      _isLoading = true;
    });

    // Try logging the user in with Firebase Authentication.
    final String? result = await _authService.signIn(
      email: emailController.text,
      password: passwordController.text,
    );

    // Stop loading after the request is complete.
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    // If result is null, login was successful.
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.text(lang, 'loginSuccessful'))),
      );

      // Do not navigate manually here.
      // AuthGate in main.dart will detect the signed-in user
      // and move the app into the signed-in flow automatically
    } else {
      // If there is an error message, show it to the user.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background for this screen.
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      body: SafeArea(
        child: SingleChildScrollView(
          // This helps prevent overflow, especially when the keyboard opens.
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 55),

                // Main app logo.
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4D24D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D8CE0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Main welcome text.
                Text(
                  AppStrings.text(lang, 'welcomeBack'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  AppStrings.text(lang, 'loginSubtitle'),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 42),

                // Google sign-in button.
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      // Google sign-in can be added later.
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.text(lang, 'continueWith'),
                            style: const TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: AppStrings.text(lang, 'google'),
                            style: const TextStyle(color: Color(0xFF2D8CE0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Apple sign-in button.
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apple sign-in can be added later.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      AppStrings.text(lang, 'continueWithApple'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Small divider text before the form.
                Text(
                  AppStrings.text(lang, 'or'),
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 18),

                // Email input field.
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: AppStrings.text(lang, 'enterEmail'),
                    hintStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFEAEAEA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Password input field.
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: AppStrings.text(lang, 'enterPassword'),
                    hintStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFEAEAEA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Login button.
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D8CE0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            AppStrings.text(lang, 'logIn'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                // Link to the sign-up screen.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.text(lang, 'noAccount'),
                      style: TextStyle(fontSize: 15, color: Color(0xFF2D8CE0)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.text(lang, 'signUp'),
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2D8CE0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Language display text.
                const Text(
                  'English | Hausa',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
