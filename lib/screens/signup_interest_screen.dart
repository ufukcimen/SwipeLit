import 'package:flutter/material.dart';
import 'package:swipelit/utils/constants.dart';

class SignUpInterestScreen extends StatefulWidget {
  const SignUpInterestScreen({super.key});

  @override
  State<SignUpInterestScreen> createState() => _SignUpInterestScreenState();
}

class _SignUpInterestScreenState extends State<SignUpInterestScreen> {
  final List<String> interests = [
    "History", "Poetry",
    "Sci-fi", "Magazine", "Fantasy",
    "Adventure", "Romance",
    "Politics", "Cooking", "Psychology",
    "Sports", "Fashion"
  ];

  final Set<String> selected = {};

  void toggleSelection(String interest) {
    setState(() {
      if (selected.contains(interest)) {
        selected.remove(interest);
      } else {
        if (selected.length < 3) selected.add(interest);
      }
    });
  }

  Widget buildInterestRow(List<String> row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: row.map((interest) {
        final isSelected = selected.contains(interest);
        return GestureDetector(
          onTap: () => toggleSelection(interest),
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,

              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary,),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.5,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.green.shade100,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 5 / 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                "Select Up To 3 Interest",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tell us what piques your curiosity and passions",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 28),

              // Interest Grid Rows
              buildInterestRow(["History", "Poetry"]),
              buildInterestRow(["Sci-fi", "Magazine", "Fantasy"]),
              buildInterestRow(["Adventure", "Romance"]),
              buildInterestRow(["Politics", "Cooking", "Psychology"]),
              buildInterestRow(["Sports", "Fashion"]),

              const Spacer(),

              // ✅ Continue Button
              GestureDetector(
                onTap: () {
                  if (selected.isNotEmpty) {
                    Navigator.pushNamed(context, '/signupUpload');
                  }
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: selected.isNotEmpty ? Colors.green : Colors.green.shade200,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: selected.isNotEmpty
                        ? [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
