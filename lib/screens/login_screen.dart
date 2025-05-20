/*import 'package:flutter/material.dart';
import 'package:pain/services/auth_service.dart'; // Updated to use firebase_service
import 'package:pain/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorFeedback;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppPaddings.screen,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      const Icon(Icons.menu_book_rounded, size: 60, color: Colors.green),
                      const SizedBox(height: 8),
                      const Text("SwipeLit", style: AppTextStyles.heading),
                      const SizedBox(height: 32),

                      // Form section
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: Text(
                                "Sign in to your account!",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.green),
                                ),
                              ),
                              validator: (value) {
                                if(value == null || value.isEmpty) {
                                  return "Please enter your email";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "Password",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.green),
                                ),
                              ),
                              validator: (value) {
                                if(value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                            ),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/resetPassword');
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            if(_errorFeedback != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorFeedback!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Continue button
                      ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          if(_formKey.currentState!.validate()) {
                            setState(() {
                              _errorFeedback = null;
                              _isLoading = true;
                            });

                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();

                            final user = await FirebaseService.signIn(email, password);

                            setState(() {
                              _isLoading = false;
                            });

                            if(user == null) {
                              setState(() {
                                _errorFeedback = "Incorrect login credentials!";
                              });
                            } else {
                              Navigator.pushReplacementNamed(context, '/bookDiscovery');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // OR divider
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("OR", style: TextStyle(color: Colors.black54)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google button - redesigned
                      OutlinedButton(
                        onPressed: _isGoogleLoading ? null : () async {
                          setState(() {
                            _errorFeedback = null;
                            _isGoogleLoading = true;
                          });

                          final user = await FirebaseService.signInWithGoogle();

                          setState(() {
                            _isGoogleLoading = false;
                          });

                          if(user == null) {
                            setState(() {
                              _errorFeedback = "Google sign-in was cancelled!";
                            });
                          } else {
                            Navigator.pushReplacementNamed(context, '/bookDiscovery');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey, width: 1),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google logo
                            Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Login with Google",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 17, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 28),
                            if (_isGoogleLoading) ...[
                              const SizedBox(width: 12),
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Move the "Don't have an account?" section to a separate column
                  // so it doesn't push up when content is added above
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/phoneEntry');
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:pain/services/auth_service.dart'; // Updated to use firebase_service
import 'package:pain/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorFeedback;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppPaddings.screen,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.menu_book_rounded, size: 60, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text("SwipeLit", style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      )),
                      const SizedBox(height: 32),

                      // Form section
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Text(
                                "Sign in to your account!",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Email",
                                labelStyle: TextStyle(color: textSecondaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                filled: isDarkMode,
                                fillColor: isDarkMode ? Colors.grey.shade800 : null,
                              ),
                              validator: (value) {
                                if(value == null || value.isEmpty) {
                                  return "Please enter your email";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: TextStyle(color: textSecondaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                filled: isDarkMode,
                                fillColor: isDarkMode ? Colors.grey.shade800 : null,
                              ),
                              validator: (value) {
                                if(value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                            ),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/resetPassword');
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            if(_errorFeedback != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorFeedback!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Continue button
                      ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          if(_formKey.currentState!.validate()) {
                            setState(() {
                              _errorFeedback = null;
                              _isLoading = true;
                            });

                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();

                            final user = await FirebaseService.signIn(email, password);

                            setState(() {
                              _isLoading = false;
                            });

                            if(user == null) {
                              setState(() {
                                _errorFeedback = "Incorrect login credentials!";
                              });
                            } else {
                              Navigator.pushReplacementNamed(context, '/bookDiscovery');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // OR divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: textSecondaryColor)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("OR", style: TextStyle(color: textSecondaryColor)),
                          ),
                          Expanded(child: Divider(color: textSecondaryColor)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google button - redesigned
                      OutlinedButton(
                        onPressed: _isGoogleLoading ? null : () async {
                          setState(() {
                            _errorFeedback = null;
                            _isGoogleLoading = true;
                          });

                          final user = await FirebaseService.signInWithGoogle();

                          setState(() {
                            _isGoogleLoading = false;
                          });

                          if(user == null) {
                            setState(() {
                              _errorFeedback = "Google sign-in was cancelled!";
                            });
                          } else {
                            Navigator.pushReplacementNamed(context, '/bookDiscovery');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey,
                            width: 1,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: cardColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google logo
                            const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Login with Google",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 28),
                            if (_isGoogleLoading) ...[
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(textSecondaryColor),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Move the "Don't have an account?" section to a separate column
                  // so it doesn't push up when content is added above
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(color: textColor)),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/phoneEntry');
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}