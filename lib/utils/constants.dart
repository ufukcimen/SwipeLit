import 'package:flutter/material.dart';

class AppColors {
  // Original light mode colors
  static const background = Color(0xFFDFF7F6); // Light mint background
  static const primary = Colors.green;
  static const textPrimary = Colors.black87;
  static const textSecondary = Colors.black54;
  static const white = Colors.white;

  // Dark mode colors
  static const backgroundDark = Color(0xFF121212); // Dark background like settings page
  static const cardDark = Color(0xFF1E1E1E); // Darker card background like in settings
  static const textPrimaryDark = Colors.white;
  static const textSecondaryDark = Colors.white70;

  // Chat colors
  static const receivedMessageLight = Color(0xFFE8E8E8);
  static const receivedMessageDark = Color(0xFF2A2A2A);
  static const sentMessageLight = Color(0xFF4CAF50); // Green bubble
  static const sentMessageDark = Color(0xFF4CAF50); // Keep green for sent messages

  // Dynamic color getters - use these in your UI
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : background;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardDark
        : white;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondary;
  }

  static Color getReceivedMessageColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? receivedMessageDark
        : receivedMessageLight;
  }

  static Color getSentMessageColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? sentMessageDark
        : sentMessageLight;
  }

  // Input field background color
  static Color getInputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black26
        : Colors.white;
  }

  // Border color for inputs
  static Color getInputBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black12;
  }
}

class AppTextStyles {
  // Original static styles (preserved for compatibility)
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

  // Dynamic styles - use these for theme-aware text
  static TextStyle getHeading(BuildContext context) {
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: AppColors.getTextPrimary(context),
    );
  }

  static TextStyle getSubheading(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      color: AppColors.getTextSecondary(context),
    );
  }

  static TextStyle getBodyText(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: AppColors.getTextPrimary(context),
    );
  }

  static TextStyle getInputText(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      color: AppColors.getTextPrimary(context),
    );
  }

  static TextStyle getInputLabelText(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      color: AppColors.getTextSecondary(context),
    );
  }
}

class AppPaddings {
  static const screen = EdgeInsets.symmetric(horizontal: 24);
  static const betweenSections = SizedBox(height: 32);
}

// Add a class for theme-aware decoration styles
class AppDecorations {
  // Card decoration
  static BoxDecoration getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.getCardBackground(context),
      borderRadius: BorderRadius.circular(12),
      boxShadow: Theme.of(context).brightness == Brightness.dark
          ? [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: Offset(0, 2),
        )
      ]
          : [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 2),
        )
      ],
    );
  }

  // Input decoration
  static InputDecoration getInputDecoration(BuildContext context, {String? labelText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.getInputLabelText(context),
      filled: true,
      fillColor: AppColors.getInputBackground(context),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.getInputBorder(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}