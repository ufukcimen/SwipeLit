import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFDFF7F6);
  static const primary = Colors.green;
  static const textPrimary = Colors.black87;
  static const textSecondary = Colors.black54;
  static const white = Colors.white;
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const subheading = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static const buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}

class AppPaddings {
  static const screen = EdgeInsets.symmetric(horizontal: 24);
  static const betweenSections = SizedBox(height: 32);
}
