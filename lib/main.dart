import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pain/providers/theme_provider.dart';
import 'package:pain/screens/forgot_password_screen.dart';
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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/upload_books_screen.dart'; // New screen for uploading books
import 'screens/book_details_screen.dart'; // New screen for book details


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(
    child: SwipeLitApp(),
  ));
}
/*
* @override
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
      routes:
* */


class SwipeLitApp extends ConsumerWidget {
  const SwipeLitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the theme state
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SwipeLit',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.backgroundDark,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.textPrimaryDark,
          displayColor: AppColors.textPrimaryDark,
          fontFamily: 'Inter',
        ),
        cardColor: AppColors.cardDark,
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.black26,
          filled: true,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/phoneEntry': (context) => const PhoneEntryScreen(),
        '/otpVerification': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OTPVerificationScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
            fromSignUp: args?['fromSignUp'] ?? false,
            fromEdit: args?['fromEdit'] ?? false,
          );
        },
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
        '/settings': (context) => const SettingsPage(),
        '/gallery': (context) => const UpdateGalleryScreen(),
        '/resetPassword': (context) => const PasswordResetScreen(),
        '/uploadBook': (context) => const UploadBookScreen(),
        '/bookDetails': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return BookDetailsScreen(
        book: args?['book'],
        index: args?['index'] ?? 0,
        isEditing: args?['isEditing'] ?? false,
        );

      },}
    );
  }
}
