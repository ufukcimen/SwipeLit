import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> with WidgetsBindingObserver {
  bool openedSettings = false;
  bool _isCreatingUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect when user returns from settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && openedSettings) {
      var status = await Permission.location.status;
      if (status.isGranted && mounted) {
        // If location is granted after returning from settings, get location and create user
        _createUserWithLocation();
      }
      openedSettings = false;
    }
  }

  Future<String?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  Future<void> _createUserWithLocation() async {
    if (_isCreatingUser) return;

    setState(() {
      _isCreatingUser = true;
    });

    try {
      // Get location if permission is granted
      String? locationString;
      var status = await Permission.location.status;
      if (status.isGranted) {
        locationString = await _getCurrentLocation();
      }

      // Get signup data
      final signupState = ref.read(signupProvider);

      // Ensure we have all required data
      if (signupState.name == null ||
          signupState.email == null ||
          signupState.password == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing required user information")),
        );
        setState(() {
          _isCreatingUser = false;
        });
        return;
      }

      // Create user with Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: signupState.email!,
        password: signupState.password!,
      );

      if (userCredential.user == null) {
        throw Exception("Failed to create user account");
      }

      // Create user data for Firestore
      final userData = {
        'uid': userCredential.user!.uid,
        'name': signupState.name,
        'email': signupState.email,
        'phoneNum': signupState.phoneNum ?? "",
        'birthDate': signupState.birthDate?.toIso8601String(),
        'gender': signupState.gender,
        'interests': signupState.interests,
        'uploadedBooks': signupState.uploadedBooks,
        'location': locationString,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      // Clear signup state
      ref.read(signupProvider.notifier).clear();

      // Navigate to book discovery
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/bookDiscovery');
      }

    } catch (e) {
      print("Error creating user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
        setState(() {
          _isCreatingUser = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      // Call the create user method instead of navigating directly
      _createUserWithLocation();  // <-- Change this line
    } else if (status.isDenied || status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white,
          title: Text(
            "Location Required",
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          content: Text(
            "You need to enable location access to use SwipeLit.",
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close", style: TextStyle(color: AppColors.primary)),
            ),
            TextButton(
              onPressed: () async {
                openedSettings = true;
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text("Open Settings", style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            Image.asset(
              'assets/icons/location_icon.png',
              height: 150,
              errorBuilder: (_, __, ___) => Icon(
                Icons.location_on,
                size: 120,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              "Enable Your Location",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Choose your location to start find people around you",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: AppPaddings.screen,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreatingUser ? null : _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 2,
                    shadowColor: isDarkMode ? Colors.black38 : Colors.black12,
                  ),
                  child: _isCreatingUser
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Allow Location Access",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}