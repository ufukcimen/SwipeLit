import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';

class SignUpGenderScreen extends ConsumerStatefulWidget {
  const SignUpGenderScreen({super.key});

  @override
  ConsumerState<SignUpGenderScreen> createState() => _SignUpGenderScreenState();
}

class _SignUpGenderScreenState extends ConsumerState<SignUpGenderScreen> {
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    final signupState = ref.read(signupProvider);
    if (signupState.gender != null) {
      selectedGender = signupState.gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Progress bar colors
    final progressBgColor = isDarkMode
        ? AppColors.primary.withOpacity(0.3)
        : Colors.green.shade100;

    // Gender option colors
    final unselectedOptionColor = isDarkMode
        ? AppColors.primary.withOpacity(0.2)
        : Colors.green.shade100;
    final unselectedTextColor = isDarkMode
        ? Colors.white
        : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Back + Progress Bar (Step 4 of 6)
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
                      widthFactor: 4 / 6,
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
                "What's Your Gender?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Tell us about your gender",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),

              const Spacer(),

              _buildGenderOption("Male", Icons.male, isDarkMode, unselectedOptionColor, unselectedTextColor),
              const SizedBox(height: 40),
              _buildGenderOption("Female", Icons.female, isDarkMode, unselectedOptionColor, unselectedTextColor),

              const Spacer(),

              // Continue button
              GestureDetector(
                onTap: () {
                  if (selectedGender != null) {
                    // Save to provider
                    ref.read(signupProvider.notifier).setGender(selectedGender!);
                    Navigator.pushNamed(context, '/signupInterest');
                  }
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: selectedGender != null
                        ? AppColors.primary
                        : (isDarkMode
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.green.shade200),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: selectedGender != null
                        ? [
                      BoxShadow(
                        color: isDarkMode ? Colors.black26 : Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, IconData icon, bool isDarkMode, Color unselectedColor, Color unselectedTextColor) {
    final isSelected = selectedGender == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : unselectedColor,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
            BoxShadow(
                color: isDarkMode
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.green.shade200,
                blurRadius: 10
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                icon,
                size: 60,
                color: isSelected ? Colors.white : unselectedTextColor
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : unselectedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}