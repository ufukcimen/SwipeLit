import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';

class SignUpInterestScreen extends ConsumerStatefulWidget {
  const SignUpInterestScreen({super.key});

  @override
  ConsumerState<SignUpInterestScreen> createState() => _SignUpInterestScreenState();
}

class _SignUpInterestScreenState extends ConsumerState<SignUpInterestScreen> {
  final List<String> interests = [
    "History", "Poetry",
    "Sci-fi", "Magazine", "Fantasy",
    "Adventure", "Romance",
    "Politics", "Cooking", "Psychology",
    "Sports", "Fashion"
  ];

  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    // Initialize selected interests from the provider
    final signupState = ref.read(signupProvider);
    selected = Set<String>.from(signupState.interests ?? []);
  }

  void toggleSelection(String interest) {
    setState(() {
      if (selected.contains(interest)) {
        selected.remove(interest);
      } else {
        if (selected.length < 3) selected.add(interest);
      }
    });
  }

  Widget interestChip(String interest, Color textColor, Color cardColor, Color borderColor) {
    final isSelected = selected.contains(interest);
    return GestureDetector(
      onTap: () => toggleSelection(interest),
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cardColor,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
          ),
        ),
        child: Text(
          interest,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
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

    // Border color for interest chips
    final borderColor = isDarkMode
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ⬅️ Back + Progress Bar (Step 5/6)
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
                      widthFactor: 5 / 6,
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

              const SizedBox(height: 24),

              Text(
                "Select Up To 3 Interest",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tell us what piques your curiosity and passions",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),

              const SizedBox(height: 20),

              // Interest Grid - Scrollable Wrap
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 0,
                    children: interests.map((interest) {
                      return interestChip(interest, textColor, cardColor, borderColor);
                    }).toList(),
                  ),
                ),
              ),

              // ✅ Continue Button
              GestureDetector(
                onTap: () {
                  if (selected.isNotEmpty) {
                    // Save to provider
                    ref.read(signupProvider.notifier).setInterests(selected.toList());
                    Navigator.pushNamed(context, '/signupUpload');
                  } else {
                    // Show message if no interests selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select at least one interest")),
                    );
                  }
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: selected.isNotEmpty
                        ? AppColors.primary
                        : (isDarkMode
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.green.shade200),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: selected.isNotEmpty
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
}