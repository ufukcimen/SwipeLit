import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';

class SignUpAgeScreen extends ConsumerStatefulWidget {
  const SignUpAgeScreen({super.key});

  @override
  ConsumerState<SignUpAgeScreen> createState() => _SignUpAgeScreenState();
}

class _SignUpAgeScreenState extends ConsumerState<SignUpAgeScreen> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    final signupState = ref.read(signupProvider);
    if (signupState.birthDate != null) {
      selectedDate = signupState.birthDate;
    }
  }

  void _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return "$day/$month/$year";
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
    final borderColor = isDarkMode
        ? Colors.green.shade800
        : Colors.green.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 🔙 Back + Progress bar (step 3 of 6)
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
                      color: progressBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 3 / 6,
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
                "How Old Are You?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please select your birth date",
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),

              // 📅 Date Picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      selectedDate != null
                          ? _formattedDate(selectedDate!)
                          : "Select your birthdate",
                      style: TextStyle(
                        fontSize: 18,
                        color: selectedDate != null
                            ? textColor
                            : textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ✅ Continue Button
              GestureDetector(
                onTap: () {
                  if (selectedDate != null) {
                    // Save to provider
                    ref.read(signupProvider.notifier).setBirthDate(selectedDate!);
                    Navigator.pushNamed(context, '/signupGender');
                  }
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: selectedDate != null
                        ? AppColors.primary
                        : (isDarkMode
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.green.shade200),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      if (selectedDate != null)
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
}