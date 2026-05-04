import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

// This screen allows a new user to create an account.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // These controllers hold what the user types.
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // This service handles Firebase Authentication actions.
  final AuthService _authService = AuthService();

  // This helps show loading while account creation is in progress.
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    // Clean up the controllers when the screen is removed.
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // This handles account creation.
  Future<void> _handleSignUp() async {
    // Remove keyboard from screen before sign-up starts.
    FocusScope.of(context).unfocus();
    final lang = context.read<LanguageProvider>().languageCode;

    // Validate the fields before continuing.
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.text(lang, 'signupEmptyFields'))),
      );
      return;
    }

    // Show loading state while Firebase sign-up is running.
    setState(() {
      _isEmailLoading = true;
    });

    // Try creating the account using Firebase Authentication.
    final String? result = await _authService.signUp(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Stop loading after the request is complete.
    if (!mounted) return;
    setState(() {
      _isEmailLoading = false;
    });

    // If result is null, sign-up was successful.
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.text(lang, 'accountCreated'))),
      );

      // Clear the fields after successful sign-up.
      nameController.clear();
      emailController.clear();
      passwordController.clear();
    } else {
      // If there is an error message, show it to the user.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final lang = context.read<LanguageProvider>().languageCode;
    final messenger = ScaffoldMessenger.of(context);

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
    });

    final String? result = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.text(lang, 'accountCreated'))),
      );

      // No manual navigation here.
      // AuthGate should move the user automatically.
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    return Scaffold(
      // White background, just like the screen design.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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

                // Welcome text for new users.
                Text(
                  AppStrings.text(lang, 'startLearning'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 6),

                // Short helper text for the sign-up screen.
                Text(
                  AppStrings.text(lang, 'signupSubtitle'),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 42),

                // Google sign-up button.
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: (_isEmailLoading || _isGoogleLoading)
                        ? null
                        : _handleGoogleSignUp,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2D8CE0),
                              ),
                            ),
                          )
                        : RichText(
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
                                  style: const TextStyle(
                                    color: Color(0xFF2D8CE0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // Apple sign-up button.
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apple sign-up can be added later.
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

                // Small divider text before the form fields.
                Text(
                  AppStrings.text(lang, 'orEnterDetails'),
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 18),

                // Name input field.
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: AppStrings.text(lang, 'fullName'),
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

                // Email input field.
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: AppStrings.text(lang, 'email'),
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
                    hintText: AppStrings.text(lang, 'password'),
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

                // Create account button.
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: (_isEmailLoading || _isGoogleLoading)
                        ? null
                        : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D8CE0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isEmailLoading
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
                            AppStrings.text(lang, 'createAccount'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                // Link for users who already have an account.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.text(lang, 'alreadyHaveAccount'),
                      style: TextStyle(fontSize: 15, color: Color(0xFF2D8CE0)),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Go back to the login screen.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.text(lang, 'logIn'),
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2D8CE0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
