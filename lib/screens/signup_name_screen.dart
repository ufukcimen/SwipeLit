import 'package:flutter/material.dart';
import 'package:swipelit/utils/constants.dart';

class SignUpNameScreen extends StatefulWidget {
  const SignUpNameScreen({super.key});

  @override
  State<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends State<SignUpNameScreen> {
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                      widthFactor: 1 / 6, // 1st step
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

              const SizedBox(height: 48),

              const Text(
                "What’s Your Name?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary,),
              ),
              const SizedBox(height: 12),
              const Text(
                "Let’s Get to Know Each Other",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () {
                  final name = nameController.text.trim();
                  final nameRegex = RegExp(r'^[a-zA-Z\s]+$');

                  if (name.isNotEmpty && nameRegex.hasMatch(name)) {
                    Navigator.pushNamed(context, '/signupEmail');
                  } else {
                    showDialog(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text("Invalid Name"),
                        content: Text("Name should contain only letters."),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
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
