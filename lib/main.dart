import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Screens
import 'screens/chat_list_screen.dart'; // 👈 create this file if not already
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/phone_entry_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/signup_name_screen.dart';
import 'screens/signup_email_screen.dart';
import 'screens/signup_age_screen.dart';
import 'screens/signup_gender_screen.dart';
import 'screens/signup_interest_screen.dart';
import 'screens/signup_book_upload_screen.dart';
import 'screens/location_permission_screen.dart';
import 'screens/book_discovery_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_user_info_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/update_gallery_screen.dart';


void main() {
  runApp(const SwipeLitApp());
}

class SwipeLitApp extends StatelessWidget {
  const SwipeLitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeLit',
      theme: ThemeData(
        fontFamily: 'Inter', // ✅ This line sets Inter as the default font
        scaffoldBackgroundColor: AppColors.background,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/phoneEntry': (context) => const PhoneEntryScreen(),
        '/otpVerification': (context) => const OTPVerificationScreen(phoneNumber: '', fromSignUp: false),
        '/signupName': (context) => const SignUpNameScreen(),
        '/signupEmail': (context) => const SignUpEmailScreen(),
        '/signupAge': (context) => const SignUpAgeScreen(),
        '/signupGender': (context) => const SignUpGenderScreen(),
        '/signupInterest': (context) => const SignUpInterestScreen(),
        '/signupUpload': (context) => const SignUpUploadBookScreen(),
        '/locationPermission': (context) => const LocationPermissionScreen(),
        '/bookDiscovery': (context) => const BookDiscoveryScreen(),
        '/messages': (context) => const ChatListScreen(),

        '/profile': (context) => const ProfileScreen(),
        '/edit': (context) => const EditUserInfoScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/gallery': (context) => const UpdateGalleryScreen(),

      },
    );
  }
}
