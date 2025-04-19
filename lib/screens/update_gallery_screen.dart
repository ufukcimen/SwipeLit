import 'package:flutter/material.dart';
import '../utils/constants.dart';

class UpdateGalleryScreen extends StatelessWidget {
  const UpdateGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Update Gallery"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Update gallery screen placeholder",
          style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
