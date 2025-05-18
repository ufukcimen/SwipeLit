import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Settings screen placeholder",
          style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
