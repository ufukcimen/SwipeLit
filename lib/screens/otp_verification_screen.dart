/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';
import 'package:pain/services/auth_service.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool fromSignUp;
  final bool fromEdit;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.fromSignUp = false,
    this.fromEdit = false,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _verificationId;
  int? _resendToken;
  String _errorMessage = '';
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    // Start phone verification when screen loads
    _startPhoneVerification();
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // Firebase Phone Authentication
  Future<void> _startPhoneVerification() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      await FirebaseService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
        resendToken: _resendToken,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  // Auto verification (usually on Android devices)
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    print("Auto verification completed");
    // Auto-verify (usually happens on Android)
    setState(() => _isVerifying = true);

    try {
      if (widget.fromEdit) {
        // Link phone number to current user
        final success = await FirebaseService.linkPhoneNumberToCurrentUser(
            _verificationId ?? '',
            credential.smsCode ?? ''
        );

        if (success) {
          // Return to edit screen with success
          Navigator.pop(context, true);
        } else {
          throw Exception("Failed to link phone number");
        }
      } else {
        // Sign in with the credential for new users
        await FirebaseService.signInWithPhoneAuthCredential(credential);
        _handleAuthSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    print("Verification failed: ${e.message}");
    setState(() {
      _errorMessage = 'Verification failed: ${e.message}';
      _isVerifying = false;
    });
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    print("SMS code sent to ${widget.phoneNumber}");
    setState(() {
      _verificationId = verificationId;
      _resendToken = resendToken;
      _isVerifying = false;
      _codeSent = true;
    });

    // Show a snackbar to inform user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Verification code sent to ${widget.phoneNumber}")),
    );
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    print("Code auto retrieval timeout");
    setState(() {
      _verificationId = verificationId;
      _isVerifying = false;
    });
  }

  void _handleInput(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      _verifyOTP();
    }
  }

  void _verifyOTP() async {
    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification code not yet sent, please wait.';
      });
      return;
    }

    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      if (widget.fromEdit) {
        // Link phone number to current user
        final success = await FirebaseService.linkPhoneNumberToCurrentUser(
            _verificationId!,
            code
        );

        if (success) {
          // Return to edit screen with success
          Navigator.pop(context, true);
        } else {
          throw Exception("Failed to link phone number");
        }
      } else {
        // Sign in with the credential for new users/login
        await FirebaseService.signInWithPhoneAuthCredential(credential);
        _handleAuthSuccess();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Verification error: ${e.message}';
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  void _handleAuthSuccess() async {
    // Handle successful verification based on flow
    if (widget.fromSignUp) {
      // Save the phone number to the signup provider
      ref.read(signupProvider.notifier).setPhoneNum(widget.phoneNumber);

      Navigator.pushReplacementNamed(context, '/signupName');
    } else if (widget.fromEdit) {
      // Return to edit screen with success
      Navigator.pop(context, true);
    } else {
      // Regular login flow
      Navigator.pushReplacementNamed(context, '/bookDiscovery');
    }
  }

  void _resendCode() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      // Reset text fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Focus first field
      FocusScope.of(context).requestFocus(_focusNodes[0]);

      // Request new code
      await _startPhoneVerification();
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String screenTitle = widget.fromEdit
        ? "Verify Phone Number"
        : "Verification Code";

    final String subtitleText = widget.fromEdit
        ? "Please verify your new phone number"
        : "Please enter the code we just sent to";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                screenTitle,
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 12),
              Text(
                subtitleText,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              if (!_codeSent && _isVerifying)
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Sending verification code...",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 40),
                    // OTP Input Fields (6 digits for Firebase)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45,
                          height: 55,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(fontSize: 22),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => _handleInput(index, value),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

              // Error message (if any)
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive OTP? ", style: TextStyle(fontSize: 16)),
                  GestureDetector(
                    onTap: (_isResending || !_codeSent) ? null : _resendCode,
                    child: Text(
                      "Resend Code",
                      style: TextStyle(
                        fontSize: 16,
                        color: (_isResending || !_codeSent) ? Colors.grey : Colors.green,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: (_isVerifying || !_codeSent) ? null : _verifyOTP,
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isVerifying
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                      : const Text(
                    "Verify",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // In edit mode, show explanatory text
              if (widget.fromEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    "You'll return to the edit screen once verification is complete.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';
import 'package:pain/services/auth_service.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool fromSignUp;
  final bool fromEdit;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.fromSignUp = false,
    this.fromEdit = false,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _verificationId;
  int? _resendToken;
  String _errorMessage = '';
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    // Start phone verification when screen loads
    _startPhoneVerification();
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // Firebase Phone Authentication
  Future<void> _startPhoneVerification() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      await FirebaseService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
        resendToken: _resendToken,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  // Auto verification (usually on Android devices)
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    print("Auto verification completed");
    // Auto-verify (usually happens on Android)
    setState(() => _isVerifying = true);

    try {
      if (widget.fromEdit) {
        // Link phone number to current user
        final success = await FirebaseService.linkPhoneNumberToCurrentUser(
            _verificationId ?? '',
            credential.smsCode ?? ''
        );

        if (success) {
          // Return to edit screen with success
          Navigator.pop(context, true);
        } else {
          throw Exception("Failed to link phone number");
        }
      } else {
        // Sign in with the credential for new users
        await FirebaseService.signInWithPhoneAuthCredential(credential);
        _handleAuthSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    print("Verification failed: ${e.message}");
    setState(() {
      _errorMessage = 'Verification failed: ${e.message}';
      _isVerifying = false;
    });
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    print("SMS code sent to ${widget.phoneNumber}");
    setState(() {
      _verificationId = verificationId;
      _resendToken = resendToken;
      _isVerifying = false;
      _codeSent = true;
    });

    // Show a snackbar to inform user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Verification code sent to ${widget.phoneNumber}")),
    );
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    print("Code auto retrieval timeout");
    setState(() {
      _verificationId = verificationId;
      _isVerifying = false;
    });
  }

  void _handleInput(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      _verifyOTP();
    }
  }

  void _verifyOTP() async {
    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification code not yet sent, please wait.';
      });
      return;
    }

    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      if (widget.fromEdit) {
        // Link phone number to current user
        final success = await FirebaseService.linkPhoneNumberToCurrentUser(
            _verificationId!,
            code
        );

        if (success) {
          // Return to edit screen with success
          Navigator.pop(context, true);
        } else {
          throw Exception("Failed to link phone number");
        }
      } else {
        // Sign in with the credential for new users/login
        await FirebaseService.signInWithPhoneAuthCredential(credential);
        _handleAuthSuccess();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Verification error: ${e.message}';
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  void _handleAuthSuccess() async {
    // Handle successful verification based on flow
    if (widget.fromSignUp) {
      // Save the phone number to the signup provider
      ref.read(signupProvider.notifier).setPhoneNum(widget.phoneNumber);

      Navigator.pushReplacementNamed(context, '/signupName');
    } else if (widget.fromEdit) {
      // Return to edit screen with success
      Navigator.pop(context, true);
    } else {
      // Regular login flow
      Navigator.pushReplacementNamed(context, '/bookDiscovery');
    }
  }

  void _resendCode() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      // Reset text fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Focus first field
      FocusScope.of(context).requestFocus(_focusNodes[0]);

      // Request new code
      await _startPhoneVerification();
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String screenTitle = widget.fromEdit
        ? "Verify Phone Number"
        : "Verification Code";

    final String subtitleText = widget.fromEdit
        ? "Please verify your new phone number"
        : "Please enter the code we just sent to";

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                screenTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitleText,
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              if (!_codeSent && _isVerifying)
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text("Sending verification code...",
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 40),
                    // OTP Input Fields (6 digits for Firebase)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45,
                          height: 55,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: TextStyle(fontSize: 22, color: textColor),
                              decoration: InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                fillColor: cardColor,
                                filled: true,
                              ),
                              onChanged: (value) => _handleInput(index, value),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

              // Error message (if any)
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive OTP? ",
                      style: TextStyle(fontSize: 16, color: textColor)),
                  GestureDetector(
                    onTap: (_isResending || !_codeSent) ? null : _resendCode,
                    child: Text(
                      "Resend Code",
                      style: TextStyle(
                        fontSize: 16,
                        color: (_isResending || !_codeSent)
                            ? Colors.grey
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: (_isVerifying || !_codeSent) ? null : _verifyOTP,
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black26
                            : Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isVerifying
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                      : const Text(
                    "Verify",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // In edit mode, show explanatory text
              if (widget.fromEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    "You'll return to the edit screen once verification is complete.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}