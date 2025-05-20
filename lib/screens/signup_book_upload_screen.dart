/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';

class SignUpUploadBookScreen extends ConsumerStatefulWidget {
  const SignUpUploadBookScreen({super.key});

  @override
  ConsumerState<SignUpUploadBookScreen> createState() => _SignUpUploadBookScreenState();
}

class _SignUpUploadBookScreenState extends ConsumerState<SignUpUploadBookScreen> {
  final List<File> _bookImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // We won't try to load existing book images as they're File objects
    // In a real app, you'd likely store image URLs and load them here
  }

  Future<void> _pickImage() async {
    print("📸 PLUS BUTTON TAPPED");

    var status = await Permission.photos.request();

    if (!status.isGranted) {
      print("❌ Permission not granted");
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bookImages.add(File(pickedFile.path));
      });

      // Save to provider
      ref.read(signupProvider.notifier).addBookImage(pickedFile.path);
    } else {
      print("No image selected.");
    }
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

    // Add button colors
    final addButtonBgColor = isDarkMode
        ? AppColors.primary.withOpacity(0.2)
        : Colors.green.shade100;
    final addButtonBorderColor = isDarkMode
        ? AppColors.primary.withOpacity(0.6)
        : Colors.green;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 🔁 Back button + progress bar
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
                      widthFactor: 1.0,
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

              const SizedBox(height: 32),

              Center(
                child: Text(
                  "Upload Your Books",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Share your favorite books to begin\nexchanging",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textSecondaryColor),
                ),
              ),

              const SizedBox(height: 32),

              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    ..._bookImages.map(
                          (image) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(image, fit: BoxFit.cover),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: addButtonBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: addButtonBorderColor),
                          ),
                          child: Center(
                            child: Icon(Icons.add, size: 40, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Finish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/locationPermission');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 2,
                    shadowColor: isDarkMode ? Colors.black38 : Colors.black12,
                  ),
                  child: const Text(
                    "Finish",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pain/utils/constants.dart';
import 'package:pain/providers/sign_up_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpUploadBookScreen extends ConsumerStatefulWidget {
  const SignUpUploadBookScreen({super.key});

  @override
  ConsumerState<SignUpUploadBookScreen> createState() => _SignUpUploadBookScreenState();
}

class _SignUpUploadBookScreenState extends ConsumerState<SignUpUploadBookScreen> {
  final List<File> _bookImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // We don't load existing images since we don't have a bookImages field in SignupState
  }

  Future<void> _pickImage() async {
    print("📸 PLUS BUTTON TAPPED");

    var status = await Permission.photos.request();

    if (!status.isGranted) {
      print("❌ Permission not granted");
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bookImages.add(File(pickedFile.path));
      });

      // We don't save to provider since there's no addBookImage method
      // Instead we'll handle all uploads when the user clicks "Finish"
    } else {
      print("No image selected.");
    }
  }

  Future<void> _uploadBooks() async {
    if (_bookImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one book')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get signup data from provider
      final signupData = ref.read(signupProvider);
      final ownerName = signupData.name;

      // Upload images and add books to Firestore
      for (final bookImageFile in _bookImages) {
        // Upload image to Firebase Storage
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${bookImageFile.path.split('/').last}';
        final storageRef = FirebaseStorage.instance.ref()
            .child('book_images/${currentUser.uid}/$fileName');

        // Upload file
        final uploadTask = storageRef.putFile(bookImageFile);
        final snapshot = await uploadTask.whenComplete(() {});

        // Get download URL
        final imageUrl = await snapshot.ref.getDownloadURL();

        // Add book to Firestore
        await FirebaseFirestore.instance.collection('books').add({
          'title': 'New Book',
          'ownerName': ownerName,
          'age': 0,
          'location': signupData.location ?? 'Unknown Location',
          'imageUrl': imageUrl,
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Done uploading
      setState(() {
        _isUploading = false;
      });

      // Navigate to next screen
      if (mounted) {
        Navigator.pushNamed(context, '/locationPermission');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading books: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Progress bar colors
    final progressBgColor = isDarkMode
        ? AppColors.primary.withOpacity(0.3)
        : Colors.green.shade100;

    // Add button colors
    final addButtonBgColor = isDarkMode
        ? AppColors.primary.withOpacity(0.2)
        : Colors.green.shade100;
    final addButtonBorderColor = isDarkMode
        ? AppColors.primary.withOpacity(0.6)
        : Colors.green;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 🔁 Back button + progress bar
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
                      widthFactor: 1.0,
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

              const SizedBox(height: 32),

              Center(
                child: Text(
                  "Upload Your Books",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Share your favorite books to begin\nexchanging",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textSecondaryColor),
                ),
              ),

              const SizedBox(height: 32),

              // Grid
              Expanded(
                child: _isUploading
                    ? const Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Uploading your books..."),
                  ],
                ))
                    : GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    ..._bookImages.map(
                          (image) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(image, fit: BoxFit.cover),
                          ),
                          // Delete button
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _bookImages.remove(image);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: addButtonBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: addButtonBorderColor),
                          ),
                          child: Center(
                            child: Icon(Icons.add, size: 40, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Finish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadBooks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 2,
                    shadowColor: isDarkMode ? Colors.black38 : Colors.black12,
                  ),
                  child: const Text(
                    "Finish",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}