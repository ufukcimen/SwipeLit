import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';

class SignUpNameScreen extends ConsumerStatefulWidget {
  const SignUpNameScreen({super.key});

  @override
  ConsumerState<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends ConsumerState<SignUpNameScreen> {
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if returning to this screen
    final signupState = ref.read(signupProvider);
    if (signupState.name != null) {
      nameController.text = signupState.name!;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Progress bar colors
    final progressBgColor = isDarkMode
        ? AppColors.primary.withOpacity(0.3)
        : Colors.green.shade100;

    // Input field colors
    final inputBorderColor = isDarkMode
        ? Colors.grey[700]
        : Colors.green.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 🔁 Back button + progress bar
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.5,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: progressBgColor,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1 / 6, // 1st step
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              Text(
                "What's Your Name?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                "Let's Get to Know Each Other",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  hintStyle: TextStyle(color: textSecondaryColor),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: BorderSide(color: inputBorderColor!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () {
                  final name = nameController.text.trim();
                  final nameRegex = RegExp(r'^[a-zA-Z\s]+$');

                  if (name.isNotEmpty && nameRegex.hasMatch(name)) {
                    // Save name to provider
                    ref.read(signupProvider.notifier).setName(name);
                    Navigator.pushNamed(context, '/signupEmail');
                  } else {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text("Invalid Name", style: TextStyle(color: textColor)),
                        content: Text(
                          "Name should contain only letters.",
                          style: TextStyle(color: textColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("OK", style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.black26 : Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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